//
//  TransloaditKitExampleApp.swift
//  TransloaditKitExample
//
//  Created by Tjeerd in ‘t Veen on 12/10/2021.
//

import SwiftUI
import TransloaditKit
import Atlantis

final class MyUploader: ObservableObject {
    @Published var progress: Float = 0.0
    @Published var uploadCompleted = false
    
    let transloadit: Transloadit
    
    init(backgroundUploader: Bool = false) {
        let credentials = Transloadit.Credentials(key: "OsCOAe4ro8CyNsHTp8pdhSiyEzuqwBue", secret: "jB5gZqmkiu2sdSwc7pko8iajD9ailws1eYUtwoKj")

        if backgroundUploader {
            self.transloadit = Transloadit(credentials: credentials, sessionConfiguration: .background(withIdentifier: "com.transloadit.bg_sample"))
        } else {
            self.transloadit = Transloadit(credentials: credentials, sessionConfiguration: .default)
        }
        self.transloadit.fileDelegate = self
    }
    
    func upload2(_ urls: [URL]) {
        let templateID = "1a84d2f1f2584f92981bda285bbc4e84"
        
        transloadit.createAssembly(templateId: templateID, andUpload: urls, customFields: ["hello": "world"]) { result in
            switch result {
            case .success(let assembly):
                print("Retrieved \(assembly)")
            case .failure(let error):
                print("Assembly error \(error)")
            }
        }.pollAssemblyStatus { result in
            switch result {
            case .success(let assemblyStatus):
                print("Received assemblystatus \(assemblyStatus)")
            case .failure(let error):
                print("Caught polling error \(error)")
            }
        }
    }
    
    func upload(_ urls: [URL]) {
        let resizeStep = StepFactory.makeResizeStep(width: 200, height: 100)
        transloadit.createAssembly(steps: [resizeStep], andUpload: urls, customFields: ["hello": "world"]) { result in
            switch result {
            case .success(let assembly):
                print("Retrieved \(assembly)")
            case .failure(let error):
                print("Assembly error \(error)")
            }
        }.pollAssemblyStatus { result in
            switch result {
            case .success(let assemblyStatus):
                print("Received assemblystatus \(assemblyStatus)")
            case .failure(let error):
                print("Caught polling error \(error)")
            }
        }
    }
}

enum StepFactory {
    static func makeResizeStep(width: Int, height: Int) -> Step {
        Step(name: "resize", robot: "/image/resize", options: ["width": width,
                                                               "height": height,
                                                               "resize_strategy": "fit",
                                                               "result": true])
    }
    
}

extension MyUploader: TransloaditFileDelegate {
    func progressFor(assembly: Assembly, bytesUploaded: Int, totalBytes: Int, client: Transloadit) {
        print("Progress for \(assembly) is \(bytesUploaded) / \(totalBytes)")
        Task { @MainActor in
            progress = Float(bytesUploaded) / Float(totalBytes)
        }
    }
    
    func totalProgress(bytesUploaded: Int, totalBytes: Int, client: Transloadit) {
        print("Total bytes \(totalBytes)")
    }
    
    func didErrorOnAssembly(errror: Error, assembly: Assembly, client: Transloadit) {
        print("didErrorOnAssembly")
    }
    
    func didError(error: Error, client: Transloadit) {
        print("didError")
    }
    
    func didCreateAssembly(assembly: Assembly, client: Transloadit) {
        print("didCreateAssembly \(assembly)")
    }
    
    func didFinishUpload(assembly: Assembly, client: Transloadit) {
        print("didFinishUpload")
        Task { @MainActor in
            progress = 1.0
            uploadCompleted = true
        }
        
        transloadit.fetchStatus(assemblyURL: assembly.url) { result in
            print("status result \(result)")
        }
    }
    
    func didStartUpload(assembly: Assembly, client: Transloadit) {
        print("didStartUpload")
        Task { @MainActor in
            progress = 0.0
            uploadCompleted = false
        }
    }
}

@main
struct TransloaditKitExampleApp: App {
    @StateObject var uploader = MyUploader()
    @StateObject var backgroundUploader = MyUploader(backgroundUploader: true)
    
    init() {
        Atlantis.start(hostName: "donnys-macbook-pro-2.local.")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(uploader: uploader, backgroundUploader: backgroundUploader)
        }
    }
}
