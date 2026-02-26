//
//  SearchViewModel.swift
//  Meridian
//
//  ViewModel for the search and filter screen.
//

import SwiftUI
import Combine

/// Filter option for entries
enum EntryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case morning = "Morning"
    case night = "Night"
    case anytime = "Anytime"

    var id: String { rawValue }

    var sessionType: SessionType? {
        switch self {
        case .all: return nil
        case .morning: return .morning
        case .night: return .night
        case .anytime: return .anytime
        }
    }

    var iconName: String {
        switch self {
        case .all: return "star.fill"
        case .morning: return "sun.max.fill"
        case .night: return "moon.stars.fill"
        case .anytime: return "pencil"
        }
    }

    var color: Color {
        switch self {
        case .all: return .primaryButton
        case .morning: return .morningStar
        case .night: return .nightStar
        case .anytime: return .textSecondary
        }
    }
}

/// ViewModel for the search view
final class SearchViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var searchQuery: String = ""
    @Published var selectedFilter: EntryFilter = .all
    @Published var results: [JournalEntry] = []
    @Published var isSearching = false

    // Date range
    @Published var showDatePicker = false
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var useDateRange = false

    // Entry detail
    @Published var selectedEntry: JournalEntry?
    @Published var showEntryDetail = false

    // MARK: - Services

    private let coreDataService = CoreDataService.shared
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var resultCount: Int {
        results.count
    }

    var isEmpty: Bool {
        results.isEmpty && !isSearching
    }

    var hasActiveFilters: Bool {
        selectedFilter != .all || useDateRange || !searchQuery.isEmpty
    }

    // MARK: - Initialization

    init() {
        setupSearchDebounce()
        performSearch()
    }

    // MARK: - Search Setup

    private func setupSearchDebounce() {
        // Debounce search query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.performSearch()
            }
            .store(in: &cancellables)

        // React to filter changes immediately
        $selectedFilter
            .dropFirst()
            .sink { [weak self] _ in
                self?.performSearch()
            }
            .store(in: &cancellables)

        // React to date range changes
        Publishers.CombineLatest3($useDateRange, $startDate, $endDate)
            .dropFirst()
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.performSearch()
            }
            .store(in: &cancellables)
    }

    // MARK: - Search

    func performSearch() {
        // Cancel any existing search task
        searchTask?.cancel()

        isSearching = true

        searchTask = Task { @MainActor in
            // Small delay for UI feedback
            try? await Task.sleep(nanoseconds: 100_000_000)

            guard !Task.isCancelled else { return }

            let fetchedResults: [JournalEntry]

            if useDateRange {
                fetchedResults = coreDataService.fetchEntries(
                    from: startDate.startOfDay,
                    to: endDate.endOfDay,
                    ofType: selectedFilter.sessionType
                )
            } else if !searchQuery.isEmpty {
                fetchedResults = coreDataService.searchEntries(
                    query: searchQuery,
                    ofType: selectedFilter.sessionType
                )
            } else if let sessionType = selectedFilter.sessionType {
                fetchedResults = coreDataService.fetchEntries(ofType: sessionType)
            } else {
                fetchedResults = coreDataService.fetchAllEntries()
            }

            // Apply search query filter if we're using date range
            if useDateRange && !searchQuery.isEmpty {
                let query = searchQuery.lowercased()
                results = fetchedResults.filter {
                    $0.content.lowercased().contains(query)
                }
            } else {
                results = fetchedResults
            }

            isSearching = false
        }
    }

    // MARK: - Actions

    func selectFilter(_ filter: EntryFilter) {
        selectedFilter = filter
    }

    func toggleDateRange() {
        useDateRange.toggle()
    }

    func clearFilters() {
        searchQuery = ""
        selectedFilter = .all
        useDateRange = false
        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        endDate = Date()
    }

    func viewEntryDetail(_ entry: JournalEntry) {
        selectedEntry = entry
        showEntryDetail = true
    }
}
