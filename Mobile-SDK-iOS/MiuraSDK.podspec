#
# Be sure to run `pod lib lint MiuraSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MiuraSDK'
  s.version          = '0.1.0'
  s.summary          = 'Library usd for communication with Miura products.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
The library is used to convert the protocol commands to a Miura device into meaningfull functions for the iOS platform.
                       DESC

s.homepage         = 'http://www.miurasystems.com'
  s.license          = { :type => 'Proprietary', :file => 'LICENSE' }
  s.author           = { 'Miura Systems' => 'info@miurasystems.com' }
  s.source           = { :git => '../MiuraSDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'MiuraSDK/**/*'
  
  # s.resource_bundles = {
  #   'MiuraSDK' => ['MiuraSDK/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
