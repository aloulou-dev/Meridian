//
//  SearchView.swift
//  Meridian
//
//  Search and filter screen for journal entries.
//

import SwiftUI

/// Search and filter screen
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.nightSkyGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Filter chips
                    filterChips

                    // Date range (if enabled)
                    if viewModel.useDateRange {
                        dateRangePicker
                    }

                    // Results header
                    resultsHeader

                    // Results list or empty state
                    if viewModel.isEmpty {
                        emptyState
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Archives")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryButton)
                }
            }
            .sheet(isPresented: $viewModel.showEntryDetail) {
                if let entry = viewModel.selectedEntry {
                    EntryDetailView(entry: entry)
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textMuted)

            TextField("Search your stars...", text: $viewModel.searchQuery)
                .font(Theme.Typography.body)
                .foregroundColor(.textPrimary)
                .focused($isSearchFocused)

            if !viewModel.searchQuery.isEmpty {
                Button(action: { viewModel.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textMuted)
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Color.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(EntryFilter.allCases) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: viewModel.selectedFilter == filter,
                        onTap: { viewModel.selectFilter(filter) }
                    )
                }

                // Date range toggle
                Button(action: { viewModel.toggleDateRange() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text("Date Range")
                    }
                    .font(Theme.Typography.caption)
                    .foregroundColor(viewModel.useDateRange ? .white : .textSecondary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(viewModel.useDateRange ? Color.primaryButton : Color.cardBackground)
                    .cornerRadius(Theme.CornerRadius.full)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    // MARK: - Date Range Picker

    private var dateRangePicker: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading) {
                    Text("From")
                        .font(Theme.Typography.small)
                        .foregroundColor(.textMuted)
                    DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(.primaryButton)
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("To")
                        .font(Theme.Typography.small)
                        .foregroundColor(.textMuted)
                    DatePicker("", selection: $viewModel.endDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(.primaryButton)
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .cardStyle()
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Results Header

    private var resultsHeader: some View {
        HStack {
            if viewModel.isSearching {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryButton))
                    .scaleEffect(0.8)
                Text("Searching...")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textMuted)
            } else {
                Text("\(viewModel.resultCount) entries")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            if viewModel.hasActiveFilters {
                Button(action: { viewModel.clearFilters() }) {
                    Text("Clear filters")
                        .font(Theme.Typography.small)
                        .foregroundColor(.primaryButton)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.textMuted)

            Text("No entries found")
                .font(Theme.Typography.subheading)
                .foregroundColor(.textSecondary)

            if viewModel.hasActiveFilters {
                Text("Try adjusting your filters")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textMuted)
            }

            Spacer()
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(viewModel.results) { entry in
                    SearchResultRow(entry: entry) {
                        viewModel.viewEntryDetail(entry)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.lg)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let filter: EntryFilter
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: filter.iconName)
                    .font(.system(size: 12))
                Text(filter.rawValue)
            }
            .font(Theme.Typography.caption)
            .foregroundColor(isSelected ? .white : .textSecondary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(isSelected ? filter.color : Color.cardBackground)
            .cornerRadius(Theme.CornerRadius.full)
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let entry: JournalEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                // Type indicator
                Image(systemName: entry.sessionType.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(entry.isMorning ? .morningStar : .nightStar)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    // Date and type
                    HStack {
                        Text(entry.timestamp.shortMonthDay)
                            .font(Theme.Typography.caption)
                            .foregroundColor(.textSecondary)

                        Text("•")
                            .foregroundColor(.textMuted)

                        Text(entry.sessionType.headerTitle)
                            .font(Theme.Typography.caption)
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Text(entry.timestamp.timeString)
                            .font(Theme.Typography.small)
                            .foregroundColor(.textMuted)
                    }

                    // Content preview
                    Text(entry.previewText)
                        .font(Theme.Typography.body)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)

                    // Word count
                    Text("\(entry.wordCount) words")
                        .font(Theme.Typography.small)
                        .foregroundColor(.textMuted)
                }
            }
            .padding(Theme.Spacing.sm)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SearchView()
}
