use_frameworks!

source 'https://github.com/CocoaPods/Specs'
source 'https://github.com/PopcornTimeTV/Specs'

def pods
    pod 'PopcornTorrent', '~> 1.3.15'
    pod 'XCDYouTubeKit', '~> 2.12.0'
    pod 'Alamofire', '~> 4.9.1'
    pod 'AlamofireImage', '~> 3.6.0'
    pod 'SwiftyTimer', '~> 2.1.0'
    pod 'GCDWebServer', '~>3.5.4' 
    pod 'Reachability', :git => 'https://github.com/tonymillion/Reachability'
    pod 'MarqueeLabel/Swift', '~> 3.2.0'
    pod 'ObjectMapper', '~> 3.5.2'
    pod 'FloatRatingView', '~> 3.0.1'
end

target 'PopcornTimeiOS' do
    platform :ios, '13.0'
    pods
    pod 'AlamofireNetworkActivityIndicator', '~> 2.4.0'
    pod 'google-cast-sdk-no-bluetooth', '~> 4.4.7'
    pod 'OBSlider', '~> 1.1.1'
    pod '1PasswordExtension', '~> 1.8.6'
    pod 'MobileVLCKit', '~> 3.3.10'
    pod "Player", "~> 0.13.2"
end

target 'PopcornTimetvOS' do
    platform :tvos, '13.0'
    pods
    pod 'TvOSMoreButton', '~> 1.2.0'
    pod 'TVVLCKit', '~> 3.3.10'
    pod 'MBCircularProgressBar', '~> 0.3.5-1'
end

target 'TopShelf' do
    platform :tvos, '13.0'
    pod 'ObjectMapper', '~> 3.5.2'
end

def kitPods
    pod 'Alamofire', '~> 4.9.1'
    pod 'ObjectMapper', '~> 3.5.2'
    pod 'SwiftyJSON', '~> 4.2.0'
    pod 'Locksmith', '~> 4.0.0'
end

target 'PopcornKit tvOS' do
    platform :tvos, '13.0'
    kitPods
end

target 'PopcornKit iOS' do
    platform :ios, '13.0'
    kitPods
    pod 'google-cast-sdk-no-bluetooth', '~> 4.4.7'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
            config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
            config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
        end
        if ['FloatRatingView-iOS', 'FloatRatingView-tvOS'].include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end
    end
end
