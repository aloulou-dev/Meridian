//
//  CyclePhaseIndicator.swift
//  Meridian
//
//  Pill-shaped indicator showing the current daily cycle phase.
//

import SwiftUI
import Combine

struct CyclePhaseIndicator: View {
    @EnvironmentObject var lockStateManager: LockStateManager

    @State private var graceRemaining: TimeInterval = 0
    @State private var timerCancellable: AnyCancellable?

    private var phase: LockState { lockStateManager.currentState }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: phase.phaseIcon)
                .font(.system(size: 12, weight: .semibold))

            Text(phase.phaseLabel)
                .font(Theme.Typography.small)
                .fontWeight(.medium)

            if phase == .nightGracePeriod, graceRemaining > 0 {
                Text(formattedCountdown)
                    .font(Theme.Typography.small.monospacedDigit())
                    .fontWeight(.semibold)
            }
        }
        .foregroundColor(phase.phaseColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(phase.phaseColor.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(phase.phaseColor.opacity(0.3), lineWidth: 1))
        .animation(Theme.Animation.fast, value: phase)
        .onAppear { startTimerIfNeeded() }
        .onDisappear { timerCancellable?.cancel() }
        .onChange(of: phase) { _ in startTimerIfNeeded() }
    }

    private var formattedCountdown: String {
        let minutes = Int(graceRemaining) / 60
        let seconds = Int(graceRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startTimerIfNeeded() {
        timerCancellable?.cancel()
        timerCancellable = nil

        guard phase == .nightGracePeriod,
              let endsAt = SettingsService.shared.nightGraceEndsAt else {
            graceRemaining = 0
            return
        }

        graceRemaining = max(0, endsAt.timeIntervalSinceNow)

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let remaining = endsAt.timeIntervalSinceNow
                if remaining <= 0 {
                    graceRemaining = 0
                    timerCancellable?.cancel()
                    timerCancellable = nil
                } else {
                    graceRemaining = remaining
                }
            }
    }
}

#Preview {
    ZStack {
        Color.nightSkyGradient.ignoresSafeArea()
        VStack(spacing: 16) {
            CyclePhaseIndicator()
        }
    }
    .environmentObject(LockStateManager.shared)
}
