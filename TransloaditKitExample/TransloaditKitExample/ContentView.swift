//
//  ContentView.swift
//  TransloaditKitExample
//
//  Created by Tjeerd in ‘t Veen on 12/10/2021.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var uploader: MyUploader
    @ObservedObject var backgroundUploader: MyUploader
    @State private var showingImagePicker = false
    @State var uploadUsingBackgroundConfig = false
    
    var currentUploader: MyUploader {
        uploadUsingBackgroundConfig ? backgroundUploader : uploader
    }
    
    var body: some View {
        VStack {
            Text("TransloadIt")
                .font(.title)
                .padding()
            
            Button("Select image(s)") {
                showingImagePicker.toggle()
            }.sheet(isPresented:$showingImagePicker, content: {
                PhotoPicker { [weak uploader, weak backgroundUploader] urls in
                    print(urls)
                    if uploadUsingBackgroundConfig {
                        backgroundUploader?.upload(urls)
                    } else {
                        uploader?.upload(urls)
                    }
                }
            })
            
            Toggle(isOn: $uploadUsingBackgroundConfig, label: {
                Text("Upload using background session")
            })
            .padding(.vertical, 8)
            
            if currentUploader.progress > 0.0 && !currentUploader.uploadCompleted {
                Text("Upload progress")
                ProgressView(value: currentUploader.progress, total: 1.0)
            } else if currentUploader.uploadCompleted {
                Text("File uploaded 🟢")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let uploader = MyUploader()
        let bgUploader = MyUploader(backgroundUploader: true)
        ContentView(uploader: uploader, backgroundUploader: bgUploader)
    }
}
