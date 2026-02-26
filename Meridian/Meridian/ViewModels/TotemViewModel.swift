//
//  TotemViewModel.swift
//  Meridian
//
//  ViewModel for QR code totem scanning and setup.
//

import SwiftUI
import Combine

final class TotemViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var scanStatus: ScanStatus = .idle
    @Published var errorMessage: String?
    @Published var showScanner = false

    // MARK: - Types

    enum ScanStatus: Equatable {
        case idle
        case scanning
        case success
        case failed(String)
        case bypassed
    }

    enum ScanPurpose {
        case setup
        case unlock
    }

    // MARK: - Services

    private let settingsService = SettingsService.shared
    private let lockStateManager = LockStateManager.shared
    let scanner = QRScannerService()
    private(set) var scanPurpose: ScanPurpose = .setup

    // MARK: - Computed Properties

    var isCameraAvailable: Bool {
        QRScannerService.isCameraAvailable
    }

    var hasTotemRegistered: Bool {
        settingsService.totemIdentifier != nil
    }

    var isTotemEnabled: Bool {
        settingsService.isTotemEnabled
    }

    var maskedTotemID: String? {
        guard let identifier = settingsService.totemIdentifier else { return nil }
        if identifier.count > 12 {
            return String(identifier.prefix(6)) + "..." + String(identifier.suffix(6))
        }
        return identifier
    }

    // MARK: - Setup Methods

    @MainActor
    func beginSetupScan() async {
        let granted = await QRScannerService.requestCameraAccess()
        guard granted else {
            errorMessage = "Camera access is required to scan QR codes. Enable it in Settings."
            scanStatus = .failed("Camera permission denied")
            return
        }
        scanPurpose = .setup
        scanStatus = .scanning
        errorMessage = nil
        showScanner = true

        scanner.startScanning { [weak self] code in
            guard let self else { return }
            self.settingsService.registerTotem(code)
            self.scanStatus = .success
            self.showScanner = false
        }
    }

    func clearTotem() {
        settingsService.clearTotem()
        scanStatus = .idle
    }

    // MARK: - Unlock Methods

    @MainActor
    func beginUnlockScan() async {
        guard hasTotemRegistered else {
            unlockApps()
            return
        }

        let granted = await QRScannerService.requestCameraAccess()
        guard granted else {
            errorMessage = "Camera access required"
            scanStatus = .failed("Camera permission denied")
            return
        }

        scanPurpose = .unlock
        scanStatus = .scanning
        errorMessage = nil
        showScanner = true

        scanner.startScanning { [weak self] code in
            guard let self else { return }
            if self.scanner.verifyTotem(code) {
                self.scanStatus = .success
                self.showScanner = false
                self.unlockApps()
            } else {
                self.scanner.stopScanning()
                self.errorMessage = "This QR code does not match your registered code"
                self.scanStatus = .failed("Wrong QR code")
                self.showScanner = false
            }
        }
    }

    func bypassAndUnlock() {
        scanner.stopScanning()
        showScanner = false
        scanStatus = .bypassed
        unlockApps()
    }

    private func unlockApps() {
        lockStateManager.unlockApps()
    }

    // MARK: - Reset

    func reset() {
        scanner.stopScanning()
        showScanner = false
        scanStatus = .idle
        errorMessage = nil
    }
}
