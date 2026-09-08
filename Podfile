platform :ios, '14.2'

target 'parkingHere' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for parkingHere
  pod 'Alamofire', '~> 5.2'
  pod 'IQKeyboardManagerSwift', '6.3.0'  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.2'
    end
  end
end
