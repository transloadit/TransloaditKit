//
//  PhotoPicker.swift
//  TransloaditKitExample
//
//  Created by Tjeerd in ‘t Veen on 12/10/2021.
//

import SwiftUI
import UIKit
import PhotosUI
import TUSKit

struct PhotoPicker: UIViewControllerRepresentable {

    var didPickPhotos: ([URL]) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.selectionLimit = 30
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Use a Coordinator to act as your PHPickerViewControllerDelegate
    class Coordinator: PHPickerViewControllerDelegate {
      
        private let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            var imageURLs = [URL]()
            results.forEach { result in
                let semaphore = DispatchSemaphore(value: 0)
                result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] (object, error) in
                    defer {
                        semaphore.signal()
                    }
                    guard let self = self else { return }
                    if let image = object as? UIImage {
                        let id = UUID().uuidString + ".jpg"
                        let fileManager = FileManager.default
                        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                        let imageURL = appSupportDirectory.appendingPathComponent(id)
                        if !fileManager.fileExists(atPath: appSupportDirectory.path) {
                                try! fileManager.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true, attributes: nil)
                            }
                        
                        if let imageData = image.jpegData(compressionQuality: 0.7) {
                            print(fileManager.createFile(atPath: imageURL.path, contents: imageData, attributes: nil))
                            imageURLs.append(imageURL)
                        } else {
                            print("Could not retrieve image data")
                        }
                        
                        if results.count == imageURLs.count {
                            print("Received \(imageURLs.count) images")
                            self.parent.didPickPhotos(imageURLs)
                        }
                        
                    } else {
                        if let object {
                            print(object)
                        }
                        if let error {
                            print(error)
                        }
                    }
                })
                semaphore.wait()
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        deinit {
            
        }
    }
}
