//
//  NightSkyView.swift
//  Meridian
//
//  Main home screen showing journal entries as stars.
//

import SwiftUI

/// Main home screen with night sky visualization
struct NightSkyView: View {
    @StateObject private var viewModel = NightSkyViewModel()
    @EnvironmentObject var lockStateManager: LockStateManager
    @EnvironmentObject var settingsService: SettingsService

    var body: some View {
        ZStack {
            // Background gradient
            Color.nightSkyGradient
                .ignoresSafeArea()

            // Stars or empty state
            if viewModel.isEmpty {
                EmptyNightSkyView()
            } else {
                NightSkyCanvasView(
                    renderableStars: viewModel.renderableStars,
                    constellationLines: viewModel.constellationLines,
                    onStarTapped: { date in
                        if let dayStar = viewModel.starDays.first(where: { $0.date == date }) {
                            viewModel.viewDayDetail(dayStar)
                        }
                    }
                )
            }

            // Navigation overlay
            VStack {
                topBar
                CyclePhaseIndicator()
                    .padding(.top, Theme.Spacing.xxs)
                Spacer()
                bottomBar
            }
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $viewModel.showSearch) {
            SearchView()
        }
        .sheet(isPresented: $viewModel.showJournalEntry) {
            JournalEntryView(
                sessionType: .anytime,
                onComplete: viewModel.onEntryCreated
            )
        }
        .sheet(isPresented: $viewModel.showEntryDetail) {
            if let dayStar = viewModel.selectedDayStar {
                DayDetailView(dayStar: dayStar)
            }
        }
        .onAppear {
            viewModel.loadEntries()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Settings button
            Button(action: { viewModel.showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.textSecondary)
                    .padding(Theme.Spacing.xs)
            }
            .accessibilityLabel("Settings")

            Spacer()

            // Greeting and date display
            VStack(spacing: 2) {
                if !settingsService.userName.isEmpty {
                    Text("Welcome Back, \(settingsService.userName)")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.textSecondary)
                }

                Text(Date().shortMonthDay)
                    .font(Theme.Typography.subheading)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Search button
            Button(action: { viewModel.showSearch = true }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22))
                    .foregroundColor(.textSecondary)
                    .padding(Theme.Spacing.xs)
            }
            .accessibilityLabel("Search")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            // Entry count
            if !viewModel.isEmpty {
                Text("\(viewModel.entryCount) day\(viewModel.entryCount == 1 ? "" : "s")")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textMuted)
            }

            Spacer()

            // FAB button for anytime journaling
            Button(action: { viewModel.startAnytimeJournal() }) {
                ZStack {
                    Circle()
                        .fill(Color.primaryButton)
                        .frame(width: Theme.Size.fabSize, height: Theme.Size.fabSize)
                        .shadow(color: .primaryButton.opacity(0.4), radius: 12, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("New journal entry")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
    }
}

// MARK: - Day Detail View (both morning + night sessions for one day)

struct DayDetailView: View {
    let dayStar: DayStar
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.nightSkyGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        if let morning = dayStar.morningEntry {
                            SessionBlock(
                                title: "Morning",
                                subtitle: "Set your intentions for the day",
                                entry: morning
                            )
                        }

                        ForEach(Array(dayStar.anytimeEntries.enumerated()), id: \.offset) { index, entry in
                            SessionBlock(
                                title: dayStar.anytimeEntries.count > 1 ? "Reflection \(index + 1)" : "Reflection",
                                subtitle: "Extra journal entry",
                                entry: entry
                            )
                        }

                        if let night = dayStar.nightEntry {
                            SessionBlock(
                                title: "Night",
                                subtitle: "How did your day go?",
                                entry: night
                            )
                        }

                        if dayStar.entries.isEmpty {
                            Text("No entries for this day")
                                .font(Theme.Typography.body)
                                .foregroundColor(.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle(dayStar.date.fullDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryButton)
                }
            }
        }
    }
}

// MARK: - Session Block (one morning, reflection, or night entry in the day detail)

private struct SessionBlock: View {
    let title: String
    let subtitle: String
    let entry: JournalEntry

    private var accentColor: Color {
        if entry.isMorning { return .morningStar }
        if entry.isNight { return .nightStar }
        return .primaryButton
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: entry.sessionType.iconName)
                    .foregroundColor(accentColor)
                Text(title)
                    .font(Theme.Typography.subheading)
                    .foregroundColor(.textPrimary)
            }

            Text(entry.timestamp?.timeString ?? "")
                .font(Theme.Typography.caption)
                .foregroundColor(.textMuted)

            Divider()
                .background(Color.white.opacity(0.1))

            Text(entry.content ?? "")
                .font(Theme.Typography.body)
                .foregroundColor(.textPrimary)
                .lineSpacing(6)

            Text("\(entry.wordCount) words")
                .font(Theme.Typography.small)
                .foregroundColor(.textMuted)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

// MARK: - Entry Detail View (single entry, used e.g. from Search)

struct EntryDetailView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.nightSkyGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        // Header
                        HStack {
                            // Type indicator
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: entry.sessionType.iconName)
                                    .foregroundColor(entry.isMorning ? .morningStar : .nightStar)
                                Text(entry.sessionType.headerTitle)
                                    .font(Theme.Typography.subheading)
                                    .foregroundColor(.textPrimary)
                            }

                            Spacer()

                            // Date
                            Text(entry.timestamp?.fullDate ?? "")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                        }

                        // Time
                        Text(entry.timestamp?.timeString ?? "")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.textMuted)

                        Divider()
                            .background(Color.white.opacity(0.1))

                        // Content
                        Text(entry.content ?? "")
                            .font(Theme.Typography.body)
                            .foregroundColor(.textPrimary)
                            .lineSpacing(6)

                        // Word count
                        Text("\(entry.wordCount) words")
                            .font(Theme.Typography.small)
                            .foregroundColor(.textMuted)
                            .padding(.top, Theme.Spacing.sm)

                        Spacer()
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle(entry.timestamp.map { $0.formattedWithSession(entry.sessionType) } ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryButton)
                }
            }
        }
    }
}

#Preview {
    NightSkyView()
        .environmentObject(LockStateManager.shared)
        .environmentObject(SettingsService.shared)
}
