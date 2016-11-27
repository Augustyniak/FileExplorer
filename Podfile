# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'FileExplorer' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for FileExplorer

end

target 'FileExplorerTests' do
  use_frameworks!
  pod 'FBSnapshotTestCase', '~>2.1.4'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
