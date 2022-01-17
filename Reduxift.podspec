#
# Be sure to run `pod lib lint Reduxift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Reduxift'
  s.version          = '0.5.0'
  s.summary          = 'Another ViewModel implementation in Swift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Reduxift is another view model inspired by Redux, MVVM, and ReactorKit. It exposes two output properties of state and event.
                       DESC

  s.homepage         = 'https://github.com/skyofdwarf/Reduxift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'skyofdwarf' => 'skyofdwarf@gmail.com' }
  s.source           = { :git => 'https://github.com/skyofdwarf/Reduxift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.swift_version = '5'

  s.source_files = 'Sources/Reduxift/**/*'
  
  # s.resource_bundles = {
  #   'Reduxift' => ['Reduxift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'RxSwift', '~> 6.5'
  s.dependency 'RxRelay', '~> 6.5'
  s.dependency 'RxCocoa', '~> 6.5'
end
