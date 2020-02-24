
xcodebuild:=xcodebuild -scheme "WifiCamMobileApp" -derivedDataPath ~/Desktop/App -sdk iphoneos10.3 -configuration


release:
	$(security unlock-keychaina)
	$(xcodebuild) Release
	xcrun -sdk iphoneos10.3 PackageApplication -v ~/Desktop/App/Build/Products/Release-iphoneos/WifiCamMobileApp.app -o ~/Desktop/WifiCamMobileApp.ipa

debug:
	$(security unlock-keychain)
	$(xcodebuild) Debug
	xcrun -sdk iphoneos10.3 PackageApplication -v ~/Desktop/App/Build/Products/Debug-iphoneos/WifiCamMobileApp.app -o ~/Desktop/WifiCamMobileApp.ipa

clean: clean-release clean-debug

clean-release:
	$(xcodebuild) Release clean

clean-debug:
	$(xcodebuild) Debug clean


