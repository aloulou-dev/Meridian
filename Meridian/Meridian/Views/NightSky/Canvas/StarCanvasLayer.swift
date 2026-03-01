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
    let onStarTapped: (Date) -> Void

    @State private var twinklePhases: [Date: Double] = [:]
    @State private var hitRegions: [StarHitRegion] = []

    init(stars: [RenderableStar], parallaxOffset: CGSize, scale: CGFloat = 1.0, onStarTapped: @escaping (Date) -> Void) {
        self.stars = stars
        self.parallaxOffset = parallaxOffset
        self.scale = scale
        self.onStarTapped = onStarTapped
    }

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Update hit regions for tap detection
                var newHitRegions: [StarHitRegion] = []

                let centerX = size.width / 2
                let centerY = size.height / 2

                for star in stars {
                    // Calculate scaled position (scale from center)
                    let basePos = star.screenPosition(in: size, parallaxOffset: parallaxOffset)
                    let scaledPos = CGPoint(
                        x: centerX + (basePos.x - centerX) * scale,
                        y: centerY + (basePos.y - centerY) * scale
                    )

                    let twinklePhase = twinklePhases[star.id] ?? 1.0

                    // Draw the star with scaled size
                    StarRenderer.draw(
                        star: star,
                        in: context,
                        at: scaledPos,
                        twinklePhase: twinklePhase,
                        scale: scale
                    )

                    // Record hit region (minimum 44pt for accessibility, scaled)
                    let baseHitRadius = max(star.effectiveSize * 1.5, Theme.Star.minHitTargetSize / 2)
                    let scaledHitRadius = baseHitRadius * scale
                    newHitRegions.append(StarHitRegion(
                        id: star.id,
                        center: scaledPos,
                        radius: scaledHitRadius
                    ))
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
        // Find the star that was tapped (check foreground first for z-order)
        let sortedRegions = hitRegions.sorted { region1, region2 in
            // Sort by depth layer - foreground stars should be checked first
            let star1 = stars.first { $0.id == region1.id }
            let star2 = stars.first { $0.id == region2.id }
            let layer1 = star1?.depthLayer ?? .background
            let layer2 = star2?.depthLayer ?? .background
            return layer1.parallaxMultiplier > layer2.parallaxMultiplier
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
