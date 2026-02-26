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

    var body: some View {
        ZStack {
            // Background gradient
            Color.nightSkyGradient
                .ignoresSafeArea()

            // Stars or empty state
            if viewModel.isEmpty {
                EmptyNightSkyView()
            } else {
                starsView
            }

            // Navigation overlay
            VStack {
                topBar
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
            if let entry = viewModel.selectedEntry {
                EntryDetailView(entry: entry)
            }
        }
        .onAppear {
            viewModel.loadEntries()
        }
    }

    // MARK: - Stars View

    private var starsView: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(viewModel.entries) { entry in
                    StarView(
                        entry: entry,
                        size: geometry.size,
                        onTap: { viewModel.viewEntryDetail(entry) }
                    )
                }
            }
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

            // Date display
            Text(Date().shortMonthDay)
                .font(Theme.Typography.subheading)
                .foregroundColor(.textSecondary)

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
                Text("\(viewModel.entryCount) stars")
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

// MARK: - Entry Detail View

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
                            Text(entry.timestamp.fullDate)
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                        }

                        // Time
                        Text(entry.timestamp.timeString)
                            .font(Theme.Typography.caption)
                            .foregroundColor(.textMuted)

                        Divider()
                            .background(Color.white.opacity(0.1))

                        // Content
                        Text(entry.content)
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
            .navigationTitle(entry.timestamp.formattedWithSession(entry.sessionType))
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
}
