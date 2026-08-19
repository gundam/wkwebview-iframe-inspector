#!/usr/bin/env ruby

require "xcodeproj"

root = File.expand_path("..", __dir__)
project_path = File.join(root, "iOSApp.xcodeproj")
project = Xcodeproj::Project.new(project_path)

project.root_object.attributes["LastSwiftUpdateCheck"] = "1620"
project.root_object.attributes["LastUpgradeCheck"] = "1620"

app_group = project.main_group.new_group("iOSApp", "iOSApp")
test_group = project.main_group.new_group("iOSAppTests", "iOSAppTests")

app_files = Dir[File.join(root, "iOSApp", "*.swift")].sort.map do |path|
  app_group.new_file(File.basename(path))
end
asset_catalog = app_group.new_file("Assets.xcassets")
test_file = test_group.new_file("iOSAppTests.swift")

app_target = project.new_target(:application, "iOSApp", :ios, "17.0")
app_target.add_file_references(app_files)
app_target.resources_build_phase.add_file_reference(asset_catalog)

app_target.build_configurations.each do |config|
  settings = config.build_settings
  settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  settings["ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"] = "AccentColor"
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["CURRENT_PROJECT_VERSION"] = "1"
  settings["ENABLE_PREVIEWS"] = "YES"
  settings["GENERATE_INFOPLIST_FILE"] = "YES"
  settings["INFOPLIST_KEY_UIApplicationSceneManifest_Generation"] = "YES"
  settings["INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents"] = "YES"
  settings["INFOPLIST_KEY_UILaunchScreen_Generation"] = "YES"
  settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
  settings["MARKETING_VERSION"] = "1.0"
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.example.iOSApp"
  settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  settings["SWIFT_EMIT_LOC_STRINGS"] = "YES"
  settings["SWIFT_VERSION"] = "5.0"
  settings["TARGETED_DEVICE_FAMILY"] = "1,2"
end

test_target = project.new_target(:unit_test_bundle, "iOSAppTests", :ios, "17.0")
test_target.add_file_references([test_file])
test_target.add_dependency(app_target)

test_target.build_configurations.each do |config|
  settings = config.build_settings
  settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["GENERATE_INFOPLIST_FILE"] = "YES"
  settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.example.iOSAppTests"
  settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  settings["SWIFT_VERSION"] = "5.0"
  settings["TARGETED_DEVICE_FAMILY"] = "1,2"
  settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/iOSApp.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/iOSApp"
end

project.save

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)
scheme.set_launch_target(app_target)
scheme.add_test_target(test_target)
scheme.save_as(project_path, "iOSApp", true)

puts "Generated #{project_path}"
