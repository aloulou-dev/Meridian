//
//  CameraCaptureView.swift
//  Meridian
//
//  SwiftUI wrapper around UIImagePickerController for taking photos
//  of physical journal entries.
//

import SwiftUI
import UIKit

struct CameraCaptureView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    let onPhotoCaptured: (UIImage, Data) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, onPhotoCaptured: onPhotoCaptured)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let dismiss: DismissAction
        private let onPhotoCaptured: (UIImage, Data) -> Void

        init(dismiss: DismissAction, onPhotoCaptured: @escaping (UIImage, Data) -> Void) {
            self.dismiss = dismiss
            self.onPhotoCaptured = onPhotoCaptured
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage,
               let jpegData = image.jpegData(compressionQuality: 0.8) {
                onPhotoCaptured(image, jpegData)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
