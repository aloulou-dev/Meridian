//
//  EmptyNightSkyView.swift
//  Meridian
//
//  Empty state view when no journal entries exist.
//

import SwiftUI

/// Empty state view for the night sky
struct EmptyNightSkyView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Animated icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.primaryButton.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                // Stars
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.nightStar, .primaryButton],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: Theme.Spacing.xs) {
                Text("Your journey begins here")
                    .font(Theme.Typography.heading)
                    .foregroundColor(.textPrimary)

                Text("Each journal entry becomes a star\nin your personal night sky")
                    .font(Theme.Typography.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Hint
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.primaryButton)
                Text("Tap the + button to write your first entry")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textMuted)
            }
            .padding(.top, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.lg)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.nightSkyGradient
            .ignoresSafeArea()
        EmptyNightSkyView()
    }
}
