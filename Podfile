platform :ios, '12.0'
use_frameworks!

target 'OnePay' do
    pod 'SkyFloatingLabelTextField', '~> 3.0'
    pod 'IQKeyboardManagerSwift'
    pod 'SideMenuSwift'
    pod 'SwiftyJSON', '~> 4.0'
    pod 'Stripe'
    pod 'ReachabilitySwift'
    pod "ApplicationInsights", '1.0-beta.8'
    pod 'AppCenter'
end 

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
            config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
        end
    end
end

