#!/usr/bin/env ruby

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'pathname'
require 'xcodeproj'

root = Pathname.new(File.expand_path('..', __dir__))
project_path = root.join('Demo/Demo.xcodeproj')
project = Xcodeproj::Project.open(project_path.to_s)
app = project.targets.find { |target| target.name == 'Demo' }
abort('Demo target not found') unless app

tests = project.targets.find { |target| target.name == 'DemoTests' }
tests ||= project.new_target(:unit_test_bundle, 'DemoTests', :ios, '13.0')
tests.add_dependency(app) unless tests.dependencies.any? { |dependency| dependency.target == app }

demo_group = project.main_group.groups.find { |group| group.display_name == 'Demo' }
abort('Demo group not found') unless demo_group
app_group = demo_group.groups.find { |group| group.display_name == 'App' }
app_group ||= demo_group.new_group('App', 'App')
tests_group = project.main_group.groups.find { |group| group.display_name == 'DemoTests' }
tests_group ||= project.main_group.new_group('DemoTests', 'DemoTests')

def ensure_reference(group, path)
  group.files.find { |reference| reference.path == path } || group.new_file(path)
end

app_references = [
  ensure_reference(demo_group, 'AppDelegate.swift'),
  ensure_reference(demo_group, 'SceneDelegate.swift')
]
app_root = root.join('Demo/Demo/App')
Dir.glob(app_root.join('**/*.{swift,m,mm,c,cpp}').to_s).sort.each do |path|
  relative = Pathname.new(path).relative_path_from(app_root).to_s
  app_references << ensure_reference(app_group, relative)
end

test_root = root.join('Demo/DemoTests')
test_references = Dir.glob(test_root.join('**/*.swift').to_s).sort.map do |path|
  relative = Pathname.new(path).relative_path_from(test_root).to_s
  ensure_reference(tests_group, relative)
end

app.source_build_phase.files.to_a.each(&:remove_from_project)
tests.source_build_phase.files.to_a.each(&:remove_from_project)
app.add_file_references(app_references)
tests.add_file_references(test_references)

allowed_resources = ['Assets.xcassets', 'LaunchScreen.storyboard']
app.resources_build_phase.files.to_a.each do |build_file|
  build_file.remove_from_project unless allowed_resources.include?(build_file.file_ref.display_name)
end

app.build_configurations.each do |config|
  settings = config.build_settings
  settings.delete('DEVELOPMENT_TEAM')
  settings.delete('INFOPLIST_KEY_UIMainStoryboardFile')
  settings.delete('INFOPLIST_KEY_NSCameraUsageDescription')
  settings.delete('SWIFT_OBJC_BRIDGING_HEADER')
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'io.agora.KLyricsDemo'
  settings['INFOPLIST_KEY_NSMicrophoneUsageDescription'] = '需要使用麦克风检测演唱音高并计算得分。'
  settings['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone'] = 'UIInterfaceOrientationPortrait'
end

tests.build_configurations.each do |config|
  settings = config.build_settings
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'io.agora.KLyricsDemoTests'
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['PRODUCT_MODULE_NAME'] = '$(PRODUCT_NAME:c99extidentifier)'
  settings['SWIFT_VERSION'] = '5.0'
  settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/Demo.app/Demo'
  settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
end

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(tests)
scheme.set_launch_target(app)
scheme.save_as(project_path.to_s, 'Demo', true)
project.save
