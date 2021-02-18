# TransloaditKit

An **iOS & macOS** Integration for [Transloadit](https://transloadit.com)'s file uploading and encoding service

[Transloadit](https://transloadit.com) is a service that helps you handle file uploads, resize, crop and watermark your images, make GIFs, transcode your videos, extract thumbnails, generate audio waveforms, and so much more. In short, [Transloadit](https://transloadit.com) is the Swiss Army Knife for your files.

This is an **iOS and macOS** SDK to make it easy to talk to the [Transloadit](https://transloadit.com) REST API.

## Install

The library can be downloaded manualy from this repo, or installed with your favorite package managment software

**CocoaPods:**

```shell
pod 'transloadit'
```

**Carthage:**

**Swift Package Manager:**


### Install Troubleshooting

**CocoaPods**

If during install you recieve an error resembling
```
[!] CocoaPods could not find compatible versions for pod "TUSKit":
  In Podfile:
    Transloadit (from `../`) was resolved to 2.0.5.alpha, which depends on
      TUSKit (~> 2.1.5.alpha)

None of your spec sources contain a spec satisfying the dependency: `TUSKit (~> 2.1.5.alpha)`.

You have either:
 * out-of-date source repos which you can update with `pod repo update` or with `pod install --repo-update`.
 * mistyped the name or version.
 * not added the source repo that hosts the Podspec to your Podfile.
 ```
 Please follow instructuions and run `pod repo update`

## Setup

All interactions with the SDK begin with the `import Transloadit`
Before utilzing, you'll need to configure your TransloaditKit library with desired config.

### Implement

You can implement directly in your `AppDelegate`
```Swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        var config = TransloaditConfig(withKey: "", andSecret: "")
        Transloadit.setup(with: config)
        return true
    }
```

or add your keys to `Transloadit.plist` in your root directory and enter a default config

```Swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        var config = TransloaditConfig()
        Transloadit.setup(with: config)
        return true
    }
```

`Transloadit.plist`:

```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
    	<key>key</key>
    	    <string>PUT_KEY_HERE</string>
    	<key>secret</key>
    	    <string>PUT_SECRET_HERE</string>
    </dict>
</plist>
```

#### Other Configs

##### Logging

```Swift
config.logLevel = .All
```

##### URLSession

```
```

#### Delegate

Be sure to set the delgate in order to recieve proper callbacks from the library 

```Swift
Transloadit.shared.delegate = self
```

## Usage 

### Create an Assembly

To create an Assembly, you use the `newAssembly` method.

```Swift
// Create the assembly
let assembly: Assembly = Transloadit.shared.newAssembly()

//Create the steps
var resizeSteps: [String: Any] = [:]
                newSteps["robot"] = "/image/resize"
                newSteps["width"] = 75
            
//Add the steps
assembly.addStep(name: "resize", options: resizeSteps)

//Add the file
assembly.addFile(withPathURL: imageURL as! URL)

//Create and run the assembly
assembly.save()
```

## Example

Download the GitHub repo and open the [`Example/`](https://github.com/transloadit/TransloaditKit/tree/master/Example) folder.

## License

[The MIT License](LICENSE).
