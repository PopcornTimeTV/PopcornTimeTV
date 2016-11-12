platform :tvos, '9.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs'
source 'https://github.com/angryDuck2/CocoaSpecs'
source 'https://github.com/PopcornTimeTV/Specs'

target 'PopcornTime' do
  pod 'PopcornTorrent', '~> 1.1.1.8'
  pod 'PopcornKit', '~> 3.1.0'
  pod 'TVVLCKit', '~> 2.0.7'
  pod 'XCDYouTubeKit', '~> 2.5.3'
  pod 'TVMLKitchen', :git => 'https://github.com/toshi0383/TVMLKitchen.git'
  pod 'AlamofireXMLRPC'
  pod 'AlamofireImage', '~> 3.0'
end

target 'TopShelf' do
    pod 'PopcornKit', '~> 3.1.0'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
