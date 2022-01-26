#
#

Pod::Spec.new do |s|
  s.name             = 'ScreenMeetSDK'
  s.version          = '2.0.9'
  s.summary          = 'ScreenMeetSDK enables ScreenMeet\'s realtime platform in your app.'

  s.description      = <<-DESC
  ScreenMeet provides a platform that allows you to build realtime solutions for your application.
                       DESC

  s.homepage         = 'https://github.com/screenmeet/screenmeet-live-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ScreenMeet' => 'sdksupport@screenmeet.com' }
  s.source           = { :git => 'https://github.com/screenmeet/screenmeet-live-sdk-ios.git', :tag => s.version.to_s }
  
  s.swift_version = '5.0'
  s.ios.deployment_target = '12.0'

  s.source_files = 'ScreenMeetSDK/Classes/**/*'
  
  s.dependency  'Socket.IO-Client-Swift', '~> 15.2.0'
  s.dependency  'GoogleWebRTC' #, '~> 1.1'

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'ENABLE_BITCODE' => 'NO'
  }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
