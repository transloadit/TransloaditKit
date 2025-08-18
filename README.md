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

### Simple initialization; pass key and secret to the SDK

```swift
let credentials = Transloadit.Credentials(key: "SomeKey", secret: "SomeSecret")
let transloadit = Transloadit(credentials: credentials, session: URLSession.shared)
```

Certain transloadit endpoints (can) require signatures to be included in their requests. The SDK can automatically generate signatures on your behalf but this requires you to pass both your Transloadit key _and_ secret to the SDK.

The SDK does not persist your secret locally beyond the SDK's lifetime.

This means that you're free to obtain your SDK secret in a secure manner from an external host or that you can include it in your app binary. It's up to you.

It's also possible to initialize the SDK with a `nil` secret and manage signing yourself.

### Advanced initialization; omit secret for manual request signing

If, for security reasons, you choose to not expose your API secret to the app in any way, shape, or form, you can manage signature generation yourself. This allows you to generate signatures on your server and provide them to Transloadit as needed.

To do this, use the `Transloadit` initializer that takes an api key and a `signatureGenerator`

```swift
let transloadit = Transloadit(
    apiKey: "YOUR-API-KEY", 
    sessionConfiguration: .default, 
    signatureGenerator: { stringToSign, onSignatureGenerated in
        mySigningService.sign(stringToSign) { result in 
          onSignatureGenerated(result)
        }
    })
```

The signature generator is defined as follows:

```swift
public typealias SignatureCompletion = (Result<String, Error>) -> Void
public typealias SignatureGenerator = (String, SignatureCompletion) -> Void
```

The generator itself is passed a string that needs to be signed (a JSON representation of the request parameters that you're generating a signature for) and a closure that you _must_ call to inform the SDK when you're done generating the signature (whether it's successful or failed).

**Important** if you don't call the completion handler, your requests will never be sent. The SDK does not implement a fallback or timeout. 

The SDK will invoke the signature generator for every request that requires a signature. It will pass a parameter string for each request to your closure which you can then send to your service (local or external) for signature generation.

To learn more about signature generation see this page: https://transloadit.com/docs/api/authentication/

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
