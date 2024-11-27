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
    let transloadit: Transloadit
    
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
    
    init() {
        let credentials = Transloadit.Credentials(key: "", secret: "")
        self.transloadit = Transloadit(credentials: credentials, sessionConfiguration: .default)
        //self.transloadit = Transloadit(credentials: credentials, sessionConfiguration: .background(withIdentifier: "com.transloadit.bg_sample"))
        self.transloadit.fileDelegate = self
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
        
        transloadit.fetchStatus(assemblyURL: assembly.url) { result in
            print("status result \(result)")
        }
    }
    
    func didStartUpload(assembly: Assembly, client: Transloadit) {
        print("didStartUpload")
    }
}

@main
struct TransloaditKitExampleApp: App {
    @ObservedObject var uploader: MyUploader
    
    init() {
        self.uploader = MyUploader()
        Atlantis.start(hostName: "donnys-macbook-pro-2.local.")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(uploader: uploader)
        }
    }
}
