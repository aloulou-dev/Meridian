//
//  NightSkySceneBuilder.swift
//  Meridian
//
//  Pure builder: takes [RenderableStar] + [ConstellationLine] → returns configured SCNScene.
//

import SceneKit
import UIKit

// MARK: - Shared ISO8601 date formatter for star node naming

// Use the local timezone so "2024-10-24" round-trips to local midnight,
// matching Calendar.current.startOfDay(for:) used in NightSkyViewModel.
let starNodeDateFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withFullDate]
    f.timeZone = Calendar.current.timeZone
    return f
}()

// MARK: - Scene Builder

struct NightSkySceneBuilder {

    static func build(
        stars: [RenderableStar],
        lines: [ConstellationLine]
    ) -> SCNScene {
        let scene = SCNScene()

        // Deep navy background
        scene.background.contents = UIColor(red: 0.03, green: 0.05, blue: 0.12, alpha: 1)

        // Ambient light — very dim, emissive stars supply their own illumination
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        ambientNode.light?.intensity = 50
        scene.rootNode.addChildNode(ambientNode)

        // Background star sphere + galaxy nebulae
        let backgroundRoot = SCNNode()
        backgroundRoot.name = "backgroundRoot"
        scene.rootNode.addChildNode(backgroundRoot)
        buildBackgroundStars(into: backgroundRoot)
        buildGalaxies(into: backgroundRoot)

        // Journal stars
        let journalStarsRoot = SCNNode()
        journalStarsRoot.name = "journalStarsRoot"
        scene.rootNode.addChildNode(journalStarsRoot)
        buildJournalStars(stars: stars, into: journalStarsRoot)

        // Constellation lines (connect stars already placed in journalStarsRoot)
        buildConstellationLines(lines: lines, from: journalStarsRoot)

        // Camera
        let camera = SCNCamera()
        camera.fieldOfView = Theme.Scene3D.cameraFOV
        camera.zNear = 1
        camera.zFar = 3000

        let cameraNode = SCNNode()
        cameraNode.name = "mainCamera"
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, Theme.Scene3D.cameraStartZ)
        scene.rootNode.addChildNode(cameraNode)

