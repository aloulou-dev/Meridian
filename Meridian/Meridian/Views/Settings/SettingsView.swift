//
//  SettingsView.swift
//  Meridian
//
//  Settings screen for configuring app preferences.
//

import SwiftUI
import FamilyControls

/// Main settings screen
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var expandedMorningDays: Set<DayOfWeek> = []
    @State private var expandedNightDays: Set<DayOfWeek> = []
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.nightSkyGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        // Blocked Apps Section
                        blockedAppsSection

                        // Morning Session Section
                        morningSessionSection

                        // Night Session Section
                        nightSessionSection

                        // Notifications (test)
                        notificationsSection

                        // Demo Controls
                        demoControlsSection

                        // About Section
                        aboutSection

                        // Reset Button
                        resetButton
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryButton)
                }
            }
            .familyActivityPicker(
                isPresented: $viewModel.showAppPicker,
                selection: $viewModel.blockedAppsSelection
            )
            .onChange(of: viewModel.blockedAppsSelection) { _ in
                viewModel.saveBlockedApps()
            }
            .alert("Reset All Settings?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.resetAllSettings()
                }
            } message: {
                Text("This will reset all settings to defaults. Your journal entries will not be affected.")
            }
        }
    }

    // MARK: - Blocked Apps Section

    private var blockedAppsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "Blocked Apps", icon: "app.badge.fill")

            Button(action: { viewModel.showAppPicker = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select Apps")
                            .font(Theme.Typography.body)
                            .foregroundColor(.textPrimary)

                        Text("\(viewModel.blockedAppsCount) apps selected")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.textMuted)
                }
                .padding()
                .cardStyle()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Morning Session Section

    private var morningSessionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "Morning Session", icon: "sun.max.fill", iconColor: .morningStar)

            VStack(spacing: Theme.Spacing.xs) {
                // Enable toggle
                HStack {
                    Text("Enable Morning Session")
                        .font(Theme.Typography.body)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Toggle("", isOn: $viewModel.isMorningEnabled)
                        .labelsHidden()
                        .tint(.morningStar)
                }
                .padding()
                .cardStyle()

                if viewModel.isMorningEnabled {
                    // Time pickers for each day
                    ForEach(DayOfWeek.allCases) { day in
                        SettingsTimeRow(
                            day: day,
                            time: Binding(
                                get: { viewModel.getMorningTime(for: day) },
                                set: { viewModel.setMorningTime($0, for: day) }
                            ),
                            accentColor: .morningStar,
                            isExpanded: expandedMorningDays.contains(day),
                            onToggleExpand: {
                                withAnimation(Theme.Animation.fast) {
                                    if expandedMorningDays.contains(day) {
                                        expandedMorningDays.remove(day)
                                    } else {
                                        expandedMorningDays.insert(day)
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Night Session Section

    private var nightSessionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "Night Session", icon: "moon.stars.fill", iconColor: .primaryButton)

            VStack(spacing: 0) {
                // Info note
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.primaryButton)
                    Text("Apps lock at this time")
                        .font(Theme.Typography.small)
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium, corners: [.topLeft, .topRight])

                Divider()
                    .background(Color.white.opacity(0.1))

                HStack {
                    Text("Grace period")
                        .font(Theme.Typography.body)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Stepper(
                        "\(viewModel.nightGraceMinutes) min",
                        value: $viewModel.nightGraceMinutes,
                        in: 1...60
                    )
                    .labelsHidden()
                    Text("\(viewModel.nightGraceMinutes) min")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.textSecondary)
                }
                .padding()
                .background(Color.cardBackground)

                Divider()
                    .background(Color.white.opacity(0.1))

                // Time pickers for each day
                ForEach(Array(DayOfWeek.allCases.enumerated()), id: \.element.id) { index, day in
                    VStack(spacing: 0) {
                        SettingsTimeRow(
                            day: day,
                            time: Binding(
                                get: { viewModel.getBedtime(for: day) },
                                set: { viewModel.setBedtime($0, for: day) }
                            ),
                            accentColor: .primaryButton,
                            label: "Bedtime",
                            isExpanded: expandedNightDays.contains(day),
                            onToggleExpand: {
                                withAnimation(Theme.Animation.fast) {
                                    if expandedNightDays.contains(day) {
                                        expandedNightDays.remove(day)
                                    } else {
                                        expandedNightDays.insert(day)
                                    }
                                }
                            }
                        )
                        .cornerRadius(index == DayOfWeek.allCases.count - 1 ? Theme.CornerRadius.medium : 0, corners: index == DayOfWeek.allCases.count - 1 ? [.bottomLeft, .bottomRight] : [])

                        if index < DayOfWeek.allCases.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.05))
                        }
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "Notifications", icon: "bell.fill")

            VStack(alignment: .leading, spacing: 0) {
                Button(action: { viewModel.sendTestNotification() }) {
                    HStack {
                        Text("Send test notification")
                            .font(Theme.Typography.body)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        if viewModel.isSendingTestNotification {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primaryButton))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.primaryButton)
                        }
                    }
                    .padding()
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSendingTestNotification)

                Text("Tap to send a notification now. If you see it, reminders at your morning/night times will work.")
                    .font(Theme.Typography.small)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal)
                    .padding(.bottom, Theme.Spacing.sm)
            }
            .cardStyle()
        }
    }

    // MARK: - Demo Controls Section

    private var demoControlsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "Hackathon Demo Controls", icon: "wand.and.stars")
            VStack(spacing: Theme.Spacing.xs) {
                // Status info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: viewModel.isScreenTimeAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.isScreenTimeAuthorized ? .success : .error)
                        Text("Screen Time: \(viewModel.isScreenTimeAuthorized ? "Authorized" : "Not Authorized")")
                            .font(Theme.Typography.small)
                            .foregroundColor(.textSecondary)
                    }
                    HStack {
                        Image(systemName: viewModel.hasAppsSelected ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.hasAppsSelected ? .success : .error)
                        Text("Apps Selected: \(viewModel.blockedAppsCount)")
                            .font(Theme.Typography.small)
                            .foregroundColor(.textSecondary)
                    }
                    HStack {
                        Image(systemName: viewModel.isMorningEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.isMorningEnabled ? .success : .warning)
                        Text("Morning Session: \(viewModel.isMorningEnabled ? "Enabled" : "Disabled")")
                            .font(Theme.Typography.small)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // App blocking test controls
                HStack(spacing: Theme.Spacing.sm) {
                    Button(action: viewModel.blockAppsNow) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                            Text("Block Apps")
                                .font(Theme.Typography.body)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryButton)
                        .foregroundColor(.white)
                        .cornerRadius(Theme.CornerRadius.medium)
                    }

                    Button(action: viewModel.unblockAppsNow) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 14))
                            Text("Unblock Apps")
                                .font(Theme.Typography.body)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.success)
                        .foregroundColor(.white)
                        .cornerRadius(Theme.CornerRadius.medium)
                    }
                }

                if let message = viewModel.blockingStatusMessage {
                    Text(message)
                        .font(Theme.Typography.small)
                        .foregroundColor(message.contains("successfully") ? .success : .warning)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xs)
                }

                Text(viewModel.areAppsBlocked ? "Shield Status: ACTIVE" : "Shield Status: INACTIVE")
                    .font(Theme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.areAppsBlocked ? .error : .success)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Theme.Spacing.xs)

                demoButton("Trigger morning lock now", action: viewModel.triggerMorningLockNow)
                demoButton("Trigger night soft lock now", action: viewModel.triggerNightSoftLockNow)
                demoButton("Start grace period now", action: viewModel.triggerGraceNow)
                demoButton("Trigger hard lock now", action: viewModel.triggerHardLockNow)
            }
        }
    }

    private func demoButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundColor(.textPrimary)
                Spacer()
                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.primaryButton)
            }
            .padding()
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "About", icon: "info.circle")

            VStack(spacing: 0) {
                aboutRow(title: "Version", value: viewModel.appVersion)
                Divider().background(Color.white.opacity(0.05))
                aboutRow(title: "Build", value: viewModel.buildNumber)
            }
            .cardStyle()
        }
    }

    // MARK: - Reset Button

    private var resetButton: some View {
        Button(action: { showResetConfirmation = true }) {
            Text("Reset All Settings")
                .font(Theme.Typography.body)
                .foregroundColor(.error)
                .frame(maxWidth: .infinity)
                .padding()
                .cardStyle()
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String, iconColor: Color = .textSecondary) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
            Text(title)
                .font(Theme.Typography.subheading)
                .foregroundColor(.textPrimary)
        }
    }

    private func aboutRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Theme.Typography.body)
                .foregroundColor(.textPrimary)
            Spacer()
            Text(value)
                .font(Theme.Typography.body)
                .foregroundColor(.textSecondary)
        }
        .padding()
    }
}

// MARK: - Settings Time Row

struct SettingsTimeRow: View {
    let day: DayOfWeek
    @Binding var time: Date
    let accentColor: Color
    var label: String = "Time"
    let isExpanded: Bool
    let onToggleExpand: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggleExpand) {
                HStack {
                    Text(day.fullName)
                        .font(Theme.Typography.body)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Text(time.timeString)
                        .font(Theme.Typography.body)
                        .foregroundColor(accentColor)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }
                .padding()
                .background(Color.cardBackground)
            }
            .buttonStyle(.plain)

            if isExpanded {
                DatePicker(
                    "",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .background(Color.surfaceDark)
            }
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    SettingsView()
}
