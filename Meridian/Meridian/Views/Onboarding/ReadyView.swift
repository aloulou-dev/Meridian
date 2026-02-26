//
//  ReadyView.swift
//  Meridian
//
//  Completion screen for the onboarding flow.
//

import SwiftUI

/// Final onboarding screen - ready to start
struct ReadyView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showConfetti = false
    @State private var starScale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            // Celebration animation
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.primaryButton.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)

                // Stars
                ForEach(0..<8, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(index % 2 == 0 ? .morningStar : .nightStar)
                        .offset(celebrationStarOffset(for: index))
                        .scaleEffect(showConfetti ? 1 : 0)
                        .opacity(showConfetti ? 1 : 0)
                        .animation(
                            Theme.Animation.spring.delay(0.3 + Double(index) * 0.1),
                            value: showConfetti
                        )
                }

                // Main star
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.morningStar, .nightStar],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(starScale)
                    .animation(Theme.Animation.spring, value: starScale)
            }
            .frame(height: 250)

            // Title
            VStack(spacing: Theme.Spacing.sm) {
                Text("You're All Set!")
                    .font(Theme.Typography.title)
                    .foregroundColor(.textPrimary)

                Text("Your journey to better habits starts now")
                    .font(Theme.Typography.body)
                    .foregroundColor(.textSecondary)
            }

            // Summary
            VStack(spacing: Theme.Spacing.sm) {
                SummaryRow(
                    icon: "app.badge",
                    text: "\(viewModel.selectedAppsCount) apps will be blocked"
                )

                if viewModel.isMorningEnabled {
                    SummaryRow(
                        icon: "sun.max.fill",
                        text: "Morning sessions enabled",
                        iconColor: .morningStar
                    )
                }

                SummaryRow(
                    icon: "moon.stars.fill",
                    text: "Night sessions before bed",
                    iconColor: .nightStar
                )
            }
            .padding()
            .cardStyle()
            .padding(.horizontal, Theme.Spacing.md)

            Spacer()

            // Start button
            Button(action: {
                viewModel.completeOnboarding()
            }) {
                HStack {
                    Text("Start My Journey")
                    Image(systemName: "sparkles")
                }
                .primaryButtonStyle()
            }
            .padding(.horizontal, Theme.Spacing.md)

            Button(action: { viewModel.goToPreviousStep() }) {
                Text("Go Back")
                    .font(Theme.Typography.button)
                    .foregroundColor(.textSecondary)
            }
            .padding(.bottom, Theme.Spacing.lg)
        }
        .onAppear {
            withAnimation {
                starScale = 1.0
                showConfetti = true
            }
        }
    }

    private func celebrationStarOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 8.0) * .pi / 180.0
        let radius: CGFloat = 100
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius
        )
    }
}

// MARK: - Summary Row

struct SummaryRow: View {
    let icon: String
    let text: String
    var iconColor: Color = .primaryButton

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 28)

            Text(text)
                .font(Theme.Typography.body)
                .foregroundColor(.textPrimary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.success)
        }
    }
}

#Preview {
    ZStack {
        Color.nightSkyGradient.ignoresSafeArea()
        ReadyView(viewModel: OnboardingViewModel())
    }
}