        return scene
    }

    // MARK: - Background Stars

    static func buildBackgroundStars(into parent: SCNNode) {
        var rng = SeededRandomNumberGenerator(seed: Theme.BackgroundStarField.seed)

        for _ in 0..<Theme.BackgroundStarField.count {
            let theta = Float(Double.random(in: 0...(2 * .pi), using: &rng))
            let phi   = Float(acos(2 * Double.random(in: 0...1, using: &rng) - 1))
            let r     = Theme.Scene3D.bgStarRadius

            let position = SCNVector3(
                r * sin(phi) * cos(theta),
                r * sin(phi) * sin(theta),
                r * cos(phi)
            )

            let radius = CGFloat(Float.random(
                in: Theme.Scene3D.bgStarMinRadius...Theme.Scene3D.bgStarMaxRadius,
                using: &rng
            ))
            let temperature = Double.random(in: 0...1, using: &rng)
            let opacity = Double.random(
                in: Theme.BackgroundStarField.minOpacity...Theme.BackgroundStarField.maxOpacity,
                using: &rng
            )

            let sphere = SCNSphere(radius: radius)
            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor.black
            mat.emission.contents = bgStarColor(temperature: temperature).withAlphaComponent(CGFloat(opacity))
            mat.lightingModel = .constant
            sphere.firstMaterial = mat

            let node = SCNNode(geometry: sphere)
            node.position = position
            node.castsShadow = false

            // Single glow halo per background star
            let glowSphere = SCNSphere(radius: radius * 3.0)
            let glowMat = SCNMaterial()
            glowMat.diffuse.contents = UIColor.clear
            glowMat.emission.contents = bgStarColor(temperature: temperature)
                .withAlphaComponent(CGFloat(opacity * 0.6))
            glowMat.isDoubleSided = true
            glowMat.blendMode = .add
            glowMat.lightingModel = .constant
            glowSphere.firstMaterial = glowMat
            let glowNode = SCNNode(geometry: glowSphere)
            glowNode.castsShadow = false
            node.addChildNode(glowNode)

            parent.addChildNode(node)
        }
    }

    // MARK: - Journal Stars

    static func buildJournalStars(stars: [RenderableStar], into parent: SCNNode) {
        for star in stars {
            // Seeded ±12% XY jitter per star for natural 3D scatter
            let dateSeedRaw = Int64(star.id.timeIntervalSince1970 * 1000)
            let dateSeed = UInt64(bitPattern: dateSeedRaw) % 99_991
            var starRng = SeededRandomNumberGenerator(seed: dateSeed)
            let jitterX = Float(Double.random(in: -0.12...0.12, using: &starRng))
            let jitterY = Float(Double.random(in: -0.12...0.12, using: &starRng))

            let worldX = Float((star.normalizedPosition.x - 0.5 + Double(jitterX)) * Double(Theme.Scene3D.journalXSpread))
            let worldY = Float((0.5 - star.normalizedPosition.y + Double(jitterY)) * Double(Theme.Scene3D.journalYSpread))

            // 3rd draw — deterministic radius seeded from date (replaces word-count approach)
            let coreRadius = Theme.Scene3D.journalStarMinRadius
                + Float(Double.random(in: 0...1, using: &starRng))
                * (Theme.Scene3D.journalStarMaxRadius - Theme.Scene3D.journalStarMinRadius)

            // 4th draw — deterministic Z seeded from date (replaces non-stable zDepth)
            let zFraction = Float(Double.random(in: 0...1, using: &starRng))
            let worldZ = Theme.Scene3D.journalZNear
                - zFraction * abs(Theme.Scene3D.journalZFar - Theme.Scene3D.journalZNear)

            let starColor = journalStarColor(temperature: star.colorTemperature)

            // Core sphere — bright warm-white centre regardless of temperature
            let coreSphere = SCNSphere(radius: CGFloat(coreRadius))
            let coreMat = SCNMaterial()
            coreMat.diffuse.contents = UIColor.black
            coreMat.emission.contents = UIColor(red: 1, green: 0.97, blue: 0.95, alpha: 1)
            coreMat.lightingModel = .constant
            coreSphere.firstMaterial = coreMat

            let coreNode = SCNNode(geometry: coreSphere)
            coreNode.position = SCNVector3(worldX, worldY, worldZ)
            coreNode.castsShadow = false
            coreNode.name = "star_\(starNodeDateFormatter.string(from: star.id))"

            // Glow layers — i=0: outer coloured haze (8×); i=1: inner warm-white bloom (3×)
            for (i, mult) in Theme.Scene3D.glowRadiusMultipliers.enumerated() {
                let glowSphere = SCNSphere(radius: CGFloat(coreRadius * mult))
                let glowMat = SCNMaterial()
                glowMat.diffuse.contents = UIColor.clear
                let glowColor: UIColor = i == 0
                    ? starColor.withAlphaComponent(CGFloat(Theme.Scene3D.glowOpacities[i]))
                    : UIColor(red: 1, green: 0.96, blue: 0.88, alpha: CGFloat(Theme.Scene3D.glowOpacities[i]))
                glowMat.emission.contents = glowColor
                glowMat.isDoubleSided = true
                glowMat.blendMode = .add
                glowMat.lightingModel = .constant
                glowSphere.firstMaterial = glowMat

                let glowNode = SCNNode(geometry: glowSphere)
                glowNode.castsShadow = false
                coreNode.addChildNode(glowNode)
            }

            // Omni light at star position
            let lightNode = SCNNode()
            lightNode.light = SCNLight()
            lightNode.light?.type = .omni
            lightNode.light?.color = starColor
            lightNode.light?.intensity = Theme.Scene3D.starLightIntensity * CGFloat(star.opacityMultiplier)
            lightNode.light?.attenuationStartDistance = CGFloat(coreRadius * 2)
            lightNode.light?.attenuationEndDistance = CGFloat(coreRadius * 10)
            coreNode.addChildNode(lightNode)

            parent.addChildNode(coreNode)
        }
    }

    // MARK: - Constellation Lines

    static func buildConstellationLines(lines: [ConstellationLine], from journalStarsRoot: SCNNode) {
        for line in lines {
            let nameA = "star_\(starNodeDateFormatter.string(from: line.startStarID))"
            let nameB = "star_\(starNodeDateFormatter.string(from: line.endStarID))"

            guard
                let nodeA = journalStarsRoot.childNode(withName: nameA, recursively: false),
                let nodeB = journalStarsRoot.childNode(withName: nameB, recursively: false)
            else { continue }

            let posA = nodeA.position
            let posB = nodeB.position

            let dx = posB.x - posA.x
            let dy = posB.y - posA.y
            let dz = posB.z - posA.z
            let length = sqrt(dx * dx + dy * dy + dz * dz)
            guard length > 0.001 else { continue }

            let midpoint = SCNVector3(
                (posA.x + posB.x) / 2,
                (posA.y + posB.y) / 2,
                (posA.z + posB.z) / 2
            )

            let cylinder = SCNCylinder(
                radius: CGFloat(Theme.Scene3D.lineRadius),
                height: CGFloat(length)
            )
            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor.white
            mat.emission.contents = UIColor.white.withAlphaComponent(0.3)
            mat.isDoubleSided = true
            mat.lightingModel = .constant
            cylinder.firstMaterial = mat

            let cylinderNode = SCNNode(geometry: cylinder)
            cylinderNode.position = midpoint
            cylinderNode.opacity = CGFloat(Theme.Scene3D.lineOpacity)

            // Align Y-axis (cylinder height axis) toward posB
            // Use Z as up unless direction is nearly vertical, then use X
            let normalizedDY = abs(dy / length)
            let upVec: SCNVector3 = normalizedDY > 0.95
                ? SCNVector3(1, 0, 0)
                : SCNVector3(0, 0, 1)
            cylinderNode.look(at: posB, up: upVec, localFront: SCNVector3(0, 1, 0))

            journalStarsRoot.addChildNode(cylinderNode)

            // Soft glow dot at each vertex
            addVertexGlow(at: posA, to: journalStarsRoot)
            addVertexGlow(at: posB, to: journalStarsRoot)
        }
    }

    private static func addVertexGlow(at pos: SCNVector3, to parent: SCNNode) {
        let plane = SCNPlane(width: 18, height: 18)
        let mat = SCNMaterial()
        mat.emission.contents   = CelestialSpriteGenerator.vertexGlowImage()
        mat.diffuse.contents    = UIColor.black
        mat.isDoubleSided       = true
        mat.blendMode           = .add
        mat.lightingModel       = .constant
        mat.writesToDepthBuffer = false
        plane.firstMaterial = mat

        let glowNode = SCNNode(geometry: plane)
        glowNode.position = pos
        glowNode.opacity = 0.20
        let bb = SCNBillboardConstraint()
        bb.freeAxes = .all
        glowNode.constraints = [bb]
        parent.addChildNode(glowNode)
    }

    // MARK: - Galaxies

    /// 3 celestial objects at r=1400: procedural CG texture on billboard SCNPlane.
    static func buildGalaxies(into parent: SCNNode) {
        var rng = SeededRandomNumberGenerator(seed: 77777)

        struct CelestialDef {
            let type: CelestialType
            let planeW: Float
            let planeH: Float
            let r: Float
            let rotationDuration: Double?
        }

        let defs: [CelestialDef] = [
            CelestialDef(type: .spiralCool, planeW: 180, planeH: 180, r: 1400, rotationDuration: nil),
            CelestialDef(type: .edgeOn,     planeW: 200, planeH: 78,  r: 1400, rotationDuration: nil),
        ]

        for def in defs {
            let theta = Float(Double.random(in: 0...(2 * .pi), using: &rng))
            let phi   = Float(acos(2 * Double.random(in: 0...1, using: &rng) - 1))
            let pos = SCNVector3(
                def.r * sin(phi) * cos(theta),
                def.r * sin(phi) * sin(theta),
                def.r * cos(phi)
            )

            let galaxyNode = SCNNode()
            galaxyNode.position = pos
            galaxyNode.castsShadow = false

            // Billboard plane
            let plane = SCNPlane(width: CGFloat(def.planeW), height: CGFloat(def.planeH))
            let mat = SCNMaterial()
            mat.emission.contents   = CelestialSpriteGenerator.image(for: def.type)
            mat.diffuse.contents    = UIColor.black
            mat.isDoubleSided       = true
            mat.blendMode           = .add
            mat.lightingModel       = .constant
            mat.writesToDepthBuffer = false
            plane.firstMaterial = mat

            let planeNode = SCNNode(geometry: plane)
            let billboard = SCNBillboardConstraint()
            billboard.freeAxes = .all
            planeNode.constraints = [billboard]

            // Slow in-plane rotation for spiral galaxies
            if let duration = def.rotationDuration {
                planeNode.runAction(.repeatForever(
                    .rotate(by: .pi * 2, around: SCNVector3(0, 0, 1), duration: duration)
                ))
            }

            // Subtle opacity pulse (0.65–0.75 over 5–7 seconds)
            let pulseDuration = Double.random(in: 5.0...7.0, using: &rng)
            planeNode.opacity = 0.70
            planeNode.runAction(.repeatForever(.sequence([
                .fadeOpacity(to: 0.65, duration: pulseDuration),
                .fadeOpacity(to: 0.75, duration: pulseDuration)
            ])))

            galaxyNode.addChildNode(planeNode)
            parent.addChildNode(galaxyNode)
        }
    }

    // MARK: - Color Helpers

    private static func journalStarColor(temperature: Double) -> UIColor {
        let t = max(0, min(1, temperature))
        if t < 0.5 {
            let p = t * 2
            // cool (#B8D4E8) → neutral (#F5F5DC)
            return UIColor(
                red: lerp(0xB8, 0xF5, p) / 255,
                green: lerp(0xD4, 0xF5, p) / 255,
                blue: lerp(0xE8, 0xDC, p) / 255,
                alpha: 1
            )
        } else {
            let p = (t - 0.5) * 2
            // neutral (#F5F5DC) → warm (#FFB347)
            return UIColor(
                red: lerp(0xF5, 0xFF, p) / 255,
                green: lerp(0xF5, 0xB3, p) / 255,
                blue: lerp(0xDC, 0x47, p) / 255,
                alpha: 1
            )
        }
    }

    private static func bgStarColor(temperature: Double) -> UIColor {
        let t = max(0, min(1, temperature))
        if t < 0.5 {
            let p = t * 2
            // cool blue (#AAD4FF) → white (#FFFFFF)
            return UIColor(
                red: lerp(0xAA, 0xFF, p) / 255,
                green: lerp(0xD4, 0xFF, p) / 255,
                blue: lerp(0xFF, 0xFF, p) / 255,
                alpha: 1
            )
        } else {
            let p = (t - 0.5) * 2
            // white (#FFFFFF) → warm peach (#FFE4B5)
            return UIColor(
                red: lerp(0xFF, 0xFF, p) / 255,
                green: lerp(0xFF, 0xE4, p) / 255,
                blue: lerp(0xFF, 0xB5, p) / 255,
                alpha: 1
            )
        }
    }

    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> CGFloat {
        CGFloat(a + (b - a) * t)
    }
}
