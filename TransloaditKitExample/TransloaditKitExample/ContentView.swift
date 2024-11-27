//
//  ContentView.swift
//  TransloaditKitExample
//
//  Created by Tjeerd in ‘t Veen on 12/10/2021.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var uploader: MyUploader
    @State private var showingImagePicker = false
    
    var body: some View {
        VStack {
            Text("TransloadIt")
                .font(.title)
                .padding()
            
            Button("Select image(s)") {
                showingImagePicker.toggle()
            }.sheet(isPresented:$showingImagePicker, content: {
                PhotoPicker { [weak uploader] urls in
                    print(urls)
                    uploader?.upload(urls)
                }
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let uploader = MyUploader()
        ContentView(uploader: uploader)
    }
}
