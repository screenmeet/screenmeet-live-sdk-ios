#
#

Pod::Spec.new do |s|
  s.name             = 'ScreenMeetSDK'
  s.version          = '3.0.2'
  s.summary          = 'ScreenMeetSDK enables ScreenMeet\'s realtime platform in your app.'

  s.description      = <<-DESC
  ScreenMeet provides a platform that allows you to build realtime solutions for your application.
                       DESC

  s.homepage         = 'https://github.com/screenmeet/screenmeet-live-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ScreenMeet' => 'rstepanyak@screenmeet.com' }
  s.source           = { :git => 'https://github.com/screenmeet/screenmeet-live-sdk-ios.git', :tag => s.version.to_s }
  
  s.swift_version = '5.0'
  s.ios.deployment_target = '14.0'

  s.ios.vendored_frameworks = 'ScreenMeetLive.xcframework'
  
  s.dependency  'Socket.IO-Client-Swift', '~> 15.2.0'
  s.dependency  'UniversalWebRTC', '~> 106.0.7'

end
