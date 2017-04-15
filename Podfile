use_frameworks!

source 'https://github.com/CocoaPods/Specs'
source 'https://github.com/angryDuck2/CocoaSpecs'
source 'https://github.com/PopcornTimeTV/Specs'

def pods
    pod 'PopcornTorrent', '~> 1.1.9'
    pod 'XCDYouTubeKit', '~> 2.5.3'
    pod 'Alamofire', '~> 4.2.0'
    pod 'AlamofireImage', '~> 3.2.0'
    pod 'SwiftyTimer', '~> 2.0.0'
    pod 'FloatRatingView', '~> 2.0.1'
    pod 'Reachability', :git => 'https://github.com/tonymillion/Reachability'
    pod 'MarqueeLabel/Swift', '~> 3.0.0'
    pod 'ObjectMapper', '~> 2.2.5'
end

target 'PopcornTimeiOS' do
    platform :ios, '9.0'
    pods
    pod 'AlamofireNetworkActivityIndicator', '~> 2.1.0'
    pod 'google-cast-sdk', '~> 3.3.0'
    pod 'OBSlider', '~> 1.1.1'
    pod '1PasswordExtension', '~> 1.8.4'
    pod 'MobileVLCKit-unstable', '~> 3.0.0a24'
end

target 'PopcornTimetvOS' do
    platform :tvos, '9.0'
    pods
    pod 'TvOSMoreButton', :git => 'https://github.com/cgoldsby/TvOSMoreButton'
    pod 'TVVLCKit', '~> 2.1.0'
    pod 'MBCircularProgressBar', '~> 0.3.5-1'
end

target 'TopShelf' do
    platform :tvos, '9.0'
    pod 'ObjectMapper', '~> 2.2.5'
end

def kitPods
    pod 'Alamofire', '~> 4.2.0'
    pod 'ObjectMapper', '~> 2.2.5'
    pod 'AlamofireXMLRPC', '~> 2.1.0'
    pod 'SwiftyJSON', '~> 3.1.1'
    pod 'Locksmith', '~> 3.0.0'
end

target 'PopcornKit tvOS' do
    platform :tvos, '9.0'
    kitPods
end

target 'PopcornKit iOS' do
    platform :ios, '9.0'
    kitPods
    pod 'google-cast-sdk', '~> 3.3.0'
    pod 'SRT2VTT', '~> 1.0.1'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
