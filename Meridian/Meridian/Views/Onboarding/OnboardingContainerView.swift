//
//  OnboardingContainerView.swift
//  Meridian
//
//  Container view for the onboarding flow with page navigation.
//

import SwiftUI

/// Container view that manages the onboarding flow
struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            // Background gradient
            Color.nightSkyGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Step indicator (hidden on welcome and ready screens)
                if showStepIndicator {
                    StepIndicator(
                        currentStep: viewModel.currentStep.stepNumber,
                        totalSteps: OnboardingViewModel.Step.totalSteps
                    )
                    .padding(.top, Theme.Spacing.md)
                    .padding(.horizontal, Theme.Spacing.md)
                }

                // Content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeView(viewModel: viewModel)
                        .tag(OnboardingViewModel.Step.welcome)

                    PermissionView(viewModel: viewModel)
                        .tag(OnboardingViewModel.Step.permission)

                    AppSelectionView(viewModel: viewModel)
                        .tag(OnboardingViewModel.Step.appSelection)

                    MorningConfigView(viewModel: viewModel)
                        .tag(OnboardingViewModel.Step.morningConfig)

                    NightConfigView(viewModel: viewModel)
                        .tag(OnboardingViewModel.Step.nightConfig)

                    ReadyView(viewModel: viewModel)
                        .tag(OnboardingViewModel.Step.ready)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(Theme.Animation.standard, value: viewModel.currentStep)
            }
        }
    }

    private var showStepIndicator: Bool {
        viewModel.currentStep != .welcome && viewModel.currentStep != .ready
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.primaryButton : Color.white.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Onboarding Page Template

struct OnboardingPageTemplate<Content: View>: View {
    let title: String
    let subtitle: String?
    let buttonTitle: String
    let isButtonEnabled: Bool
    let showBackButton: Bool
    let onBack: (() -> Void)?
    let onNext: () -> Void
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        buttonTitle: String,
        isButtonEnabled: Bool = true,
        showBackButton: Bool = false,
        onBack: (() -> Void)? = nil,
        onNext: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.isButtonEnabled = isButtonEnabled
        self.showBackButton = showBackButton
        self.onBack = onBack
        self.onNext = onNext
        self.content = content
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Header
            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.heading)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, Theme.Spacing.md)

            // Content
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Buttons
            VStack(spacing: Theme.Spacing.sm) {
                Button(action: onNext) {
                    Text(buttonTitle)
                        .primaryButtonStyle(isEnabled: isButtonEnabled)
                }
                .disabled(!isButtonEnabled)

                if showBackButton {
                    Button(action: { onBack?() }) {
                        Text("Back")
                            .font(Theme.Typography.button)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.lg)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView()
}
