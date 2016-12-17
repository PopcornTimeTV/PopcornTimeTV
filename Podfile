use_frameworks!

source 'https://github.com/CocoaPods/Specs'
source 'https://github.com/angryDuck2/CocoaSpecs'
source 'https://github.com/PopcornTimeTV/Specs'

def pods
    pod 'PopcornTorrent', '~> 1.1.2'
    pod 'PopcornKit', '~> 3.1.6'
    pod 'XCDYouTubeKit', '~> 2.5.3'
    pod 'Alamofire', '~> 4.0'
    pod 'AlamofireImage', '~> 3.0'
    pod 'SwiftyTimer', '~> 2.0.0'
end

target 'PopcornTimeiOS' do
    platform :ios, '9.0'
    pods
    pod 'AlamofireNetworkActivityIndicator', '~> 2.0'
    pod 'Reachability', '~> 3.2'
    pod 'JGProgressHUD', '~> 1.4'
    pod 'google-cast-sdk', '~> 3.2'
    pod 'OBSlider', '~> 1.1.1'
    pod 'ColorArt', '~> 0.1.1'
    pod '1PasswordExtension', '~> 1.8.4'
    pod 'MobileVLCKit-unstable', '~> 3.0.0a24'
    pod 'FloatRatingView', '~> 2.0'
end

target 'PopcornTimetvOS' do
    platform :tvos, '9.0'
    pods
    pod 'TVVLCKit-unstable', '~> 3.0.0a24'
    pod 'TVMLKitchen', :git => 'https://github.com/toshi0383/TVMLKitchen.git'
    pod 'MBCircularProgressBar', '~> 0.3.5-1'
end

target 'TopShelf' do
    pod 'PopcornKit', '~> 3.1.6'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
