//
//  PermissionView.swift
//  Meridian
//
//  Permission request screen for ScreenTime/FamilyControls.
//

import SwiftUI

/// Onboarding screen for requesting FamilyControls permission
struct PermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var isRequesting = false

    var body: some View {
        OnboardingPageTemplate(
            title: "Screen Time Access",
            subtitle: "Meridian needs permission to help you focus by blocking distracting apps",
            buttonTitle: viewModel.permissionGranted ? "Continue" : "Grant Permission",
            isButtonEnabled: !isRequesting,
            showBackButton: true,
            onBack: { viewModel.goToPreviousStep() },
            onNext: {
                if viewModel.permissionGranted {
                    viewModel.goToNextStep()
                } else {
                    requestPermission()
                }
            }
        ) {
            VStack(spacing: Theme.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.primaryButton.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "hourglass")
                        .font(.system(size: 50))
                        .foregroundColor(.primaryButton)
                }
                .padding(.top, Theme.Spacing.lg)

                // Status indicator
                if viewModel.permissionGranted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.success)
                        Text("Permission Granted")
                            .foregroundColor(.success)
                    }
                    .font(Theme.Typography.subheading)
                }

                // Error message
                if let error = viewModel.permissionError {
                    VStack(spacing: Theme.Spacing.xs) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.error)
                            Text("Permission Required")
                                .foregroundColor(.error)
                        }
                        .font(Theme.Typography.subheading)

                        Text(error)
                            .font(Theme.Typography.caption)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)

                        Button(action: openSettings) {
                            Text("Open Settings")
                                .font(Theme.Typography.button)
                                .foregroundColor(.primaryButton)
                        }
                        .padding(.top, Theme.Spacing.xs)
                    }
                    .padding()
                    .cardStyle()
                    .padding(.horizontal, Theme.Spacing.md)
                }

                // Features list
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    FeatureRow(
                        icon: "lock.fill",
                        title: "Block Distracting Apps",
                        description: "Lock selected apps until you journal"
                    )

                    FeatureRow(
                        icon: "hand.raised.fill",
                        title: "Your Data Stays Private",
                        description: "Everything is stored locally on your device"
                    )

                    FeatureRow(
                        icon: "arrow.uturn.backward",
                        title: "Revoke Anytime",
                        description: "You can remove access in Settings"
                    )
                }
                .padding(.horizontal, Theme.Spacing.md)

                Spacer()

                // Loading indicator
                if isRequesting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryButton))
                        .scaleEffect(1.2)
                }
            }
        }
    }

    private func requestPermission() {
        isRequesting = true
        Task {
            await viewModel.requestPermission()
            isRequesting = false
            if viewModel.permissionGranted {
                viewModel.goToNextStep()
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.primaryButton)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.subheading)
                    .foregroundColor(.textPrimary)

                Text(description)
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.nightSkyGradient.ignoresSafeArea()
        PermissionView(viewModel: OnboardingViewModel())
    }
}
