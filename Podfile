def all_pods
  pod 'SSKeychain'
end

def ios_pods
  platform :ios, '6.0'
  pod 'ADNKit'
  pod 'ADNLogin'
  pod 'ALActionBlocks'
  pod 'ALToolkit', :git => 'https://github.com/lavoy/ALToolkit.git' 
  pod 'DACircularProgress'
  pod 'MWPhotoBrowser'
  pod 'NYXImagesKit'
  pod 'SDScreenshotCapture'
  pod 'SDWebImage'
  pod 'SVProgressHUD'
  pod 'SSKeychain'
end

def mac_pods
  platform :osx, '10.7'
  pod 'ADNKit'
  pod 'MASPreferences'
  pod 'MASShortcut'
end

target 'Orbit iOS' do
  all_pods
  ios_pods
end

target 'Orbit Mac' do
  all_pods
  mac_pods
end