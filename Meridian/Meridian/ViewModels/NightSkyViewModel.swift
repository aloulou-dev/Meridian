//
//  NightSkyViewModel.swift
//  Meridian
//
//  ViewModel for the Night Sky home screen.
//

import SwiftUI
import Combine

/// One star per calendar day (combines morning + night entries for that day)
struct DayStar: Identifiable {
    let date: Date
    let entries: [JournalEntry]
    var id: Date { date }

    var position: (x: Double, y: Double) {
        Date.starPositionForDay(date)
    }

    /// Most recent entry for this day (for backward compatibility)
    var latestEntry: JournalEntry? {
        entries.max(by: { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) })
    }

    /// Morning entry for this day (if any)
    var morningEntry: JournalEntry? {
        entries.first { $0.sessionType == .morning }
    }

    /// Night entry for this day (if any)
    var nightEntry: JournalEntry? {
        entries.first { $0.sessionType == .night }
    }

    /// Extra/anytime reflections for this day (+ button), in chronological order
    var anytimeEntries: [JournalEntry] {
        entries
            .filter { $0.sessionType == .anytime }
            .sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
    }

    /// Total word count across all entries
    var totalWordCount: Int {
        entries.reduce(0) { $0 + $1.wordCount }
    }

    /// Week identifier for constellation grouping
    var weekIdentifier: WeekIdentifier {
        WeekIdentifier(from: date)
    }
}

/// ViewModel for the Night Sky view
final class NightSkyViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var entries: [JournalEntry] = []
    /// One star per day (grouped from entries)
    @Published var starDays: [DayStar] = []
    @Published var selectedDayStar: DayStar?
    @Published var isLoading = false
    @Published var showSettings = false
    @Published var showSearch = false
    @Published var showJournalEntry = false
    @Published var showEntryDetail = false

    // MARK: - Services

    private let coreDataService = CoreDataService.shared
    private let lockStateManager = LockStateManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var isEmpty: Bool {
        starDays.isEmpty
    }

    var entryCount: Int {
        starDays.count
    }

    /// Pre-computed renderable stars for Canvas-based rendering
    var renderableStars: [RenderableStar] {
        starDays.map { RenderableStar.from(dayStar: $0) }
    }

    /// Constellation lines connecting same-week stars
    var constellationLines: [ConstellationLine] {
        // Group stars by week
        let byWeek = Dictionary(grouping: starDays) { $0.weekIdentifier }
        var lines: [ConstellationLine] = []

        for (week, starsInWeek) in byWeek {
            // Need at least 2 stars to form a constellation
            guard starsInWeek.count >= Theme.Constellation.minimumStarsForConstellation else {
                continue
            }

            // Sort by date and connect sequentially
            let sorted = starsInWeek.sorted { $0.date < $1.date }
            for i in 0..<(sorted.count - 1) {
                lines.append(ConstellationLine(
                    startStarID: sorted[i].date,
                    endStarID: sorted[i + 1].date,
                    weekIdentifier: week,
                    opacity: Theme.Constellation.lineOpacity
                ))
            }
        }

        return lines
    }

    // MARK: - Initialization

    init() {
        loadEntries()
        observeLockState()
    }

    // MARK: - Data Loading

    /// Load all journal entries and group into one star per day
    func loadEntries() {
        isLoading = true
        entries = coreDataService.fetchAllEntries(limit: 365)
        starDays = Self.groupEntriesByDay(entries)
        isLoading = false
    }

    /// Group entries by calendar day (one star per day)
    private static func groupEntriesByDay(_ entries: [JournalEntry]) -> [DayStar] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry -> Date in
            let ts = entry.timestamp ?? Date()
            return calendar.startOfDay(for: ts)
        }
        return grouped.keys.sorted(by: >).map { date in
            DayStar(date: date, entries: grouped[date] ?? [])
        }
    }

    /// Refresh entries from Core Data
    func refresh() {
        loadEntries()
    }

    // MARK: - Lock State Observation

    private func observeLockState() {
        lockStateManager.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                // If we become locked, we should navigate away from Night Sky
                // The RootView will handle this
                if state.isLocked {
                    self?.dismissModals()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    /// Open the journal entry for anytime journaling
    func startAnytimeJournal() {
        showJournalEntry = true
    }

    /// View details for a day (show both morning and night sessions)
    func viewDayDetail(_ dayStar: DayStar) {
        selectedDayStar = dayStar
        showEntryDetail = true
    }

    /// Dismiss all modals
    func dismissModals() {
        showSettings = false
        showSearch = false
        showJournalEntry = false
        showEntryDetail = false
        selectedDayStar = nil
    }

    /// Called when a new entry is created
    func onEntryCreated() {
        loadEntries()
        showJournalEntry = false
    }
}
