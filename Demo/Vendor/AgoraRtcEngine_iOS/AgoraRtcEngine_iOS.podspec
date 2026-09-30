Pod::Spec.new do |s|
  s.name = 'AgoraRtcEngine_iOS'
  s.version = '4.5.0'
  s.summary = 'Vendored Agora iOS SDK for the lyrics demo'
  s.homepage = 'https://www.agora.io/'
  s.license = { :type => 'Copyright', :text => 'Copyright Agora, Inc.' }
  s.author = { 'Agora' => 'developer@agora.io' }
  s.source = { :git => 'https://github.com/AgoraIO/AgoraRTC-SDK-for-iOS.git' }
  s.platform = :ios, '11.0'

  s.vendored_frameworks = %w[
    libs/AgoraRtcKit.xcframework
    libs/Agorafdkaac.xcframework
    libs/Agoraffmpeg.xcframework
    libs/AgoraSoundTouch.xcframework
    libs/aosl.xcframework
    libs/video_dec.xcframework
  ]
end
