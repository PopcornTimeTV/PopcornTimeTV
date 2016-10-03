source 'https://github.com/CocoaPods/Specs'
source 'https://github.com/angryDuck2/CocoaSpecs'

platform :tvos
use_frameworks!

target 'PopcornTime' do
  pod 'YoutubeSourceParserKit', :git => 'https://github.com/lennet/YoutubeSourceParserKit.git'
  pod 'TVMLKitchen', :git => 'https://github.com/toshi0383/TVMLKitchen.git', :branch => 'swift3.0'
  pod 'PopcornKit', :git => 'https://github.com/PopcornTimeTV/PopcornKit.git', :branch => 'new-apis'
  pod 'AlamofireXMLRPC'
  pod 'PopcornTorrent', :git => 'https://github.com/PopcornTimeTV/PopcornTorrent.git'
  pod 'TVVLCKit-unstable', '3.0.0a22'
  pod 'GCDWebServer', :git => 'https://github.com/swisspol/GCDWebServer.git'
  pod 'ObjectMapper', :git => 'https://github.com/Hearst-DD/ObjectMapper.git'
  
end

target 'TopShelf' do
    pod 'PopcornKit', :git => 'https://github.com/PopcornTimeTV/PopcornKit.git', :branch => 'new-apis'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
