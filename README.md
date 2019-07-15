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
# Setup
---
## Install

### CocoaPods
Inside your podfile add,

```bash
pod 'Transloadit'
```

### Carthage

Insdie your Cartfile add,

```bash
github "transloadit/TransloaditKit"
```

### Manual
1. Download and unpack the ZIP file
2. Drag the Transloadit directory into your project

## API Keys
Befiore you begin using `TransloaditKit`, you will need to add your API keys to your project's `.plist`. 

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

---
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

### Initializing TransloaditKit
*Objective-C*
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
*Swift*
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
## API Objects
There are two main objects that interact with `TransloaditKit`, they are `Assembly` and `Template`, herein known as `APIObject`s. Most Transloadit methods require an `APIObject` as a parameter. 

**Steps**
Typically, if you aren't referencing an already created `Assembly` or `Template` with steps, you will need to create one locally before calling Trandloadit. To create your steps, create a few `Step` objects and an array to hold them.
*Objective-C*
```objc
NSMutableArray<Step *> *steps = [[NSMutableArray alloc] init];

Step *step1 = [[Step alloc] initWithKey:@"encode"];
[step1 setValue:@"/image/resize" forOption:@"robot"];
[steps addObject:step1];
```
*Swift*
```swift
var steps: Array<Step> = Array()

let step1: Step = Step()
step1.setValue("/image/resize", forOption: "robot")
steps.append(step1)
```

After creating your steps, you will be able to create a local `APIObject` object.
**Assembly**
*Objective-C*
```objc
Assembly *assebmly = [[Assembly alloc] initWithSteps:steps andNumberOfFiles:1];

[assebmly addFile:fileURL andFileName:@"test.jpg"];
```
*Swift*
```swift
let assembly: Assembly = Assembly(steps: steps, andNumberOfFiles: 1)

assembly.addFile(fileURL, andFileName: "test.jpg")
```
**Template**
*objective-c*
```objc
Template *template = [[Template alloc] initWithSteps:steps andName:@"Test Template"];
```

*swift*
```swift
 var template: Template = Template(steps: steps, andName: "Template Name")
```

However if you do have an already created `APIObject`, simply create a simple `APIObject` by initalizing with the respective id
**Assembly**
*objective-c*
```objc
Assembly *assembly = [[Assembly alloc] initWithId:@"ID_HERE"];
```
*swfit*
```swift
var assembly: Assembly = Assembly(id: "ID_HERE")
```
**Template**
*objective-c*
```objc
Template *template = [[Template alloc] initWithId:@"ID_HERE"];
```
*swfit*
```swift
var template: Template = Template(id: "ID_HERE")
```


## Functions
`TransloaditKit` uses a very simple API for the core CRUD functions. Examples of each CRUD function are defined below:
### Create
##### Assembly
After creating your `Assembly` object wuith steps, you are ready to call `Transloadit` and create your assembly
*objective-c*
```objc
[transloadit create:assembly];
```
*swfit*
```swift
transloadit.create(assembly)
```

A succesfull Assembly creation will fire the deleagte method: 
*objective-c*
```objc
transloaditAssemblyCreationResult:(Assembly *)assembly
```
*swift*
```swift
transloaditAssemblyCreationResult(_ assembly: Assembly!)
```

A failed Assembly creation will fire the deleagte method: 
*objective-c*
```objc
transloaditAssemblyCreationError:(NSError *)error withResponse:(TransloaditResponse *)response
```
*swift*
```swift
transloaditAssemblyCreationError(_ error: Error!, with response: TransloaditResponse!)
```

----
#### Template
After creating your `Template` object, you are ready to call `Transloadit` and create your template
*objective-c*
```objc
[transloadit create:template];
```
*swfit*
```swift
transloadit.create(template)
```

A succesfull `Template` creation will fire the deleagte method: 
*objective-c*
```objc
transloaditTemplateCreationResult:(Template *)template
```
*swift*
```swift
transloaditTemplateCreationResult(_ template: Template!)
```

A failed `Template` creation will fire the deleagte method: 
*objective-c*
```objc
transloaditTemplateCreationError:(NSError *)error withResponse:(TransloaditResponse *)response
```
*swift*
```swift
transloaditTemplateCreationError(_ error: Error!, with response: TransloaditResponse!)
```
------
### Get (Read)
To get a full `Assembly` or `Template` object, your local `APIObject` must at-least contain the `id`. After you are sure it holds the `APIObject`'s `id` you are ready to call `Transloadit`
#### Assembly
*objective-c*
```objc
[transloadit get:assembly];
```
*swfit*
```swift
transloadit.get(assembly)
```
A succesful get will result in 
*objectice-c*
```objc
- (void)transloaditAssemblyGetResult:(Assembly *)assembly
```
*swfit*
```Swift
func transloaditAssemblyGetResult(_ assembly: Assembly!)
```
A failed get will result in 
*objective-c*
```objc
- (void)transloaditAssemblyGetError:(NSError *)error withResponse:(TransloaditResponse *)response
```
*swfit*
```Swift
func transloaditAssemblyGetError(_ error: Error!, with response: TransloaditResponse!)
```
#### Template
*objective-c*
```objc
[transloadit get:template];
```
*swfit*
```swift
transloadit.get(template)
```
A succesful get will result in 
*objectice-c*
```objc
- (void)transloaditTemplateGetResult:(Template *)assembly
```
*swfit*
```Swift
func transloaditTemplateetResult(_ template: Template!)
```
A failed get will result in 
*objective-c*
```objc
- (void)transloaditTemplateGetError:(NSError *)error withResponse:(TransloaditResponse *)response
```
*swfit*
```Swift
func transloaditTemplateError(_ error: Error!, with response: TransloaditResponse!)
```

