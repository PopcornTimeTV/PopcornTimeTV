platform :tvos, '9.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs'
source 'https://github.com/angryDuck2/CocoaSpecs'

target 'PopcornTime' do
  pod 'PopcornTorrent', :git => 'https://github.com/PopcornTimeTV/PopcornTorrent.git'
  pod 'PopcornKit', :git => 'https://github.com/PopcornTimeTV/PopcornKit.git'
  pod 'XCDYouTubeKit', '~> 2.5.3'
  pod 'TVMLKitchen', :git => 'https://github.com/toshi0383/TVMLKitchen.git'
  pod 'AlamofireXMLRPC'
  pod 'TVVLCKit-unstable', '3.0.0a10'
  pod 'AlamofireImage', '~> 3.0'
end

target 'TopShelf' do
    pod 'PopcornKit', :git => 'https://github.com/PopcornTimeTV/PopcornKit.git'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
