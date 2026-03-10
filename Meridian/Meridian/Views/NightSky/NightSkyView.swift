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
    @StateObject private var cameraOrientation = CameraOrientation()
    @EnvironmentObject var lockStateManager: LockStateManager
    @EnvironmentObject var settingsService: SettingsService

    var body: some View {
        ZStack {
            // SceneKit provides the deep navy background; clear here so it shows through
            Color.clear
                .ignoresSafeArea()

            // Stars or empty state
            if viewModel.isEmpty {
                EmptyNightSkyView()
            } else {
                NightSkySceneView(
                    stars: viewModel.renderableStars,
                    lines: viewModel.constellationLines,
                    onStarTapped: { date in
                        if let dayStar = viewModel.starDays.first(where: { $0.date == date }) {
                            viewModel.viewDayDetail(dayStar)
                        }
                    },
                    cameraOrientation: cameraOrientation
                )
            }

            // Navigation overlay
            VStack(spacing: 0) {
                // Fortnite-style heading tape — only when 3D scene is active
                if !viewModel.isEmpty {
                    CompassTape(yaw: cameraOrientation.yaw)
                }
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

// MARK: - Compass Tape (Fortnite-style)

/// Full-width horizontal heading tape.
/// The current heading is always under the fixed downward triangle at center.
/// N is coral, cardinal letters (E/S/W) are white, numeric ticks are dimmer.
private struct CompassTape: View {
    let yaw: Float

    /// Heading in 0–360° where 0 = original forward direction.
    private var heading: Double {
        var deg = Double(yaw) * 180.0 / .pi
        deg = deg.truncatingRemainder(dividingBy: 360)
        if deg < 0 { deg += 360 }
        return deg
    }

    var body: some View {
        Canvas { ctx, size in
            let pxPerDeg = size.width / 180.0   // 180° spans the full tape width
            let cx = size.width / 2
            let h = heading

            // Ticks and labels — draw ±95° around current heading
            for deg in (Int(h) - 95)...(Int(h) + 95) {
                let x = cx + CGFloat(Double(deg) - h) * pxPerDeg
                guard x >= -8 && x <= size.width + 8 else { continue }

                let nd = ((deg % 360) + 360) % 360   // normalize to 0–359

                if nd % 30 == 0 {
                    // Major tick
                    ctx.fill(
                        Path(CGRect(x: x - 0.5, y: size.height - 14, width: 1, height: 11)),
                        with: .color(Color.white.opacity(0.82))
                    )
                    // Label
                    let (label, isCardinal) = headingLabel(nd)
                    let color: Color = nd == 0
                        ? Color(red: 1.0, green: 0.42, blue: 0.42)
                        : (isCardinal ? .white : Color.white.opacity(0.58))
                    ctx.draw(
                        Text(label)
                            .font(.system(size: isCardinal ? 11 : 9, weight: .bold, design: .monospaced))
                            .foregroundColor(color),
                        at: CGPoint(x: x, y: size.height - 27),
                        anchor: .center
                    )
                } else if nd % 10 == 0 {
                    // Minor tick
                    ctx.fill(
                        Path(CGRect(x: x - 0.5, y: size.height - 9, width: 1, height: 7)),
                        with: .color(Color.white.opacity(0.42))
                    )
                } else if nd % 5 == 0 {
                    // Tiny tick
                    ctx.fill(
                        Path(CGRect(x: x - 0.5, y: size.height - 6, width: 1, height: 4)),
                        with: .color(Color.white.opacity(0.22))
                    )
                }
            }

            // Fixed centre indicator: downward-pointing triangle
            var tri = Path()
            tri.move(to: CGPoint(x: cx - 5, y: 0))
            tri.addLine(to: CGPoint(x: cx + 5, y: 0))
            tri.addLine(to: CGPoint(x: cx,     y: 9))
            tri.closeSubpath()
            ctx.fill(tri, with: .color(Color.white.opacity(0.92)))
        }
        .frame(height: 40)
    }

    private func headingLabel(_ deg: Int) -> (String, Bool) {
        switch deg {
        case 0:   return ("N",   true)
        case 90:  return ("E",   true)
        case 180: return ("S",   true)
        case 270: return ("W",   true)
        default:  return ("\(deg)°", false)
        }
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