### Delete
#### Assembly
Sending a delete to an assembly will cancel the assembly from processsing
*objective-c*
```objc
[transloadit delete:assembly];
```
*swfit*
```swift
transloadit.delete(assembly)
```
A succesful delete will result in
*objective-c*
```obc
- (void)transloaditAssemblyDeletionResult:(TransloaditResponse *)assembly
```
*swift*
```swift
func transloaditAssemblyDeletionResult(_ assembly: TransloaditResponse!)
```
A failed delete will result in
*objective-c*
```objc
(void)transloaditAssemblyDeletionError:(NSError *)error withResponse:(TransloaditResponse *)response
```
*Swift*
```Swift
func transloaditAssemblyDeletionError(_ error: Error!, with response: TransloaditResponse!)
```
#### Template
*objective-c*
```objc
[transloadit delete:template];
```
*swfit*
```swift
transloadit.delete(template)
```
A succesful delete will result in
*objective-c*
```obc
- (void)transloaditTemplateDeletionResult:(TransloaditResponse *)template
```
*swift*
```swift
func transloaditTemplateDeletionResult(_ template: TransloaditResponse!)
```
A failed delete will result in
*objective-c*
```objc
(void)transloaditTemplateDeletionError:(NSError *)error withResponse:(TransloaditResponse *)response
```
*Swift*
```Swift
func transloaditTemplateDeletionError(_ error: Error!, with response: TransloaditResponse!)
```
----
## Invoking
Once an `Assembly` is created, you are able to start the processing of said `Assembly` and files, otherwise known as "invoking". The invoking process takes two parameters, the `Assembly` you are trying to invoke and tne number of retries you'd like the operation to perform incase of a failure.

*objective-c*
```
[transloadit invokeAssembly:assembly retry:3];
```

*swift*
```
transloadit .invokeAssembly(assembly, retry: 3)

```

Typically done in the `transloaditAssemblyCreationResult` delegate method, you can start the invoking process as shown below

*objectice-c*
```objective-c
- (void) transloaditAssemblyCreationResult:(Assembly *)assembly {
    [assembly setUrlString:[assembly urlString]];
    [transloadit invokeAssembly:assembly retry:3];
}
```
*swift*
```swift
func transloaditAssemblyCreationResult(_ assembly: Assembly!) {
assembly.urlString = assembly.urlString
transloadit .invokeAssembly(assembly, retry: 3)
}
```

Invoking the assembly results in the firing of a few delegate methods


**The progress of the upload**
*objective-c*
```
- (void)tranloaditUploadProgress:(int64_t *)written bytesTotal:(int64_t *)total
```
*swift*
```Swift
func tranloaditUploadProgress(_ written: <Int64>!, bytesTotal total: <Int64>!) 
```

**The failure of the upload**
*objective-c*
```
- (void)transloaditUploadFailureBlock:(NSError *)error
```
*swift*
```Swift
func transloaditUploadFailureBlock(_ error: Error!)
```

**The progress of the assembly**
*objective-c*
```
- (void)transloaditAssemblyProcessProgress:(TransloaditResponse *)response
```
*swift*
```Swift
func transloaditAssemblyProcessProgress(_ response: TransloaditResponse!)
```

**The result of the assembly**
*objective-c*
```
- (void)transloaditAssemblyProcessResult:(TransloaditResponse *)response
```
*swift*
```Swift
func transloaditAssemblyProcessResult(_ response: TransloaditResponse!)
```

**The failure of the assembly**
*objective-c*
```
- (void)transloaditAssemblyProcessError:(NSError *)error withResponse:(TransloaditResponse *)response
```
*swift*
```Swift
func transloaditAssemblyProcessError(_ error: Error!, with response: TransloaditResponse!)
```

## Example

Download the GitHub repo and open the example project
[`examples/`](https://github.com/transloadit/TransloaditKit/tree/master/Example).

## Contributing

We'd be happy to accept pull requests. If you plan on working on something big, please first drop us a line!

### Building

The SDK is written in Objective-C for both iOS and MacOS. 

### To Do

- websockets

## Dependencies

* [TUSKit](https://github.com/tus/tuskit) _note `TUSKit` is installed along side `Transloadit` via CocoaPods and included in the Carthage framework_

## Authors

* [Mark R. Masterson](https://twitter.com/markmasterson)

Contributions from:

* [Kevin van Zonneveld](https://twitter.com/kvz)

## License

[MIT Licensed](LICENSE).
