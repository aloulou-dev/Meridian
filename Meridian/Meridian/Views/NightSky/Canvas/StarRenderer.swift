//
//  StarRenderer.swift
//  Meridian
//
//  Core drawing logic for rendering individual stars with multi-layered glows.
//

import SwiftUI

/// Renders individual stars with multi-layered glows and optional diffraction spikes
struct StarRenderer {
    /// Draw a star at the given position with full glow effects
    static func draw(
        star: RenderableStar,
        in context: GraphicsContext,
        at screenPosition: CGPoint,
        twinklePhase: Double,
        scale: CGFloat = 1.0
    ) {
        let baseSize = star.effectiveSize
        let size = baseSize * scale
        let color = Color.starColor(temperature: star.colorTemperature)
        let opacity = star.depthLayer.opacityMultiplier

        // Scale blur radii (but cap to avoid excessive blur at high zoom)
        let blurScale = min(scale, 2.0)

        // Layer 4: Outer halo (largest, most transparent, affected by twinkle)
        drawGlowLayer(
            in: context,
            center: screenPosition,
            radius: size * Theme.Star.outerHaloRadiusMultiplier,
            color: color,
            opacity: Theme.Star.outerHaloOpacity * opacity * twinklePhase,
            blur: Theme.Star.outerHaloBlur * blurScale
        )

        // Layer 3: Mid glow
        drawGlowLayer(
            in: context,
            center: screenPosition,
            radius: size * Theme.Star.midGlowRadiusMultiplier,
            color: color,
            opacity: Theme.Star.midGlowOpacity * opacity,
            blur: Theme.Star.midGlowBlur * blurScale
        )

        // Layer 2: Inner glow
        drawGlowLayer(
            in: context,
            center: screenPosition,
            radius: size * Theme.Star.innerGlowRadiusMultiplier,
            color: color,
            opacity: Theme.Star.innerGlowOpacity * opacity,
            blur: Theme.Star.innerGlowBlur * blurScale
        )

        // Layer 1: Core (brightest, sharpest)
        drawCore(
            in: context,
            center: screenPosition,
            radius: size * Theme.Star.coreRadiusMultiplier,
            opacity: Theme.Star.coreOpacity * opacity,
            scale: scale
        )

        // Diffraction spikes for larger stars (check scaled size)
        let showSpikes = size > Theme.Star.diffractionSpikeThreshold
        if showSpikes {
            drawDiffractionSpikes(
                in: context,
                center: screenPosition,
                length: size * Theme.Star.diffractionSpikeLengthMultiplier,
                color: color,
                opacity: Theme.Star.diffractionSpikeOpacity * opacity * twinklePhase,
                scale: scale
            )
        }
    }

    /// Draw a glow layer (blurred circle)
    private static func drawGlowLayer(
        in context: GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color,
        opacity: Double,
        blur: CGFloat
    ) {
        var layerContext = context
        layerContext.addFilter(.blur(radius: blur))

        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        layerContext.fill(
            Circle().path(in: rect),
            with: .color(color.opacity(opacity))
        )
    }

    /// Draw the bright core of the star
    private static func drawCore(
        in context: GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        opacity: Double,
        scale: CGFloat = 1.0
    ) {
        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        // White core with slight glow (scale blur minimally)
        var glowContext = context
        glowContext.addFilter(.blur(radius: 2 * min(scale, 1.5)))
        glowContext.fill(
            Circle().path(in: rect),
            with: .color(Color.white.opacity(opacity))
        )

        // Sharp white center
        let innerRadius = radius * 0.6
        let innerRect = CGRect(
            x: center.x - innerRadius,
            y: center.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        )
        context.fill(
            Circle().path(in: innerRect),
            with: .color(Color.white.opacity(opacity))
        )
    }

    /// Draw diffraction spikes (cross pattern) for larger stars
    private static func drawDiffractionSpikes(
        in context: GraphicsContext,
        center: CGPoint,
        length: CGFloat,
        color: Color,
        opacity: Double,
        scale: CGFloat = 1.0
    ) {
        let width = Theme.Star.diffractionSpikeWidth * min(scale, 2.0)

        // Vertical spike
        var verticalPath = Path()
        verticalPath.move(to: CGPoint(x: center.x, y: center.y - length))
        verticalPath.addLine(to: CGPoint(x: center.x, y: center.y + length))

        // Horizontal spike
        var horizontalPath = Path()
        horizontalPath.move(to: CGPoint(x: center.x - length, y: center.y))
        horizontalPath.addLine(to: CGPoint(x: center.x + length, y: center.y))

        // Diagonal spikes (45 degrees, shorter)
        let diagonalLength = length * 0.6
        let diagonalOffset = diagonalLength / sqrt(2)

        var diagonal1Path = Path()
        diagonal1Path.move(to: CGPoint(x: center.x - diagonalOffset, y: center.y - diagonalOffset))
        diagonal1Path.addLine(to: CGPoint(x: center.x + diagonalOffset, y: center.y + diagonalOffset))

        var diagonal2Path = Path()
        diagonal2Path.move(to: CGPoint(x: center.x + diagonalOffset, y: center.y - diagonalOffset))
        diagonal2Path.addLine(to: CGPoint(x: center.x - diagonalOffset, y: center.y + diagonalOffset))

        let style = StrokeStyle(lineWidth: width, lineCap: .round)
        let spikeColor = Color.white.opacity(opacity)

        // Apply blur for soft spikes
        var blurContext = context
        blurContext.addFilter(.blur(radius: 1 * min(scale, 1.5)))

        blurContext.stroke(verticalPath, with: .color(spikeColor), style: style)
        blurContext.stroke(horizontalPath, with: .color(spikeColor), style: style)

        // Diagonal spikes are dimmer
        let diagonalStyle = StrokeStyle(lineWidth: width * 0.7, lineCap: .round)
        let diagonalColor = Color.white.opacity(opacity * 0.5)
        blurContext.stroke(diagonal1Path, with: .color(diagonalColor), style: diagonalStyle)
        blurContext.stroke(diagonal2Path, with: .color(diagonalColor), style: diagonalStyle)
    }
}

/// Hit region for tap detection on stars
struct StarHitRegion {
    let id: Date
    let center: CGPoint
    let radius: CGFloat

    /// Check if a point is within this hit region
    func contains(_ point: CGPoint) -> Bool {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return sqrt(dx * dx + dy * dy) <= radius
    }
}
