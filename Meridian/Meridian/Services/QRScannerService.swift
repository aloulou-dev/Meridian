//
//  QRScannerService.swift
//  Meridian
//
//  Camera-based QR code scanning for totem unlock flow.
//

import AVFoundation
import Combine
import SwiftUI
import UIKit

enum QRScannerError: Error {
    case cameraUnavailable
    case permissionDenied
}

final class QRScannerService: NSObject, ObservableObject {
    @Published private(set) var scannedCode: String?
    @Published private(set) var isRunning = false
    @Published private(set) var error: String?

    let captureSession = AVCaptureSession()
    private var onCodeScanned: ((String) -> Void)?
    private var isConfigured = false

    static var isCameraAvailable: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    static func requestCameraAccess() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    static var cameraPermissionGranted: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    func verifyTotem(_ scannedCode: String) -> Bool {
        guard let registered = SettingsService.shared.totemIdentifier else { return false }
        return scannedCode == registered
    }

    func startScanning(onCodeScanned: @escaping (String) -> Void) {
        self.onCodeScanned = onCodeScanned
        scannedCode = nil
        error = nil

        guard Self.isCameraAvailable else {
            error = "Camera is not available on this device"
            return
        }

        guard Self.cameraPermissionGranted else {
            error = "Camera permission not granted"
            return
        }

        if !isConfigured {
            configureCaptureSession()
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isRunning = true
            }
        }
    }

    func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }
    }

    private func configureCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            error = "Failed to configure camera"
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(output) else {
            error = "Failed to configure scanner"
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        captureSession.commitConfiguration()
        isConfigured = true
    }
}

extension QRScannerService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let value = object.stringValue,
              !value.isEmpty else { return }

        scannedCode = value
        stopScanning()
        onCodeScanned?(value)
    }
}

// MARK: - SwiftUI Camera Preview

struct QRCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            previewLayer.videoGravity = .resizeAspectFill
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
