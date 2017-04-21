# Transloadit

[![Build Status](https://travis-ci.org/transloadit/TransloaditKit.svg?branch=master)](https://travis-ci.org/transloadit/TransloaditKit)
[![Version](https://img.shields.io/cocoapods/v/Transloadit.svg?style=flat)](http://cocoapods.org/pods/Transloadit)
[![License](https://img.shields.io/cocoapods/l/Transloadit.svg?style=flat)](http://cocoapods.org/pods/Transloadit)
[![Platform](https://img.shields.io/cocoapods/p/Transloadit.svg?style=flat)](http://cocoapods.org/pods/Transloadit)

## Status

Pre-alpha and under heavy development, do not use!

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Transloadit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Transloadit"
```

## Author

Mark R. Masterson, mrobertmasterson@gmail.com

### Work Flow

* Create An AssemblyStep Object With JSONString or Values
* Create An Assembly With JSON Assembly Steps or an Array of AssemblyStep Objects
* Generate the Params as JSON for an Assembly Object 
* Create The Assembly Get A TransloaditResponse Object

* Pass TransloaditResoinse Object To TUSWrapper to perfom Upload





## License

Transloadit is available under the MIT license. See the LICENSE file for more info.
