# TransloaditKit Changelog

## 3.4

* Updated Package to depend on exact TUSKit version and removed call to removed method in TUSKit ([#41](https://github.com/transloadit/TransloaditKit/issues/41))

## 3.3.4

* Changed polling interval to 0.75s for checking assembly status

## 3.3.3

* Added data race protections, allowing for concurrent starting of assemblies

## 3.3.2
* Increased test coverage and utilities for testing in example app

## 3.3.1
* Background configuration was not set up fully correctly; this is now fixed
* TUSKit will always use a background configuration when uploading files
* Added a new initializer to TransloadIt that allows users to provide a URLSessionConfiguration instead of a URLSession

## 3.3.0

### Fixes
* Allow usage of URLSessions with background configuration to enable background uploads

## 3.2.0

### Fixes

### Added
* It's now possible to cancel a running Assembly 
* Bumped TUSKit version
* Allow passing of custom fields to assembly creating by passing them to `createAssembly` methods

## 3.1.0

### Fixes
* Headers were set incorrectly when creating an assembly + uploading files immediately

### Added
* Allow running an assembly by templateID through both `Transloadit.createAssembly(templateId:...` methods
