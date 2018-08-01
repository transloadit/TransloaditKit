# TransloaditKit SDK [![Build Status](https://travis-ci.org/transloadit/TransloaditKit.svg?branch=master)](https://travis-ci.org/transloadit/TransloaditKit) [![Version](https://img.shields.io/cocoapods/v/Transloadit.svg?style=flat)](http://cocoapods.org/pods/Transloadit) [![License](https://img.shields.io/cocoapods/l/Transloadit.svg?style=flat)](http://cocoapods.org/pods/Transloadit) [![Platform](https://img.shields.io/cocoapods/p/Transloadit.svg?style=flat)](http://cocoapods.org/pods/Transloadit)

An **iOS** and **MacOS** integration for [Transloadit](https://transloadit.com)'s file
uploading and encoding service.

## Upgrade Notice:
`Transloadit` version `1.1.0` contains several breaking changes from the previous version, the main being the deprecation of blocks and introduction of the `TransloaditDelegate`. 
Please refer to the changelog for a full list. 

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


### Setup Transloadit 
To setup Transloadit, be sure add the delegate to your ViewController and then set the delegate to your ViewController.

`Objective-C`
```objc
@interface TransloaditViewController () <TransloaditDelegate>
@end
...
Transloadit *transloadit;
....
- (void)viewDidLoad {
[super viewDidLoad];
transloadit = [[Transloadit alloc] init];
[transloadit setDelegate:self];
...
}
```
`Swift`
```Swift
class TransloaditViewControllerSwifty: UIViewController, TransloaditDelegate {
...
let transloadit: Transloadit = Transloadit()
override func viewDidLoad() {
super.viewDidLoad()
self.transloadit.delegate = self;
...
}

}
```

### API Keys
You will also need to add your API key credentials to your `plist`.
An easy way to do this is:
1. Locate your `.plist` file, normally named *`{PROJECT_NAME}.plist`*
2. Right click and select `View As Source`
3. Copy and paste the snippet below into your `.plist`
4. Replace `SECRET_KEY_HERE` and `API_KEY_HERE` with their respective tokens


*{PROJECT_NAME}.plist*
```xml
<key>TRANSLOADIT_SECRET</key>
<string>SECRET_KEY_HERE</string>
<key>TRANSLOADIT_KEY</key>
<string>API_KEY_HERE</string>
```

### Templates and Assemblies
---
### Assembly
`Objective-C`
```objc
...
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
...
```
`Swift`
```swift
...
let AssemblyStepsArray: NSMutableArray = NSMutableArray()
let Step1 = Step (key: "encode")
Step1?.setValue("/image/resize", forOption: "robot")

TestAssembly = Assembly(steps: AssemblyStepsArray, andNumberOfFiles: 1)
self.TestAssembly?.addFile(fileURL)
...
```

### Assembly and Template CRUD 
---
For basic CRUD functions, an `Assembly` and `Template` are interchangeable when it comes to creating the requests. After the request is made they return to their own seperate delegate methods.
#### Create - Request
`Objective-C`
```objc
[transloadit create: TestAssembly];
[transloadit create: TestTemplate];
```
`Swift`
```swift
transloadit.create(TestAssembly)
transloadit.create(TestTemplate)
```

#### Create - Response
`Objective-C`
```objc
//Assembly Creation Success
- (void) transloaditAssemblyCreationResult:(Assembly *)assembly {
}

//Template Creation Success
- (void) transloaditTemplateCreationResult:(Template *)template {
}

//Assembly Creation Failure
- (void) transloaditAssemblyCreationError:(NSError *)error withResponse:(TransloaditResponse *)response {
}

//Template Creation Failure
- (void) transloaditTemplateCreationError:(NSError *)error withResponse:(TransloaditResponse *)response {
}
```
`Swift`
```swift
//Assembly Creation Success
override func transloaditAssemblyCreationResult(_ assembly: Assembly!) {
}

//Assembly Creation Failure
override func transloaditAssemblyCreationError(_ error: Error!, with response: TransloaditResponse!) {
}

//Templtate Creation Success
override func transloaditTemplateCreationResult(_ assembly: Assembly!) {
}

//Template Creation Failure
override func transloaditTemplateCreationError(_ error: Error!, with response: TransloaditResponse!) {
}

```

#### Read (Get)
`Objective-C`
```objc
[transloadit get: TestAssembly];
[transloadit get: TestTemplate];
```
`Swift`
```swift
transloadit.get(TestAssembly)
transloadit.get(TestTemplate)
```

#### Update
`Objective-C`
```objc
[transloadit update: TestAssembly];
[transloadit update: TestTemplate];
```
`Swift`
```swift
transloadit.update(TestAssembly)
transloadit.update(TestTemplate)
```

#### Delete
`Objective-C`
```objc
[transloadit delete: TestAssembly];
[transloadit delete: TestTemplate];
```
`Swift`
```swift
transloadit.delete(TestAssembly)
transloadit.delete(TestTemplate)
```

------

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
