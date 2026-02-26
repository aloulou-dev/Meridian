//
//  NightConfigView.swift
//  Meridian
//
//  Night session (bedtime) configuration screen.
//

import SwiftUI

/// Onboarding screen for configuring bedtimes
struct NightConfigView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var expandedDays: Set<DayOfWeek> = []

    var body: some View {
        OnboardingPageTemplate(
            title: "Evening Wind Down",
            subtitle: "Set your night session time for each day",
            buttonTitle: "Continue",
            isButtonEnabled: true,
            showBackButton: true,
            onBack: { viewModel.goToPreviousStep() },
            onNext: { viewModel.goToNextStep() }
        ) {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    // Quick set buttons
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("Weekdays")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.textMuted)

                        HStack(spacing: Theme.Spacing.sm) {
                            QuickTimeButton(title: "9:00 PM") {
                                viewModel.setBedtimeForWeekdays(Date.today(hour: 21))
                            }
                            QuickTimeButton(title: "10:00 PM") {
                                viewModel.setBedtimeForWeekdays(Date.today(hour: 22))
                            }
                            QuickTimeButton(title: "11:00 PM") {
                                viewModel.setBedtimeForWeekdays(Date.today(hour: 23))
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)

                    VStack(spacing: Theme.Spacing.xs) {
                        Text("Weekends")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.textMuted)

                        HStack(spacing: Theme.Spacing.sm) {
                            QuickTimeButton(title: "10:00 PM") {
                                viewModel.setBedtimeForWeekends(Date.today(hour: 22))
                            }
                            QuickTimeButton(title: "11:00 PM") {
                                viewModel.setBedtimeForWeekends(Date.today(hour: 23))
                            }
                            QuickTimeButton(title: "12:00 AM") {
                                viewModel.setBedtimeForWeekends(Date.today(hour: 0))
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)

                    // Day-by-day configuration
                    VStack(spacing: Theme.Spacing.xs) {
                        ForEach(DayOfWeek.allCases) { day in
                            DayTimeRow(
                                day: day,
                                time: Binding(
                                    get: { viewModel.getBedtime(for: day) },
                                    set: { viewModel.setBedtime($0, for: day) }
                                ),
                                accentColor: .primaryButton,
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
                    VStack(spacing: Theme.Spacing.xs) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.primaryButton)
                            Text("Apps lock at this time")
                                .font(Theme.Typography.small)
                                .foregroundColor(.textSecondary)
                        }

                        Text("Choose a consistent time that supports your evening reflection rhythm")
                            .font(Theme.Typography.small)
                            .foregroundColor(.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .cardStyle()
                    .padding(.horizontal, Theme.Spacing.md)

                    Spacer(minLength: Theme.Spacing.lg)
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.nightSkyGradient.ignoresSafeArea()
        NightConfigView(viewModel: OnboardingViewModel())
    }
}
