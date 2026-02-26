//
//  JournalEntryView.swift
//  Meridian
//
//  Journal entry screen for writing morning, night, or anytime entries.
//

import SwiftUI

/// Main journal entry screen
struct JournalEntryView: View {
    @StateObject private var viewModel: JournalEntryViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool

    let onComplete: (() -> Void)?

    // MARK: - Initialization

    init(sessionType: SessionType, onComplete: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: JournalEntryViewModel(sessionType: sessionType))
        self.onComplete = onComplete
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.nightSkyGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            // Morning entry reference (for night sessions)
                            if viewModel.showMorningReference, let morningEntry = viewModel.morningEntry {
                                MorningReferenceCard(entry: morningEntry)
                            }

                            // Prompt
                            Text(viewModel.prompt)
                                .font(Theme.Typography.body)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, Theme.Spacing.sm)

                            // Text editor
                            ZStack(alignment: .topLeading) {
                                if viewModel.entryText.isEmpty {
                                    Text("Start writing...")
                                        .font(Theme.Typography.body)
                                        .foregroundColor(.textMuted)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                }

                                TextEditor(text: $viewModel.entryText)
                                    .font(Theme.Typography.body)
                                    .foregroundColor(.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .focused($isTextFieldFocused)
                                    .frame(minHeight: 200)
                            }
                            .padding()
                            .glassmorphism()
                        }
                        .padding(Theme.Spacing.md)
                    }

                    // Bottom bar with word count and submit
                    bottomBar
                }

                // Error toast
                if let error = viewModel.errorMessage {
                    VStack {
                        ErrorToast(message: error)
                            .padding(.top, Theme.Spacing.lg)
                        Spacer()
                    }
                }
            }
            .navigationTitle(viewModel.headerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.isLocked {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.textSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    sessionTypeIndicator
                }
            }
            .interactiveDismissDisabled(viewModel.isLocked)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }

    // MARK: - Session Type Indicator

    private var sessionTypeIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: viewModel.sessionType.iconName)
            Text(viewModel.sessionType.headerTitle)
        }
        .font(Theme.Typography.caption)
        .foregroundColor(viewModel.sessionType == .morning ? .morningStar : .primaryButton)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Word count
            WordCountView(
                count: viewModel.wordCount,
                minimum: viewModel.minimumWords,
                requiresMinimum: viewModel.sessionType.requiresMinimumWords
            )

            // Submit button
            Button(action: submitEntry) {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Complete Entry")
                        Image(systemName: "arrow.right")
                    }
                }
                .primaryButtonStyle(isEnabled: viewModel.canSubmit)
            }
            .disabled(!viewModel.canSubmit)
        }
        .padding(Theme.Spacing.md)
        .background(Color.surfaceDark.opacity(0.95))
    }

    // MARK: - Submit

    private func submitEntry() {
        Task {
            let success = await viewModel.submitEntry()
            if success {
                dismiss()
                onComplete?()
            }
        }
    }
}

// MARK: - Word Count View

struct WordCountView: View {
    let count: Int
    let minimum: Int
    let requiresMinimum: Bool

    private var isMetMinimum: Bool {
        count >= minimum
    }

    private var textColor: Color {
        if !requiresMinimum { return .textSecondary }
        return isMetMinimum ? .success : .textSecondary
    }

    var body: some View {
        HStack {
            Text("\(count) words")
                .font(Theme.Typography.caption)
                .foregroundColor(textColor)

            if requiresMinimum {
                Text("•")
                    .foregroundColor(.textMuted)

                if isMetMinimum {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Minimum reached")
                    }
                    .font(Theme.Typography.small)
                    .foregroundColor(.success)
                } else {
                    Text("Min: \(minimum) words")
                        .font(Theme.Typography.small)
                        .foregroundColor(.textMuted)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Morning Reference Card

struct MorningReferenceCard: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.morningStar)
                Text("This morning you wrote:")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
            }

            Text(entry.previewText)
                .font(Theme.Typography.body)
                .foregroundColor(.textPrimary)
                .lineLimit(3)
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Error Toast

struct ErrorToast: View {
    let message: String

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)

            Text(message)
                .font(Theme.Typography.caption)
                .foregroundColor(.white)
        }
        .padding(Theme.Spacing.sm)
        .background(Color.error)
        .cornerRadius(Theme.CornerRadius.medium)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, Theme.Spacing.md)
    }
}

#Preview {
    JournalEntryView(sessionType: .morning)
}
