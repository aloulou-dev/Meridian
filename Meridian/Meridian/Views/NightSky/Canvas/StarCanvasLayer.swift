//
//  StarCanvasLayer.swift
//  Meridian
//
//  Canvas layer for rendering stars with multi-layered glows and animations.
//

import SwiftUI

/// Canvas layer that renders all stars with glows and twinkle animations
struct StarCanvasLayer: View {
    let stars: [RenderableStar]
    let parallaxOffset: CGSize
    let scale: CGFloat
    let flyProgress: CGFloat
    let flyFocalPoint: CGPoint
    let onStarTapped: (Date) -> Void

    @State private var twinklePhases: [Date: Double] = [:]
    @State private var hitRegions: [StarHitRegion] = []

    init(
        stars: [RenderableStar],
        parallaxOffset: CGSize,
        scale: CGFloat = 1.0,
        flyProgress: CGFloat = 0,
        flyFocalPoint: CGPoint = .zero,
        onStarTapped: @escaping (Date) -> Void
    ) {
        self.stars = stars
        self.parallaxOffset = parallaxOffset
        self.scale = scale
        self.flyProgress = flyProgress
        self.flyFocalPoint = flyFocalPoint
        self.onStarTapped = onStarTapped
    }

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Update hit regions for tap detection
                var newHitRegions: [StarHitRegion] = []

                let centerX = size.width / 2
                let centerY = size.height / 2
                let screenDiag = sqrt(size.width * size.width + size.height * size.height)

                for star in stars {
                    // Calculate scaled position (scale from center)
                    let basePos = star.screenPosition(in: size, parallaxOffset: parallaxOffset)
                    let scaledPos = CGPoint(
                        x: centerX + (basePos.x - centerX) * scale,
                        y: centerY + (basePos.y - centerY) * scale
                    )

                    // Apply fly-forward expansion transform
                    var renderPos = scaledPos
                    var flyOpacity: Double = 1.0

                    if flyProgress > 0 {
                        let dx = scaledPos.x - flyFocalPoint.x
                        let dy = scaledPos.y - flyFocalPoint.y
                        let dist = sqrt(dx * dx + dy * dy)

                        // Closer stars in z-space fly out faster (depth-weighted expansion)
                        let depthWeight = CGFloat(0.5 + star.zDepth * 0.5)
                        let expansion = flyProgress * Theme.FlyForward.maxExpansionFactor * depthWeight

                        renderPos = CGPoint(
                            x: scaledPos.x + dx * expansion,
                            y: scaledPos.y + dy * expansion
                        )

                        // Stars near focal point fade out first (they "pass" the camera)
                        let fadeZone = Theme.FlyForward.focalFadeRadius
                        if dist < fadeZone {
                            flyOpacity = Double(max(0, 1.0 - flyProgress * (1.0 - dist / fadeZone)))
                        }

                        // Stars flying far off screen also fade
                        if dist * (1 + expansion) > screenDiag * 0.6 {
                            flyOpacity = min(flyOpacity, Double(max(0, 1.0 - flyProgress)))
                        }
                    }

                    let twinklePhase = twinklePhases[star.id] ?? 1.0

                    // Draw the star with scaled size and fly-forward opacity
                    StarRenderer.draw(
                        star: star,
                        in: context,
                        at: renderPos,
                        twinklePhase: twinklePhase,
                        scale: scale,
                        opacityMultiplier: flyOpacity
                    )

                    // Record hit region only when not animating (minimum 44pt for accessibility)
                    if flyProgress == 0 {
                        let baseHitRadius = max(star.effectiveSize * 1.5, Theme.Star.minHitTargetSize / 2)
                        let scaledHitRadius = baseHitRadius * scale
                        newHitRegions.append(StarHitRegion(
                            id: star.id,
                            center: scaledPos,
                            radius: scaledHitRadius
                        ))
                    }
                }

                // Update hit regions on main thread
                DispatchQueue.main.async {
                    hitRegions = newHitRegions
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                handleTap(at: location)
            }
            .onAppear {
                initializeTwinkleAnimations()
            }
            .onChange(of: stars.count) { _, _ in
                initializeTwinkleAnimations()
            }
        }
    }

    /// Initialize twinkle animations for all stars
    private func initializeTwinkleAnimations() {
        for star in stars {
            if twinklePhases[star.id] == nil {
                twinklePhases[star.id] = 1.0

                // Start staggered twinkle animation
                let delay = Double.random(in: 0...2)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    startTwinkleAnimation(for: star.id)
                }
            }
        }
    }

    /// Start the continuous twinkle animation for a star
    private func startTwinkleAnimation(for id: Date) {
        let duration = Double.random(
            in: Theme.Star.twinkleDurationMin...Theme.Star.twinkleDurationMax
        )

        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
        ) {
            twinklePhases[id] = Double.random(in: 0.6...0.9)
        }
    }

    /// Handle tap gesture and find which star was tapped
    private func handleTap(at location: CGPoint) {
        // Block star selection during fly-forward animation
        guard flyProgress == 0 else { return }

        // Find the star that was tapped (check foreground first for z-order)
        let sortedRegions = hitRegions.sorted { region1, region2 in
            // Sort by parallaxMultiplier — higher value = closer = checked first
            let star1 = stars.first { $0.id == region1.id }
            let star2 = stars.first { $0.id == region2.id }
            let p1 = star1?.parallaxMultiplier ?? 0
            let p2 = star2?.parallaxMultiplier ?? 0
            return p1 > p2
        }

        for region in sortedRegions {
            if region.contains(location) {
                onStarTapped(region.id)
                return
            }
        }
    }
}

#Preview {
    ZStack {
        Color.nightSkyGradient
            .ignoresSafeArea()

        StarCanvasLayer(
            stars: [],
            parallaxOffset: .zero,
            scale: 1.0,
            onStarTapped: { _ in }
        )
    }
}
