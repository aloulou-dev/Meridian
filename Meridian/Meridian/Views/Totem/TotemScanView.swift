//
//  TotemScanView.swift
//  Meridian
//
//  Full-screen view shown after journaling to scan QR code before unlocking.
//

import SwiftUI

struct TotemScanView: View {
    @StateObject private var viewModel = TotemViewModel()
    @Environment(\.dismiss) private var dismiss

    let onUnlocked: () -> Void

    var body: some View {
        ZStack {
            Color.nightSkyGradient
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Spacer()

                headerSection

                if viewModel.scanStatus == .scanning {
                    cameraSection
                } else {
                    statusIllustration
                }

                Spacer()

                actionButtons
                statusMessage
            }
            .padding(Theme.Spacing.lg)
        }
        .onAppear {
            Task { await viewModel.beginUnlockScan() }
        }
        .onDisappear {
            viewModel.reset()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Scan Your QR Code")
                .font(Theme.Typography.title)
                .foregroundColor(.textPrimary)

            Text("Take a breath, then scan your QR code to unlock")
                .font(Theme.Typography.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Camera Preview

    private var cameraSection: some View {
        QRCameraPreview(session: viewModel.scanner.captureSession)
            .frame(width: 260, height: 260)
            .cornerRadius(Theme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Color.primaryButton, lineWidth: 3)
            )
            .shadow(color: Color.primaryButton.opacity(0.3), radius: 12)
    }

    // MARK: - Status Illustration

    private var statusIllustration: some View {
        ZStack {
            Circle()
                .fill(statusBackgroundColor)
                .frame(width: 140, height: 140)

            statusIcon
                .font(.system(size: 56))
                .foregroundColor(statusIconColor)
        }
    }

    private var statusBackgroundColor: Color {
        switch viewModel.scanStatus {
        case .success, .bypassed:
            return Color.success.opacity(0.2)
        case .failed:
            return Color.error.opacity(0.2)
        default:
            return Color.primaryButton.opacity(0.15)
        }
    }

    private var statusIcon: Image {
        switch viewModel.scanStatus {
        case .success, .bypassed:
            return Image(systemName: "checkmark.circle.fill")
        case .failed:
            return Image(systemName: "xmark.circle.fill")
        default:
            return Image(systemName: "qrcode.viewfinder")
        }
    }

    private var statusIconColor: Color {
        switch viewModel.scanStatus {
        case .success, .bypassed:
            return .success
        case .failed:
            return .error
        default:
            return .primaryButton
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            if case .failed = viewModel.scanStatus {
                Button(action: {
                    Task { await viewModel.beginUnlockScan() }
                }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Try Again")
                    }
                    .primaryButtonStyle(isEnabled: true)
                }
            }

            if viewModel.scanStatus != .success && viewModel.scanStatus != .bypassed {
                Button(action: {
                    viewModel.bypassAndUnlock()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                        onUnlocked()
                    }
                }) {
                    Text("QR code not nearby? Unlock anyway")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.textMuted)
                        .underline()
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
    }

    // MARK: - Status Message

    @ViewBuilder
    private var statusMessage: some View {
        switch viewModel.scanStatus {
        case .success:
            VStack(spacing: Theme.Spacing.sm) {
                Text("QR code verified!")
                    .font(Theme.Typography.body)
                    .foregroundColor(.success)

                Text("Apps are now unlocked")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                    onUnlocked()
                }
            }

        case .bypassed:
            Text("Unlocked without QR scan")
                .font(Theme.Typography.body)
                .foregroundColor(.textSecondary)

        case .failed(let reason):
            VStack(spacing: Theme.Spacing.xs) {
                Text("Scan failed")
                    .font(Theme.Typography.body)
                    .foregroundColor(.error)

                Text(reason)
                    .font(Theme.Typography.small)
                    .foregroundColor(.textSecondary)

                Text("Try again or bypass below")
                    .font(Theme.Typography.small)
                    .foregroundColor(.textMuted)
            }

        default:
            EmptyView()
        }
    }
}

#Preview {
    TotemScanView(onUnlocked: {})
}
