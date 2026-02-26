//
//  AppSelectionView.swift
//  Meridian
//
//  App selection screen using FamilyActivityPicker.
//

import SwiftUI
import FamilyControls

/// Onboarding screen for selecting apps to block
struct AppSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var isPickerPresented = false

    var body: some View {
        OnboardingPageTemplate(
            title: "Choose Apps to Block",
            subtitle: "Select the apps you want to lock until you complete your journal entry (optional)",
            buttonTitle: "Continue",
            isButtonEnabled: true,  // Screen Time optional: can continue with or without apps
            showBackButton: true,
            onBack: { viewModel.goToPreviousStep() },
            onNext: { viewModel.goToNextStep() }
        ) {
            VStack(spacing: Theme.Spacing.md) {
                // Selection summary card
                Button(action: { isPickerPresented = true }) {
                    VStack(spacing: Theme.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(Color.primaryButton.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: viewModel.hasSelectedApps ? "checkmark.circle.fill" : "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.primaryButton)
                        }

                        if viewModel.hasSelectedApps {
                            Text("\(viewModel.selectedAppsCount) apps selected")
                                .font(Theme.Typography.subheading)
                                .foregroundColor(.textPrimary)

                            Text("Tap to modify")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                        } else {
                            Text("Tap to select apps")
                                .font(Theme.Typography.subheading)
                                .foregroundColor(.textPrimary)

                            Text("Choose social media, games, or other distracting apps")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .cardStyle()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Theme.Spacing.md)

                // Tips
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Tips")
                        .font(Theme.Typography.subheading)
                        .foregroundColor(.textPrimary)

                    TipRow(text: "Start with your most distracting apps")
                    TipRow(text: "You can add or remove apps later in Settings")
                    TipRow(text: "Categories like \"Social\" block all apps in that group")
                }
                .padding(.horizontal, Theme.Spacing.md)

                Spacer()

                // Note about same blocklist
                Text("The same apps will be blocked for both morning and night sessions")
                    .font(Theme.Typography.small)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
            .padding(.top, Theme.Spacing.md)
        }
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $viewModel.blockedAppsSelection
        )
    }
}

// MARK: - Tip Row

struct TipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(.morningStar)

            Text(text)
                .font(Theme.Typography.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview {
    ZStack {
        Color.nightSkyGradient.ignoresSafeArea()
        AppSelectionView(viewModel: OnboardingViewModel())
    }
}
