//
//  MorningConfigView.swift
//  Meridian
//
//  Morning session configuration screen.
//

import SwiftUI

/// Onboarding screen for configuring morning session times
struct MorningConfigView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var expandedDays: Set<DayOfWeek> = []

    var body: some View {
        OnboardingPageTemplate(
            title: "Morning Ritual",
            subtitle: "Set when you want to journal each morning",
            buttonTitle: "Continue",
            isButtonEnabled: true,
            showBackButton: true,
            onBack: { viewModel.goToPreviousStep() },
            onNext: { viewModel.goToNextStep() }
        ) {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    // Enable toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Morning Session")
                                .font(Theme.Typography.subheading)
                                .foregroundColor(.textPrimary)

                            Text("Optional - journal before checking apps")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                        }

                        Spacer()

                        Toggle("", isOn: $viewModel.isMorningEnabled)
                            .labelsHidden()
                            .tint(.morningStar)
                    }
                    .padding()
                    .cardStyle()
                    .padding(.horizontal, Theme.Spacing.md)

                    if viewModel.isMorningEnabled {
                        // Quick set buttons
                        HStack(spacing: Theme.Spacing.sm) {
                            QuickTimeButton(title: "7:00 AM") {
                                viewModel.setMorningTimeForAllDays(Date.today(hour: 7))
                            }
                            QuickTimeButton(title: "8:00 AM") {
                                viewModel.setMorningTimeForAllDays(Date.today(hour: 8))
                            }
                            QuickTimeButton(title: "9:00 AM") {
                                viewModel.setMorningTimeForAllDays(Date.today(hour: 9))
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)

                        // Day-by-day configuration
                        VStack(spacing: Theme.Spacing.xs) {
                            ForEach(DayOfWeek.allCases) { day in
                                DayTimeRow(
                                    day: day,
                                    time: Binding(
                                        get: { viewModel.getMorningTime(for: day) },
                                        set: { viewModel.setMorningTime($0, for: day) }
                                    ),
                                    accentColor: .morningStar,
                                    isExpanded: expandedDays.contains(day),
                                    onToggleExpand: {
                                        withAnimation(Theme.Animation.fast) {
                                            if expandedDays.contains(day) {
                                                expandedDays.remove(day)
                                            } else {
                                                expandedDays.insert(day)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)

                        // Info note
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.primaryButton)
                            Text("Apps will lock at these times until you journal")
                                .font(Theme.Typography.small)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    } else {
                        // Disabled state
                        VStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "sun.max")
                                .font(.system(size: 40))
                                .foregroundColor(.textMuted)

                            Text("Morning sessions are disabled")
                                .font(Theme.Typography.body)
                                .foregroundColor(.textSecondary)

                            Text("You can enable them later in Settings")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textMuted)
                        }
                        .padding(Theme.Spacing.xl)
                    }

                    Spacer(minLength: Theme.Spacing.lg)
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
    }
}

// MARK: - Quick Time Button

struct QuickTimeButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Color.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Day Time Row

struct DayTimeRow: View {
    let day: DayOfWeek
    @Binding var time: Date
    let accentColor: Color
    let isExpanded: Bool
    let onToggleExpand: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggleExpand) {
                HStack {
                    Text(day.shortName)
                        .font(Theme.Typography.subheading)
                        .foregroundColor(accentColor)
                        .frame(width: 50, alignment: .leading)

                    Text(day.fullName)
                        .font(Theme.Typography.body)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Text(time.timeString)
                        .font(Theme.Typography.body)
                        .foregroundColor(.textSecondary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
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
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.nightSkyGradient.ignoresSafeArea()
        MorningConfigView(viewModel: OnboardingViewModel())
    }
}
