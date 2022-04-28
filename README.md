# TransloaditKit

An **iOS** and **macOS** integration for [Transloadit](https://transloadit.com)'s file uploading and encoding service

## Install

### CocoaPods

```ruby
pod 'Transloadit', '~> 3.0'
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/transloadit/TransloaditKit", .upToNextMajor(from: "3.0.0"))
]
```

## Usage

Start by initializing `Transloadit`.

```swift
let credentials = Transloadit.Credentials(key: "SomeKey", secret: "SomeSecret")
let transloadit = Transloadit(credentials: credentials, session: URLSession.shared)
```

### Create an Assembly

To create an `Assembly` you invoke `createAssembly(steps:andUpload:completion)` on `Transloadit`.
It returns a `TransloaditPoller` that you can use to poll for the `AssemblyStatus` of your `Assembly`.

```swift
let resizeStep = Step(
    name: "resize",
    robot: "/image/resize",
    options: [
        "width": 200,
        "height": 100,
        "resize_strategy": "fit",
        "result": true])
        
let filesToUpload: [URL] = ...
transloadit.createAssembly(steps: [resizeStep], andUpload: filesToUpload) { result in
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
```
