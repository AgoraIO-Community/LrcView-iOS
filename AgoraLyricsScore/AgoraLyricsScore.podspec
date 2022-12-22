Pod::Spec.new do |spec|
  spec.name         = "AgoraLyricsScore"
  spec.version      = "1.1.0"
  spec.summary      = "AgoraLyricsScore"
  spec.description  = "AgoraLyricsScore"

  spec.homepage     = "https://github.com/AgoraIO-Community"
  spec.license      = "MIT"
  spec.author       = { "ZYQ" => "zhaoyongqiang@agora.io" }
  spec.source       = { :git => "https://github.com/AgoraIO-Community/LrcView-iOS.git", :tag => '1.1.0' }
  spec.source_files  = "Class/**/*.swift"
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'DEFINES_MODULE' => 'YES' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'DEFINES_MODULE' => 'YES' }
  spec.ios.deployment_target = '10.0'
  spec.swift_versions = "5.0"
  spec.requires_arc  = true
  #spec.static_framework = true
  
  spec.test_spec 'Tests' do |test_spec|
    test_spec.source_files = "Tests/**/*.{swift}"
    test_spec.resource = "Tests/Resource/**/*"
    test_spec.frameworks = 'UIKit','Foundation'
  end
end
