//
//  NightSkyViewModel.swift
//  Meridian
//
//  ViewModel for the Night Sky home screen.
//

import SwiftUI
import Combine

/// ViewModel for the Night Sky view
final class NightSkyViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var entries: [JournalEntry] = []
    @Published var selectedEntry: JournalEntry?
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
        entries.isEmpty
    }

    var entryCount: Int {
        entries.count
    }

    // MARK: - Initialization

    init() {
        loadEntries()
        observeLockState()
    }

    // MARK: - Data Loading

    /// Load all journal entries
    func loadEntries() {
        isLoading = true
        entries = coreDataService.fetchAllEntries(limit: 365)
        isLoading = false
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

    /// View details for a specific entry
    func viewEntryDetail(_ entry: JournalEntry) {
        selectedEntry = entry
        showEntryDetail = true
    }

    /// Dismiss all modals
    func dismissModals() {
        showSettings = false
        showSearch = false
        showJournalEntry = false
        showEntryDetail = false
        selectedEntry = nil
    }

    /// Called when a new entry is created
    func onEntryCreated() {
        loadEntries()
        showJournalEntry = false
    }
}
