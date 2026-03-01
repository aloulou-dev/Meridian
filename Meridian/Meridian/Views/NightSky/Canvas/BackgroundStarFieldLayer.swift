//
//  BackgroundStarFieldLayer.swift
//  Meridian
//
//  Canvas layer for rendering decorative background stars with twinkle animations.
//

import SwiftUI

/// Canvas layer that renders ~150 decorative background stars
struct BackgroundStarFieldLayer: View {
    let stars: [BackgroundStar]
    let parallaxOffset: CGSize
    let scale: CGFloat
    let screenSize: CGSize

    @State private var twinklePhases: [Int: Double] = [:]

    init(
        stars: [BackgroundStar],
        parallaxOffset: CGSize,
        scale: CGFloat = 1.0,
        screenSize: CGSize
    ) {
        self.stars = stars
        self.parallaxOffset = parallaxOffset
        self.scale = scale
        self.screenSize = screenSize
    }

    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2

            for star in stars {
                // Apply parallax (background stars move slower than journal stars)
                let offsetX = parallaxOffset.width * Theme.BackgroundStarField.parallaxMultiplier
                let offsetY = parallaxOffset.height * Theme.BackgroundStarField.parallaxMultiplier

                // Background stars scale slower for depth effect
                let bgScale = 1.0 + (scale - 1.0) * 0.5

                // Convert virtual canvas position to screen position
                // Center the virtual canvas on the screen initially
                let virtualCenterOffsetX = (screenSize.width * Theme.VirtualCanvas.widthMultiplier - screenSize.width) / 2
                let virtualCenterOffsetY = (screenSize.height * Theme.VirtualCanvas.heightMultiplier - screenSize.height) / 2

                let baseX = star.virtualPosition.x - virtualCenterOffsetX
                let baseY = star.virtualPosition.y - virtualCenterOffsetY

                // Apply scale from center and parallax offset
                let screenX = centerX + (baseX - centerX) * bgScale + offsetX
                let screenY = centerY + (baseY - centerY) * bgScale + offsetY

                // Viewport culling - skip stars outside visible area with padding
                let padding: CGFloat = 10
                guard screenX > -padding && screenX < size.width + padding &&
                      screenY > -padding && screenY < size.height + padding else {
                    continue
                }

                // Get twinkle phase (default to 1.0 if not yet set)
                let twinkle = twinklePhases[star.id] ?? 1.0
                let opacity = star.baseOpacity * twinkle

                // Get color based on temperature
                let color = Color.backgroundStarColor(temperature: star.colorTemperature)

                // Scale the star size slightly with zoom
                let scaledSize = star.size * min(bgScale, 1.5)

                // Draw simple filled circle (no glow needed for tiny stars)
                let rect = CGRect(
                    x: screenX - scaledSize / 2,
                    y: screenY - scaledSize / 2,
                    width: scaledSize,
                    height: scaledSize
                )
                context.fill(Circle().path(in: rect), with: .color(color.opacity(opacity)))
            }
        }
        .onAppear {
            initializeTwinkleAnimations()
        }
    }

    /// Initialize staggered twinkle animations for all stars
    private func initializeTwinkleAnimations() {
        for star in stars {
            twinklePhases[star.id] = 1.0

            // Start animation after staggered delay
            DispatchQueue.main.asyncAfter(deadline: .now() + star.twinklePhaseOffset) {
                withAnimation(
                    .easeInOut(duration: star.twinkleSpeed)
                    .repeatForever(autoreverses: true)
                ) {
                    twinklePhases[star.id] = Double.random(in: 0.6...1.0)
                }
            }
        }
    }
}

#Preview {
    GeometryReader { geometry in
        ZStack {
            Color.nightSkyGradient
                .ignoresSafeArea()

            BackgroundStarFieldLayer(
                stars: BackgroundStar.generateStarField(
                    count: 150,
                    canvasSize: CGSize(
                        width: geometry.size.width * Theme.VirtualCanvas.widthMultiplier,
                        height: geometry.size.height * Theme.VirtualCanvas.heightMultiplier
                    )
                ),
                parallaxOffset: .zero,
                scale: 1.0,
                screenSize: geometry.size
            )
        }
    }
}
