//
//  TransloaditKitExampleApp.swift
//  TransloaditKitExample
//
//  Created by Tjeerd in ‘t Veen on 12/10/2021.
//

import SwiftUI
import TransloaditKit

final class MyUploader: ObservableObject {
    let config = ["key": "MY KEY", "secret": "MY SECRET", "bucket": "MY BUCKET"]
    let transloadit: Transloadit
    
    func upload(_ urls: [URL]) {
        let resizeStep = StepFactory.makeResizeStep(width: 200, height: 100)
        
        let customStep = Step(name: "custom", robot: "/blabla/custom", options: [ "resize_strategy": "fit",
                                                                                 "result": true])
        transloadit.createAssembly(steps: [resizeStep, customStep], file: urls[0])
    }
    
    init() {
        self.transloadit = Transloadit(config: config, session: URLSession.shared)
        self.transloadit.delegate = self
        
        /*
        // Continuation
        // TODO: Figure out restoring session together with TUS. Tus just starts now.
        let assemblies = transloadit.continueUploads()
        let assemblies = transloadit.continueUploads(ids: ids)
        */
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

extension MyUploader: TransloaditDelegate {
    func didCreateAssembly(assembly: Assembly, client: Transloadit) {
        print("didCreateAssembly")
    }
    
    func didError(assembly: Assembly) {
        print("didError")
    }
    
    func didFinishUpload(assembly: Assembly, client: Transloadit) {
        print("didFinishUpload")
    }
    
    func didStartUpload(assembly: Assembly, client: Transloadit) {
        print("didStartUpload")
    }
    
    func progress(assembly: Assembly, bytedUploaded: Int, bytesTotal: Int, client: Transloadit) {
        print("progress")
    }
}

@main
struct TransloaditKitExampleApp: App {
    @ObservedObject var uploader: MyUploader
    
    init() {
        self.uploader = MyUploader()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(uploader: uploader)
        }
    }
}
