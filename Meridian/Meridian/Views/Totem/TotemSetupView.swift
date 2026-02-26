//
//  TotemSetupView.swift
//  Meridian
//
//  Settings view for registering and managing a QR code totem.
//

import SwiftUI

struct TotemSetupView: View {
    @StateObject private var viewModel = TotemViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirmation = false

    var body: some View {
        ZStack {
            Color.nightSkyGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    totemIllustration
                    infoSection

                    if viewModel.hasTotemRegistered {
                        registeredSection
                    } else {
                        setupSection
                    }

                    if !viewModel.isCameraAvailable {
                        cameraUnavailableWarning
                    }
                }
                .padding(Theme.Spacing.md)
            }

            if viewModel.showScanner {
                scannerOverlay
            }
        }
        .navigationTitle("QR Code")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove QR Code?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                viewModel.clearTotem()
            }
        } message: {
            Text("You'll unlock apps immediately after journaling without needing to scan.")
        }
    }

    // MARK: - Illustration

    private var totemIllustration: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.primaryButton.opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color.primaryButton.opacity(0.25))
                    .frame(width: 80, height: 80)

                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 44))
                    .foregroundColor(.primaryButton)
            }

            Text("QR Code Unlock")
                .font(Theme.Typography.heading)
                .foregroundColor(.textPrimary)
        }
        .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            infoRow(
                icon: "sparkles",
                title: "Add mindfulness",
                description: "Scanning a QR code creates a moment of intention before unlocking your apps"
            )

            infoRow(
                icon: "qrcode",
                title: "Any QR code works",
                description: "Print one, use a sticker, or display it somewhere meaningful"
            )

            infoRow(
                icon: "arrow.uturn.right",
                title: "Always skippable",
                description: "If your QR code isn't nearby, you can bypass and unlock anyway"
            )
        }
        .padding()
        .cardStyle()
    }

    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.primaryButton)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundColor(.textPrimary)

                Text(description)
                    .font(Theme.Typography.small)
                    .foregroundColor(.textSecondary)
            }
        }
    }

    // MARK: - Setup Section

    private var setupSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button(action: {
                Task { await viewModel.beginSetupScan() }
            }) {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan QR Code")
                }
                .primaryButtonStyle(isEnabled: viewModel.isCameraAvailable)
            }
            .disabled(!viewModel.isCameraAvailable)

            if case .success = viewModel.scanStatus {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                    Text("QR code registered!")
                        .font(Theme.Typography.body)
                        .foregroundColor(.success)
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(Theme.Typography.small)
                    .foregroundColor(.error)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Registered Section

    private var registeredSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                    Text("QR Code Active")
                        .font(Theme.Typography.body)
                        .foregroundColor(.textPrimary)
                    Spacer()
                }

                HStack {
                    Text("Code:")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.textSecondary)
                    Text(viewModel.maskedTotemID ?? "Unknown")
                        .font(Theme.Typography.caption.monospaced())
                        .foregroundColor(.textMuted)
                    Spacer()
                }
            }
            .padding()
            .cardStyle()

            Button(action: {
                Task { await viewModel.beginSetupScan() }
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Replace QR Code")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cardBackground)
                .foregroundColor(.textPrimary)
                .cornerRadius(Theme.CornerRadius.medium)
            }

            Button(action: { showClearConfirmation = true }) {
                Text("Remove QR Code")
                    .font(Theme.Typography.body)
                    .foregroundColor(.error)
            }
            .padding(.top, Theme.Spacing.sm)

            if case .success = viewModel.scanStatus {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                    Text("QR code updated!")
                        .font(Theme.Typography.body)
                        .foregroundColor(.success)
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(Theme.Typography.small)
                    .foregroundColor(.error)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Camera Unavailable Warning

    private var cameraUnavailableWarning: some View {
        VStack(spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.warning)
                Text("Camera Not Available")
                    .font(Theme.Typography.body)
                    .foregroundColor(.warning)
            }

            Text("A camera is required to scan QR codes. QR scanning will be skipped automatically on this device.")
                .font(Theme.Typography.small)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.warning.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
    }

    // MARK: - Scanner Overlay

    private var scannerOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Text("Point camera at QR code")
                    .font(Theme.Typography.heading)
                    .foregroundColor(.white)

                QRCameraPreview(session: viewModel.scanner.captureSession)
                    .frame(width: 280, height: 280)
                    .cornerRadius(Theme.CornerRadius.large)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                            .stroke(Color.primaryButton, lineWidth: 3)
                    )

                Button("Cancel") {
                    viewModel.reset()
                }
                .font(Theme.Typography.body)
                .foregroundColor(.textSecondary)
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    NavigationView {
        TotemSetupView()
    }
}
