Pod::Spec.new do |spec|
  spec.name         = "AgoraLyricsScore"
  spec.version      = "2.1.0-alpha-3"
  spec.summary      = "AgoraLyricsScore"
  spec.description  = "AgoraLyricsScore"

  spec.homepage     = "https://github.com/AgoraIO-Community"
  spec.license      = "MIT"
  spec.author       = { "ZYQ" => "zhaoyongqiang@agora.io" }
  spec.source       = { :git => "https://github.com/AgoraIO-Community/LrcView-iOS.git", :tag => '2.1.0-alpha-2' }
  spec.source_files  = ["AgoraLyricsScore/Class/**/*.swift", "AgoraLyricsScore/Class/AL/*"]
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'DEFINES_MODULE' => 'YES' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'DEFINES_MODULE' => 'YES' }
  spec.ios.deployment_target = '10.0'
  spec.swift_versions = "5.0"
  spec.requires_arc  = true
  spec.dependency 'AgoraComponetLog'
  spec.dependency 'Zip', '2.1.2'
  spec.resource_bundles = {
    'AgoraLyricsScoreBundle' => ['AgoraLyricsScore/Resources/*.xcassets']
  }
  
spec.test_spec 'Tests' do |test_spec|
    test_spec.source_files = "AgoraLyricsScore/Tests/**/*.{swift}"
    test_spec.resource = "AgoraLyricsScore/Tests/Resource/*"
    test_spec.frameworks = 'UIKit','Foundation'
#    test_spec.requires_app_host = true
end
end
