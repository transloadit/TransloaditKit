# TransloaditKit SDK [![Build Status](https://travis-ci.org/transloadit/TransloaditKit.svg?branch=master)](https://travis-ci.org/transloadit/TransloaditKit) [![Version](https://img.shields.io/cocoapods/v/Transloadit.svg?style=flat)](http://cocoapods.org/pods/Transloadit) [![License](https://img.shields.io/cocoapods/l/Transloadit.svg?style=flat)](http://cocoapods.org/pods/Transloadit) [![Platform](https://img.shields.io/cocoapods/p/Transloadit.svg?style=flat)](http://cocoapods.org/pods/Transloadit)

An **iOS** and **MacOS** integration for [Transloadit](https://transloadit.com)'s file
uploading and encoding service.

## Intro


[Transloadit](https://transloadit.com) is a service that helps you handle file
uploads, resize, crop and watermark your images, make GIFs, transcode your
videos, extract thumbnails, generate audio waveforms, and so much more. In
short, [Transloadit](https://transloadit.com) is the Swiss Army Knife for your
files.

This is an **iOS** and **MacOS**  SDK to make it easy to talk to the
[Transloadit](https://transloadit.com) REST API.

## Install

Inside your podfile add,

```bash
pod 'Transloadit'
```

If there are no errors, you can start using the pod.

## Usage

### Import TransloaditKit
*Objective-C*
```objc
#import <TransloaditKit/Transloadit.h>
```

*Swift*
```Swift
import Transloadit
```


### Define your blocks
`Objective-C`
```objc
transloadit.uploadingProgressBlock = ^(int64_t bytesWritten, int64_t bytesTotal){
// Update your progress bar here
NSLog(@"progress: %llu / %llu", (unsigned long long)bytesWritten, (unsigned long long)bytesTotal);
};

transloadit.uploadingResultBlock = ^(NSURL* fileURL){
// Use the upload url
NSLog(@"url: %@", fileURL);
};

transloadit.uploadingFailureBlock = ^(NSError* error){
// Handle the error
NSLog(@"error: %@", error);
};

transloadit.assemblyCreationResultBlock = ^(Assembly* assembly, NSDictionary* completionDictionary){
NSLog(@"Assembly creation success");
NSLog(@"%@", @"Invoking assembly.");
};

transloadit.assemblyCreationFailureBlock = ^(NSDictionary* completionDictionary){
NSLog(@"Assembly creation failed: %@", [completionDictionary debugDescription]);
};

transloadit.assemblyStatusBlock = ^(NSDictionary* completionDictionary){
NSLog(@"Assembly status: %@", [completionDictionary debugDescription]);
};

transloadit.assemblyResultBlock = ^(NSDictionary* completionDictionary){
NSLog(@"Assembly finished : %@", [completionDictionary debugDescription]);
};

transloadit.assemblyFailureBlock = ^(NSDictionary* completionDictionary){
NSLog(@"Assembly failed: %@", [completionDictionary debugDescription]);
};
```
`Swift`
```Swift
self.transloadit.assemblyCreationResultBlock = { assembly, completionDictionary in
print("Assembly created!")
}
self.transloadit.assemblyCreationFailureBlock = { completionDictionary in
print("Assembly creation failed")
}

self.transloadit.assemblyResultBlock = { completionDictionary in
print("Assembly finished executing!")
}
self.transloadit.assemblyStatusBlock = { completionDictionary in
print("Assembly is executing!")
}

self.transloadit.assemblyFailureBlock = { completionDictionary in
print("Assembly failed executing!")
}

self.transloadit.uploadResultBlock = { url in
print("file uploaded!")
}
self.transloadit.uploadProgressBlock =  {bytesWritten, bytesTotal in
print("Assembly uploading!")
}
self.transloadit.uploadFailureBlock = { error in
print("Assembly failed uploading!")
}

self.transloadit.templateCreationResultBlock = { template, completionDictionary in
print("Template created!")
}

self.transloadit.templateCreationFailureBlock = { completionDictionary in
print("Template failed creating!")
}
```


### Setup TransloaditKit
`Objective-C`
```objc
- (void)viewDidLoad {
[super viewDidLoad];
transloadit = [[Transloadit alloc] init];
}
```
`Swift`
```swift
// Simply setup a Transloadit object
let transloadit: Transloadit = Transloadit()
```

*{PROJECT_NAME}.plist*
```xml
<key>TRANSLOADIT_SECRET</key>
<string>SECRET_KEY_HERE</string>
<key>TRANSLOADIT_KEY</key>
<string>API_KEY_HERE</string>
```

### Create an assembly and upload
`Objective-C`
```objc
NSMutableArray<Step *> *steps = [[NSMutableArray alloc] init];

//MARK: A Sample step
Step *step1 = [[Step alloc] initWithKey:@"encode"];
[step1 setValue:@"/image/resize" forOption:@"robot"];

// Add the step to the array
[steps addObject:step1];

//MARK: Create an assembly with steps
Assembly *TestAssemblyWithSteps = [[Assembly alloc] initWithSteps:steps andNumberOfFiles:1];
[TestAssemblyWithSteps addFile:fileUrl];
[TestAssemblyWithSteps setNotify_url:@""];

//MARK: Start The Assembly
[transloadit createAssembly:TestAssemblyWithSteps];


transloadit.assemblyCreationResultBlock = ^(Assembly* assembly, NSDictionary* completionDictionary){
[transloadit invokeAssembly:assembly];
}
```
`Swift`
```swift
override func viewDidLoad() {
super.viewDidLoad()
let AssemblyStepsArray: NSMutableArray = NSMutableArray()
let Step1 = Step (key: "encode")
Step1?.setValue("/image/resize", forOption: "robot")
TestAssembly = Assembly(steps: AssemblyStepsArray, andNumberOfFiles: 1)

self.TestAssembly?.addFile(fileURL)
self.transloadit.createAssembly(self.TestAssembly!)

self.transloadit.assemblyCreationResultBlock = { assembly, completionDictionary in
print("Assembly created!")
print("Assembly invoking!")
self.transloadit.invokeAssembly(assembly)
}
}
```

## Example

Download the GitHub repo and open the example project
[`examples/`](https://github.com/transloadit/TransloaditKit/tree/master/Example).

## Contributing

We'd be happy to accept pull requests. If you plan on working on something big, please first drop us a line!

### Building

The SDK is written in Objective-C for both iOS and MacOS.


### Releasing

Releasing a new version to CocoaPods can be done via CocoaPods Trunk:

- Bump the version inside the `Transloadit.podspec`
- Save a release commit with the updated version in Git
- Push a tag to Github
- Publish to Cocoapods with Trunk

### To Do

-  bridge TUSKit networking
- websockets

## Dependencies

* [TUSKit](https://github.com/tus/tuskit) _note `TUSKit` is installed along side `Transloadit` via CocoaPods_

## Authors

* [Mark R. Masterson](https://twitter.com/markmasterson)

Contributions from:

* [Kevin van Zonneveld](https://twitter.com/kvz)

## License

[MIT Licensed](LICENSE).

