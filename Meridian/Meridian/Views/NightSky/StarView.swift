//
//  StarView.swift
//  Meridian
//
//  Individual star component for the night sky visualization.
//

import SwiftUI

/// A single star representing one day (morning + night sessions combined)
struct StarView: View {
    let dayStar: DayStar
    let size: CGSize
    let onTap: () -> Void

    @State private var isVisible = false
    @State private var isTwinkle = false

    // MARK: - Computed Properties

    private var position: CGPoint {
        CGPoint(
            x: dayStar.position.x * size.width,
            y: dayStar.position.y * size.height
        )
    }

    private var starColor: Color {
        (dayStar.latestEntry?.isMorning ?? false) ? .morningStar : .nightStar
    }

    private var glowColor: Color {
        (dayStar.latestEntry?.isMorning ?? false) ? .morningGlow : .nightGlow
    }

    private var starSize: CGFloat {
        let baseSize: CGFloat = 20
        let totalWords = dayStar.entries.reduce(0) { $0 + $1.wordCount }
        let wordBonus = min(CGFloat(totalWords) / 50.0, 1.0) * 8
        return baseSize + wordBonus
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(glowColor.opacity(0.4))
                .frame(width: starSize * 2, height: starSize * 2)
                .blur(radius: 10)

            // Inner glow
            Circle()
                .fill(glowColor.opacity(0.6))
                .frame(width: starSize * 1.5, height: starSize * 1.5)
                .blur(radius: 6)

            // Star icon
            Image(systemName: "star.fill")
                .font(.system(size: starSize))
                .foregroundColor(starColor)
                .shadow(color: starColor, radius: 4, x: 0, y: 0)
        }
        .position(position)
        .scaleEffect(isVisible ? 1 : 0)
        .opacity(isVisible ? (isTwinkle ? 0.7 : 1.0) : 0)
        .onAppear {
            // Staggered appearance animation
            let delay = Double.random(in: 0...0.5)
            withAnimation(Theme.Animation.starAppear.delay(delay)) {
                isVisible = true
            }

            // Start twinkle animation
            let twinkleDelay = Double.random(in: 1...3)
            DispatchQueue.main.asyncAfter(deadline: .now() + twinkleDelay) {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: true)
                ) {
                    isTwinkle = true
                }
            }
        }
        .onTapGesture {
            onTap()
        }
        .accessibilityLabel("Day \(dayStar.date.shortMonthDay)")
        .accessibilityHint("Double tap to view entry")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.nightSkyGradient
            .ignoresSafeArea()

        GeometryReader { geometry in
            // Create a mock entry for preview
            // In real app, this would come from Core Data
            Circle()
                .fill(Color.morningStar)
                .frame(width: 24, height: 24)
                .position(x: geometry.size.width * 0.3, y: geometry.size.height * 0.4)

            Circle()
                .fill(Color.nightStar)
                .frame(width: 20, height: 20)
                .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.3)
        }
    }
}
