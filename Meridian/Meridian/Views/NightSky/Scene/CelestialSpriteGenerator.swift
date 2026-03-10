//
//  CelestialSpriteGenerator.swift
//  Meridian
//
//  Procedural Core Graphics textures for galaxy billboard sprites.
//

import UIKit
import CoreGraphics

// MARK: - CelestialType

enum CelestialType: Int {
    case spiralCool, edgeOn
}

// MARK: - Generator

struct CelestialSpriteGenerator {

    // MARK: - Cache

    private static var cache: [CelestialType: UIImage] = [:]
    private static var vertexGlowCache: UIImage?

    static func image(for type: CelestialType) -> UIImage {
        if let cached = cache[type] { return cached }
        let img = generate(type)
        cache[type] = img
        return img
    }

    static func vertexGlowImage() -> UIImage {
        if let cached = vertexGlowCache { return cached }
        let s: CGFloat = 64
        UIGraphicsBeginImageContextWithOptions(CGSize(width: s, height: s), false, 1)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return UIImage() }
        drawRadialGradient(ctx: ctx, cx: s / 2, cy: s / 2, radius: s / 2, colors: [
            (UIColor.white.withAlphaComponent(0.80), 0.0),
            (UIColor.white.withAlphaComponent(0.25), 0.4),
            (UIColor.clear,                           1.0)
        ])
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        vertexGlowCache = img
        return img
    }

    // MARK: - Dispatch

    private static func generate(_ type: CelestialType) -> UIImage {
        switch type {
        case .spiralCool: return spiralGalaxy(size: 512)
        case .edgeOn:     return edgeOnGalaxy(width: 512, height: 128)
        }
    }

    // MARK: - Spiral Galaxy (2-arm logarithmic spiral)

    private static func spiralGalaxy(size: Int) -> UIImage {
        let s = CGFloat(size)
        let cx = s / 2
        let cy = s / 2

        let coreColor = UIColor(red: 1.00, green: 0.98, blue: 0.95, alpha: 1) // warm white
        let armColor  = UIColor(red: 0.72, green: 0.78, blue: 1.00, alpha: 1) // #B8C8FF cool blue-white

        UIGraphicsBeginImageContextWithOptions(CGSize(width: s, height: s), false, 1)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return UIImage() }

        // Step A — 3 background glow layers (inner → outer)

        // L3 — inner warm disc
        drawRadialGradient(ctx: ctx, cx: cx, cy: cy, radius: 80, colors: [
            (UIColor(red: 0.75, green: 0.72, blue: 0.63, alpha: 0.15), 0.0),
            (UIColor.clear, 1.0)
        ])
        // L2 — mid diffuse
        drawRadialGradient(ctx: ctx, cx: cx, cy: cy, radius: 130, colors: [
            (UIColor(red: 0.56, green: 0.63, blue: 0.82, alpha: 0.12), 0.0),
            (UIColor.clear, 1.0)
        ])
        // L1 — outer haze
        drawRadialGradient(ctx: ctx, cx: cx, cy: cy, radius: 180, colors: [
            (UIColor(red: 0.50, green: 0.56, blue: 0.75, alpha: 0.08), 0.0),
            (UIColor.clear, 1.0)
        ])

        // Step B — 2-arm logarithmic spiral, 2000 dots each
        let numArms = 2
        let stepsPerArm = 2000
        let thetaMax: Double = 4 * .pi   // 2 full turns

        for armIndex in 0..<numArms {
            let armOffset = Double(armIndex) * .pi   // 0 and π

            for step in 0..<stepsPerArm {
                let t = Double(step) / Double(stepsPerArm - 1)
                let theta = t * thetaMax
                let r = 30.0 * exp(0.15 * theta)     // logarithmic: r = 30e^(0.15θ)

                let px = cx + CGFloat(r * cos(theta + armOffset))
                let py = cy + CGFloat(r * sin(theta + armOffset))

                // Perpendicular scatter — deterministic, golden-ratio harmonic
                let scatter = CGFloat(sin(Double(step) * 1.618) * 15.0)
                let spx = px + scatter * CGFloat(-sin(theta + armOffset))
                let spy = py + scatter * CGFloat(cos(theta + armOffset))

                // Skip dots outside canvas
                guard spx >= 0, spx < s, spy >= 0, spy < s else { continue }

                // Dot radius: 0.5–1.5px, deterministic variation
                let dotRadius = CGFloat(0.5 + abs(sin(Double(step) * 1.618)) * 1.0)

                // Alpha: 0.6 at center → 0.05 at edge
                let dotAlpha = CGFloat(max(0.05, 0.6 - 0.55 * t))

                // Color lerp: warm white → cool blue-white
                let dotColor = lerpColor(coreColor, armColor, CGFloat(t)).withAlphaComponent(dotAlpha)

                ctx.setFillColor(dotColor.cgColor)
                ctx.fillEllipse(in: CGRect(x: spx - dotRadius, y: spy - dotRadius,
                                           width: dotRadius * 2, height: dotRadius * 2))
            }
        }

        // Step C — Bright core on top

        // Core glow
        drawRadialGradient(ctx: ctx, cx: cx, cy: cy, radius: 18, colors: [
            (UIColor(red: 1, green: 0.94, blue: 0.82, alpha: 0.90), 0.0),
            (UIColor.clear, 1.0)
        ])
        // Core point
        drawRadialGradient(ctx: ctx, cx: cx, cy: cy, radius: 6, colors: [
            (UIColor.white.withAlphaComponent(1.0), 0.0),
            (UIColor.clear, 1.0)
        ])

        // TODO: Replace with NASA/Hubble image — recommended: M31 Andromeda (hubblesite.org) or M51 Whirlpool

        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }

    // MARK: - Edge-On Galaxy

    private static func edgeOnGalaxy(width: Int, height: Int) -> UIImage {
        let w = CGFloat(width)
        let h = CGFloat(height)
        let cx = w / 2
        let cy = h / 2

        let bulge = UIColor(red: 1.00, green: 0.94, blue: 0.78, alpha: 1) // #FFF0C8 warm white
        let disk  = UIColor(red: 0.82, green: 0.85, blue: 0.94, alpha: 1) // #D0D8F0 cool blue-white
        let dust  = UIColor(red: 0.16, green: 0.10, blue: 0.06, alpha: 1) // #2A1A10 near-black

        UIGraphicsBeginImageContextWithOptions(CGSize(width: w, height: h), false, 1)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return UIImage() }

        // 1. Thin disk — horizontal ellipse, full width (reduced opacity)
        drawOvalBlob(ctx: ctx, size: h,
                     canvasW: w, canvasH: h,
                     cx: cx, cy: cy, rx: w * 0.50, ry: h * 0.10,
                     angleDeg: 0, color: disk.withAlphaComponent(0.48))

        // 2. Central bulge — tighter radius + lower opacity
        drawRadialGradient(ctx: ctx, cx: cx, cy: cy, radius: h * 0.28, colors: [
            (bulge.withAlphaComponent(0.70), 0.0),
            (disk.withAlphaComponent(0.30),  0.6),
            (UIColor.clear,                   1.0)
        ])

        // 3. Dust lane — thin dark horizontal stripe through center
        let dustH = h * 0.06
        ctx.saveGState()
        ctx.setAlpha(0.35)
        ctx.setFillColor(dust.cgColor)
        ctx.fill(CGRect(x: 0, y: cy - dustH / 2, width: w, height: dustH))
        ctx.restoreGState()

        // 4. Hot core — tiny bright point
        drawRadialGradient(ctx: ctx, cx: cx, cy: cy, radius: h * 0.08, colors: [
            (UIColor.white.withAlphaComponent(0.95), 0.0),
            (UIColor.clear,                           1.0)
        ])

        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }

    // MARK: - Drawing Helpers

    /// Draw a radial gradient centred at (cx, cy) with the given radius.
    /// `colors` is an array of (color, location) stops from center outward.
    private static func drawRadialGradient(
        ctx: CGContext,
        cx: CGFloat, cy: CGFloat,
        radius: CGFloat,
        colors: [(UIColor, CGFloat)],
        reversed: Bool = false
    ) {
        let cgColors = colors.map { $0.0.cgColor } as CFArray
        let locations = colors.map { $0.1 }
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: cgColors,
            locations: locations
        ) else { return }

        let center = CGPoint(x: cx, y: cy)
        ctx.drawRadialGradient(
            gradient,
            startCenter: center, startRadius: 0,
            endCenter:   center, endRadius:   radius,
            options: [.drawsAfterEndLocation]
        )
    }

    /// Draw a rotated oval blob using a scaled radial gradient (square canvas variant).
    private static func drawOvalBlob(
        ctx: CGContext,
        size: CGFloat,
        cx: CGFloat, cy: CGFloat,
        rx: CGFloat, ry: CGFloat,
        angleDeg: CGFloat,
        color: UIColor
    ) {
        // cx/cy are fractions of size
        drawOvalBlob(ctx: ctx, size: size,
                     canvasW: size, canvasH: size,
                     cx: cx * size, cy: cy * size,
                     rx: rx * size, ry: ry * size,
                     angleDeg: angleDeg, color: color)
    }

    /// Draw a rotated oval blob using a scaled radial gradient (arbitrary canvas variant).
    private static func drawOvalBlob(
        ctx: CGContext,
        size: CGFloat,
        canvasW: CGFloat, canvasH: CGFloat,
        cx: CGFloat, cy: CGFloat,
        rx: CGFloat, ry: CGFloat,
        angleDeg: CGFloat,
        color: UIColor
    ) {
        let angle = angleDeg * .pi / 180

        let cgColors = [
            color.cgColor,
            color.withAlphaComponent(0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0, 1]
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: cgColors,
            locations: locations
        ) else { return }

        ctx.saveGState()
        ctx.translateBy(x: cx, y: cy)
        ctx.rotate(by: angle)
        ctx.scaleBy(x: rx, y: ry)

        ctx.drawRadialGradient(
            gradient,
            startCenter: .zero, startRadius: 0,
            endCenter:   .zero, endRadius:   1.0,
            options: [.drawsAfterEndLocation]
        )
        ctx.restoreGState()
    }

    // MARK: - Color Lerp

    private static func lerpColor(_ a: UIColor, _ b: UIColor, _ t: CGFloat) -> UIColor {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return UIColor(
            red:   ar + (br - ar) * t,
            green: ag + (bg - ag) * t,
            blue:  ab + (bb - ab) * t,
            alpha: aa + (ba - aa) * t
        )
    }
}
