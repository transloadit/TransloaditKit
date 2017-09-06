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
pod 'TransloaditKit', git: 'https://github.com/transloadit/TransloaditKit'
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
import Arcane
import TransloaditKit
```

### Define your blocks
```objc
static TransloaditUploadProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t bytesTotal){
    // Update your progress bar here
    NSLog(@"progress: %llu / %llu", (unsigned long long)bytesWritten, (unsigned long long)bytesTotal);
};

static TransloaditUploadResultBlock resultBlock = ^(NSURL* fileURL){
    // Use the upload url
    NSLog(@"url: %@", fileURL);
};

static TransloaditUploadFailureBlock failureBlock = ^(NSError* error){
    // Handle the error
    NSLog(@"error: %@", error);
};
```

### Setup TransloaditKit
```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    transloadit = [[Transloadit alloc] initWithKey:@"YOUR_PUBLIC_KEY" andSecret:@"YOUR_SECRET_KIT"];
	// Do any additional setup after loading the view, typically from a nib.
}
```

### Create an assembly and upload
```objc
        NSMutableArray<AssemblyStep *> *steps = [[NSMutableArray alloc] init];
        
        //MARK: A Sample step
        AssemblyStep *step1 = [[AssemblyStep alloc] initWithKey:@"encode"];
        [step1 setValue:@"/image/resize" forOption:@"robot"];
        
        // Add the step to the array
        [steps addObject:step1];
        
        //MARK: Create an assembly with steps
        Assembly *TestAssemblyWithSteps = [[Assembly alloc] initWithSteps:steps andNumberOfFiles:1];
        [TestAssemblyWithSteps addFile:fileUrl];
        [TestAssemblyWithSteps setNotify_url:@""];
        
        //MARK: Start The Assembly
        [transloadit createAssembly:TestAssemblyWithSteps];
        
        
        transloadit.completionBlock = ^(NSDictionary* completionDictionary){
            
            [TestAssemblyWithSteps setUrlString:[completionDictionary valueForKey:@"assembly_ssl_url"]];
            [transloadit invokeAssembly:TestAssemblyWithSteps];
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

-  Check for wait is true on assembly status 

## Dependencies

* [TUSKit](https://github.com/tus/tuskit)

## Authors

* [Mark R. Masterson](https://twitter.com/markmasterson)

Contributions from:

* [Kevin van Zonneveld](https://twitter.com/kvz)

## License

[MIT Licensed](LICENSE).
