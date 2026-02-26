//
//  WelcomeView.swift
//  Meridian
//
//  Welcome screen for the onboarding flow.
//

import SwiftUI

/// First onboarding screen - introduces the app
struct WelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var starsVisible = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            // Animated stars background
            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: starSize(for: index)))
                        .foregroundColor(starColor(for: index))
                        .opacity(starsVisible ? 1 : 0)
                        .offset(starOffset(for: index))
                        .scaleEffect(starsVisible ? 1 : 0.5)
                        .animation(
                            Theme.Animation.starAppear.delay(Double(index) * 0.1),
                            value: starsVisible
                        )
                }

                // Moon icon
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.morningStar, .nightStar],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(starsVisible ? 1 : 0.8)
                    .animation(Theme.Animation.spring, value: starsVisible)
            }
            .frame(height: 200)

            // Title
            VStack(spacing: Theme.Spacing.sm) {
                Text("Meridian")
                    .font(Theme.Typography.title)
                    .foregroundColor(.textPrimary)

                Text("Build Better Habits")
                    .font(Theme.Typography.heading)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.morningStar, .primaryButton],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            // Subtitle
            Text("Through intentional mornings\nand reflective nights")
                .font(Theme.Typography.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            // Get Started button
            Button(action: { viewModel.goToNextStep() }) {
                HStack {
                    Text("Get Started")
                    Image(systemName: "arrow.right")
                }
                .primaryButtonStyle()
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .onAppear {
            withAnimation {
                starsVisible = true
            }
        }
    }

    // MARK: - Star Helpers

    private func starSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [12, 16, 10, 14, 8, 18, 12, 10, 16, 14, 8, 12]
        return sizes[index % sizes.count]
    }

    private func starColor(for index: Int) -> Color {
        index % 3 == 0 ? .morningStar : .nightStar
    }

    private func starOffset(for index: Int) -> CGSize {
        let offsets: [CGSize] = [
            CGSize(width: -100, height: -60),
            CGSize(width: 80, height: -80),
            CGSize(width: -60, height: 40),
            CGSize(width: 100, height: 20),
            CGSize(width: -30, height: -100),
            CGSize(width: 50, height: 70),
            CGSize(width: -120, height: 0),
            CGSize(width: 120, height: -40),
            CGSize(width: -80, height: 80),
            CGSize(width: 30, height: -70),
            CGSize(width: -50, height: 50),
            CGSize(width: 70, height: 90)
        ]
        return offsets[index % offsets.count]
    }
}

#Preview {
    ZStack {
        Color.nightSkyGradient.ignoresSafeArea()
        WelcomeView(viewModel: OnboardingViewModel())
    }
}
