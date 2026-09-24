Pod::Spec.new do |s|
  s.name             = 'RTMTokenBuilder'
  s.version          = '1.0.2'
  s.summary          = 'TokenBuilder'
  
  s.description      = <<-DESC
  TODO: Add long description of the pod here.
  DESC
  
  s.homepage         = 'https://github.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ZYP' => 'xxx@agora.io' }
  s.source           = { :git => 'https://github.com/zhuyuping/RTMTokenBuilder.git', :tag => '1.0.2' }
  
  s.ios.deployment_target = '11.0'
  s.source_files  = "RtmTokenTool/**/*.{h,m,mm,cpp}"
  s.public_header_files = "RtmTokenTool/TokenBuilder.h"
  s.platform = :ios
  s.swift_versions = "5.0"
  s.static_framework = true
  s.dependency "OpenSSL-Universal", "1.0.2.17"
  s.ios.library  = 'z', 'c++'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
