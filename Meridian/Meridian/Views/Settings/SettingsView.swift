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
                    Text("Apps lock 2 hours before bedtime")
                        .font(Theme.Typography.small)
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium, corners: [.topLeft, .topRight])

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
