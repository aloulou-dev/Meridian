//
//  NightSkyCanvasView.swift
//  Meridian
//
//  Main container orchestrating all canvas layers with parallax and zoom gesture handling.
//

import SwiftUI

/// Main container for the canvas-based night sky visualization
struct NightSkyCanvasView: View {
    let renderableStars: [RenderableStar]
    let constellationLines: [ConstellationLine]
    let onStarTapped: (Date) -> Void

    // MARK: - Parallax State

    @GestureState private var dragOffset: CGSize = .zero
    @State private var accumulatedOffset: CGSize = .zero

    // MARK: - Zoom State

    @GestureState private var magnificationDelta: CGFloat = 1.0
    @State private var accumulatedScale: CGFloat = Theme.Zoom.defaultScale

    // MARK: - Fly-Forward State

    @State private var flyProgress: CGFloat = 0
    @State private var flyFocalPoint: CGPoint = .zero

    // MARK: - Background Layers State

    @State private var nebulaClouds: [NebulaCloud] = []
    @State private var backgroundStars: [BackgroundStar] = []

    // MARK: - Computed Properties

    /// Calculate virtual canvas size based on screen size
    private func virtualCanvasSize(for screenSize: CGSize) -> CGSize {
        CGSize(
            width: screenSize.width * Theme.VirtualCanvas.widthMultiplier,
            height: screenSize.height * Theme.VirtualCanvas.heightMultiplier
        )
    }

    /// Maximum offset based on virtual canvas bounds
    private func maxOffset(for screenSize: CGSize) -> CGSize {
        let virtualSize = virtualCanvasSize(for: screenSize)
        return CGSize(
            width: (virtualSize.width - screenSize.width) / 2,
            height: (virtualSize.height - screenSize.height) / 2
        )
    }

    /// Combined offset from accumulated + current drag, clamped to virtual canvas bounds
    private func effectiveOffset(for screenSize: CGSize) -> CGSize {
        let max = maxOffset(for: screenSize)
        let scaledMaxX = max.width * effectiveScale
        let scaledMaxY = max.height * effectiveScale

        return CGSize(
            width: clampValue(accumulatedOffset.width + dragOffset.width, max: scaledMaxX),
            height: clampValue(accumulatedOffset.height + dragOffset.height, max: scaledMaxY)
        )
    }

    /// Combined scale from accumulated + current magnification
    private var effectiveScale: CGFloat {
        clampScale(accumulatedScale * magnificationDelta)
    }

    /// Clamp a value to +/- max bounds
    private func clampValue(_ value: CGFloat, max: CGFloat) -> CGFloat {
        Swift.max(-max, Swift.min(max, value))
    }

    /// Clamp scale to min/max bounds
    private func clampScale(_ value: CGFloat) -> CGFloat {
        Swift.max(Theme.Zoom.minScale, Swift.min(Theme.Zoom.maxScale, value))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let offset = effectiveOffset(for: geometry.size)

            ZStack {
                // Layer 0: Nebula background (depth: 0.15x parallax - barely moves)
                NebulaCanvasLayer(
                    clouds: nebulaClouds,
                    parallaxOffset: offset,
                    scale: effectiveScale,
                    parallaxMultiplier: Theme.Nebula.parallaxMultiplier,
                    useVirtualCanvas: true,
                    screenSize: geometry.size
                )

                // Layer 1: Background star field (depth: 0.3x parallax)
                BackgroundStarFieldLayer(
                    stars: backgroundStars,
                    parallaxOffset: offset,
                    scale: effectiveScale,
                    screenSize: geometry.size,
                    flyProgress: flyProgress
                )

                // Layer 2: Constellation lines (depth: 0.7x parallax)
                ConstellationCanvasLayer(
                    lines: constellationLines,
                    stars: renderableStars,
                    parallaxOffset: offset,
                    scale: effectiveScale
                )

                // Layer 3: Stars (depth: 1.0x parallax - foreground)
                StarCanvasLayer(
                    stars: renderableStars,
                    parallaxOffset: offset,
                    scale: effectiveScale,
                    flyProgress: flyProgress,
                    flyFocalPoint: flyFocalPoint,
                    onStarTapped: onStarTapped
                )
            }
            .gesture(combinedGesture(for: geometry.size))
            .onTapGesture(count: 2, coordinateSpace: .local) { location in
                handleFlyForward(from: location)
            }
            .onAppear {
                initializeBackgroundLayers(for: geometry.size)
            }
        }
    }

    // MARK: - Initialization

    /// Initialize background stars and nebula clouds for the virtual canvas
    private func initializeBackgroundLayers(for screenSize: CGSize) {
        let virtualSize = virtualCanvasSize(for: screenSize)

        // Generate background stars across the virtual canvas
        backgroundStars = BackgroundStar.generateStarField(
            count: Theme.BackgroundStarField.count,
            canvasSize: virtualSize
        )

        // Generate nebula clouds scattered across the virtual canvas
        nebulaClouds = NebulaCloud.generateForVirtualCanvas()
    }

    // MARK: - Gestures

    /// Combined drag and magnification gesture
    private func combinedGesture(for screenSize: CGSize) -> some Gesture {
        SimultaneousGesture(parallaxDragGesture(for: screenSize), magnificationGesture)
    }

    /// Drag gesture for parallax scrolling
    private func parallaxDragGesture(for screenSize: CGSize) -> some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let max = maxOffset(for: screenSize)
                let scaledMaxX = max.width * accumulatedScale
                let scaledMaxY = max.height * accumulatedScale

                let newWidth = clampValue(accumulatedOffset.width + value.translation.width, max: scaledMaxX)
                let newHeight = clampValue(accumulatedOffset.height + value.translation.height, max: scaledMaxY)

                withAnimation(.easeOut(duration: 0.3)) {
                    accumulatedOffset = CGSize(width: newWidth, height: newHeight)
                }
            }
    }

    /// Magnification gesture for pinch-to-zoom
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($magnificationDelta) { value, state, _ in
                state = value
            }
            .onEnded { value in
                let newScale = clampScale(accumulatedScale * value)

                withAnimation(.easeOut(duration: 0.2)) {
                    accumulatedScale = newScale
                }
            }
    }

    /// Trigger a meditative fly-forward animation from the tapped screen location.
    /// Stars expand outward from the focal point; close stars move fastest.
    /// After the animation completes the state resets silently (no snap visible).
    private func handleFlyForward(from tapLocation: CGPoint) {
        guard flyProgress == 0 else { return }  // ignore if already animating
        flyFocalPoint = tapLocation
        withAnimation(.easeIn(duration: Theme.FlyForward.duration)) {
            flyProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Theme.FlyForward.duration) {
            flyProgress = 0  // instant reset — 0 means no transform applied
        }
    }
}

#Preview {
    ZStack {
        Color.nightSkyGradient
            .ignoresSafeArea()

        NightSkyCanvasView(
            renderableStars: [],
            constellationLines: [],
            onStarTapped: { _ in }
        )
    }
}
