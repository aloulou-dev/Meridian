//
//  TryJournalPromptView.swift
//  Meridian
//
//  Post-onboarding screen asking user if they want to try a journal entry.
//

import SwiftUI

/// View shown after onboarding asking if the user wants to try their first journal entry
struct TryJournalPromptView: View {
    @EnvironmentObject var settingsService: SettingsService
    @State private var showJournalEntry = false
    @State private var starsVisible = false

    private var suggestedSessionType: SessionType {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 12 ? .morning : .night
    }

    private var sessionIcon: String {
        suggestedSessionType == .morning ? "sunrise.fill" : "moon.stars.fill"
    }

    private var sessionTitle: String {
        suggestedSessionType == .morning ? "Morning Intentions" : "Evening Reflection"
    }

    private var sessionDescription: String {
        suggestedSessionType == .morning
            ? "Start your day with clarity by writing your intentions."
            : "Wind down your day with a moment of reflection."
    }

    var body: some View {
        ZStack {
            // Background gradient
            Color.nightSkyGradient
                .ignoresSafeArea()

            // Animated stars background
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: starSize(for: index)))
                    .foregroundColor(index % 2 == 0 ? .morningStar : .nightStar)
                    .opacity(starsVisible ? 0.6 : 0)
                    .offset(starOffset(for: index))
                    .animation(
                        Theme.Animation.starAppear.delay(Double(index) * 0.1),
                        value: starsVisible
                    )
            }

            VStack(spacing: Theme.Spacing.lg) {
                Spacer()

                // Session icon
                Image(systemName: sessionIcon)
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: suggestedSessionType == .morning
                                ? [.morningStar, .orange]
                                : [.nightStar, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(starsVisible ? 1 : 0.8)
                    .animation(Theme.Animation.spring, value: starsVisible)

                // Greeting
                VStack(spacing: Theme.Spacing.sm) {
                    if !settingsService.userName.isEmpty {
                        Text("Ready, \(settingsService.userName)?")
                            .font(Theme.Typography.title)
                            .foregroundColor(.textPrimary)
                    } else {
                        Text("Ready to Begin?")
                            .font(Theme.Typography.title)
                            .foregroundColor(.textPrimary)
                    }

                    Text(sessionTitle)
                        .font(Theme.Typography.heading)
                        .foregroundStyle(
                            LinearGradient(
                                colors: suggestedSessionType == .morning
                                    ? [.morningStar, .primaryButton]
                                    : [.nightStar, .primaryButton],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                // Description
                Text(sessionDescription)
                    .font(Theme.Typography.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)

                Spacer()

                // Buttons
                VStack(spacing: Theme.Spacing.sm) {
                    // Try journal button
                    Button(action: {
                        showJournalEntry = true
                    }) {
                        HStack {
                            Text("Try It Now")
                            Image(systemName: "arrow.right")
                        }
                        .primaryButtonStyle()
                    }
                    .padding(.horizontal, Theme.Spacing.md)

                    // Skip button
                    Button(action: {
                        settingsService.hasSeenTryJournalPrompt = true
                    }) {
                        Text("Maybe Later")
                            .font(Theme.Typography.button)
                            .foregroundColor(.textSecondary)
                            .padding(.vertical, Theme.Spacing.sm)
                    }
                }
                .padding(.bottom, Theme.Spacing.lg)
            }
        }
        .sheet(isPresented: $showJournalEntry) {
            JournalEntryView(
                sessionType: suggestedSessionType,
                onComplete: {
                    settingsService.hasSeenTryJournalPrompt = true
                }
            )
        }
        .onAppear {
            withAnimation {
                starsVisible = true
            }
        }
    }

    // MARK: - Star Helpers

    private func starSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [10, 14, 8, 12, 10, 16, 8, 12]
        return sizes[index % sizes.count]
    }

    private func starOffset(for index: Int) -> CGSize {
        let offsets: [CGSize] = [
            CGSize(width: -120, height: -200),
            CGSize(width: 100, height: -250),
            CGSize(width: -80, height: 150),
            CGSize(width: 130, height: 100),
            CGSize(width: -40, height: -150),
            CGSize(width: 60, height: 200),
            CGSize(width: -150, height: 50),
            CGSize(width: 140, height: -100)
        ]
        return offsets[index % offsets.count]
    }
}

#Preview {
    TryJournalPromptView()
        .environmentObject(SettingsService.shared)
}
