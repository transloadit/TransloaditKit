#
# Be sure to run `pod lib lint Transloadit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Transloadit'
  s.version          = '3.4.0'
  s.summary          = 'Transloadit client in Swift'
  s.swift_version = '5.0'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Swift client for http://transloadit.com called TransloaditKit. Mac and iOS compatible.
                       DESC

  s.homepage         = 'https://github.com/transloadit/TransloaditKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'Transloadit'
  s.source           = { :git => 'https://github.com/transloadit/TransloaditKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target  = '10.11'

  s.source_files = 'Sources/TransloaditKit/**/*'

  s.dependency 'TUSKit', '~> 3.6.0'

end
