//
//  NightSkySceneView.swift
//  Meridian
//
//  UIViewRepresentable wrapping SCNView. Coordinator handles gestures, auto-drift, and tap detection.
//

import SwiftUI
import SceneKit
import Combine

// MARK: - Camera Orientation Observable

/// Shared object the Coordinator writes into and SwiftUI overlay reads from.
final class CameraOrientation: ObservableObject {
    @Published var yaw: Float = 0   // radians; positive = looked right from origin
}

// MARK: - NightSkySceneView

struct NightSkySceneView: UIViewRepresentable {
    let stars: [RenderableStar]
    let lines: [ConstellationLine]
    let onStarTapped: (Date) -> Void
    let cameraOrientation: CameraOrientation

    func makeCoordinator() -> NightSkySceneCoordinator {
        NightSkySceneCoordinator(onStarTapped: onStarTapped, cameraOrientation: cameraOrientation)
    }

    func makeUIView(context: Context) -> SCNView {
        let scene = NightSkySceneBuilder.build(stars: stars, lines: lines)

        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.autoenablesDefaultLighting = false
        scnView.backgroundColor = .clear
        scnView.delegate = context.coordinator
        scnView.rendersContinuously = true

        let coordinator = context.coordinator
        coordinator.scnView = scnView
        coordinator.cameraNode = scene.rootNode.childNode(withName: "mainCamera", recursively: false)
        coordinator.lastStarIDs = Set(stars.map { $0.id })

        scnView.addGestureRecognizer(
            UIPanGestureRecognizer(target: coordinator, action: #selector(NightSkySceneCoordinator.handlePan(_:)))
        )
        scnView.addGestureRecognizer(
            UIPinchGestureRecognizer(target: coordinator, action: #selector(NightSkySceneCoordinator.handlePinch(_:)))
        )
        scnView.addGestureRecognizer(
            UITapGestureRecognizer(target: coordinator, action: #selector(NightSkySceneCoordinator.handleTap(_:)))
        )

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Avoid rebuilding the star graph on every frame (e.g. triggered by cameraOrientation changes).
        // Only rebuild when the set of star dates actually changes (new/deleted entries).
        let currentIDs = Set(stars.map { $0.id })
        guard currentIDs != context.coordinator.lastStarIDs else { return }
        context.coordinator.lastStarIDs = currentIDs

        guard
            let scene = uiView.scene,
            let journalStarsRoot = scene.rootNode.childNode(withName: "journalStarsRoot", recursively: false)
        else { return }

        journalStarsRoot.childNodes.forEach { $0.removeFromParentNode() }
        NightSkySceneBuilder.buildJournalStars(stars: stars, into: journalStarsRoot)
        NightSkySceneBuilder.buildConstellationLines(lines: lines, from: journalStarsRoot)
    }
}

// MARK: - Coordinator

final class NightSkySceneCoordinator: NSObject, SCNSceneRendererDelegate {
    weak var scnView: SCNView?
    var cameraNode: SCNNode?
    var onStarTapped: (Date) -> Void
    var cameraOrientation: CameraOrientation

    // Star identity cache
    var lastStarIDs: Set<Date> = []

    // Drift state
    var isUserInteracting = false
    var lastUpdateTime: TimeInterval = 0
    var resumeWorkItem: DispatchWorkItem?

    // Cumulative zoom from pinch gestures — clamped to Theme.Scene3D.dollyMin/dollyMax
    private var cumulativeDolly: Float = 0

    init(onStarTapped: @escaping (Date) -> Void, cameraOrientation: CameraOrientation) {
        self.onStarTapped = onStarTapped
        self.cameraOrientation = cameraOrientation
    }

    // MARK: - Gesture Handlers

    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        pauseDrift()
        guard let camera = cameraNode else { return }

        let delta = recognizer.translation(in: recognizer.view)
        camera.eulerAngles.y += Float(delta.x) * Theme.Scene3D.orbitSensitivity
        camera.eulerAngles.x += Float(delta.y) * Theme.Scene3D.orbitSensitivity
        camera.eulerAngles.x = max(
            -Theme.Scene3D.pitchClamp,
            min(Theme.Scene3D.pitchClamp, camera.eulerAngles.x)
        )
        recognizer.setTranslation(.zero, in: recognizer.view)
    }

    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        pauseDrift()
        guard let camera = cameraNode else { return }

        let scale = Float(recognizer.scale)
        let rawDolly = (scale - 1.0) * Theme.Scene3D.dollyUnitsPerPinchUnit

        let newCumulative = cumulativeDolly + rawDolly
        let clampedCumulative = max(Theme.Scene3D.dollyMin, min(Theme.Scene3D.dollyMax, newCumulative))
        let effectiveDolly = clampedCumulative - cumulativeDolly
        cumulativeDolly = clampedCumulative

        camera.localTranslate(by: SCNVector3(0, 0, -effectiveDolly))
        recognizer.scale = 1.0
    }

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let scnView = scnView else { return }

        let location = recognizer.location(in: scnView)
        let hits = scnView.hitTest(location, options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue,
            .boundingBoxOnly: false
        ])

        for hit in hits {
            // Walk up the node hierarchy — hit.node may be an unnamed glow child
            var node: SCNNode? = hit.node
            while let n = node {
                if let name = n.name, name.hasPrefix("star_") {
                    let dateString = name.replacingOccurrences(of: "star_", with: "")
                    if let date = starNodeDateFormatter.date(from: dateString) {
                        // Dispatch to main so any @Published state updates work correctly
                        DispatchQueue.main.async { [weak self] in
                            self?.onStarTapped(date)
                        }
                    }
                    return
                }
                node = n.parent
            }
        }
    }

    // MARK: - Drift Control

    func pauseDrift() {
        isUserInteracting = true
        resumeWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.isUserInteracting = false
        }
        resumeWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Theme.Scene3D.interactionResumeDelay,
            execute: workItem
        )
    }

    // MARK: - SCNSceneRendererDelegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let yaw = cameraNode?.eulerAngles.y ?? 0
        DispatchQueue.main.async { [weak self] in
            self?.cameraOrientation.yaw = yaw
        }

        guard !isUserInteracting else {
            lastUpdateTime = time
            return
        }

        let delta = lastUpdateTime > 0 ? Float(time - lastUpdateTime) : 0
        lastUpdateTime = time

        guard let camera = cameraNode else { return }

        camera.localTranslate(by: SCNVector3(0, 0, -Theme.Scene3D.driftSpeed * delta))

        if camera.worldPosition.z < Theme.Scene3D.driftResetThreshold {
            let angles = camera.eulerAngles
            camera.position.z += Theme.Scene3D.cameraStartZ - Theme.Scene3D.driftResetThreshold
            camera.eulerAngles = angles
        }
    }
}
