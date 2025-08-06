# Custom Build Walkthrough

This document describes the process of customizing this app to run a single property and submission to the Apple App Store.

## Requirements

Make sure you have the following requirements downloaded before attempting to build and submit to the app store.
A Physical Apple TV is recommended for development since simulators do not allow DRM playback as of TVOS version 18.0 and below.

- XCode 16.4+
- MacOS 15.4+
- Apple TV 18.0+
- Apple Developer Account https://developer.apple.com/programs/enroll/

## Fork and Build
1. Fork this github repo to your organization's github page
   - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo
2. Clone your new repository locally to start building
   - https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository
3. In Xcode, open EluvioWalletTVOS/EluvioWalletTVOS.xcodeproj/project.xcworkspace
4. In Xcode, go to project settings by clicking the top ELuvioWalletTVOS -> TARGETS / EluvioWalletTVOS and under "General", change:
   - Display Name, Bundle Identifier, Version, Build
5. Switch to the "Signing & Capabilities" and make sure "Automatically manage signing" is on and the correct Team and Bundle Identifier is set in the previous step.
6. Pair your apple tv to XCode or run your app in a Simulator
   - https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device
7. Once the Eluvio TVOS Media Wallet is able to build and run, you can start customizing for your own property.

## Customization
1. Find your property's ID (starts with "iq__") from either Creator Studio or from https://wallet.contentfabric.io/
2. Go to Configuration/configuration.json and add the property ID into the "allowed_properties" array:

```
    "allowed_properties" : [
      "iq_xxxxx"
    ]
```
3. You can change the App Icon and Top Shelf Images. Inside XCode, open ElvioWalletTVOS/Assets and drag and drop your custom Icon images into each slot. ie. Front / Middle/ Back.
   - https://developer.apple.com/documentation/xcode/configuring-your-app-icon
4. In Creator Studio, make sure the property has a start_screen_background and start_screen_logo set.
4. You can now run your app to see the single property mode with customizations.

## Archiving and Submission to Apple Connect
1. If all the previous steps work, you can now archive and submit your app to [Appstoreconnect](https://appstoreconnect.apple.com/)
   - In Xcode, go to top menu Product -> Archive which should start the build process.
2. Once the archive has been built, the Organizer window should appear. Select your archive and click "Distribute App".
3. Log into appstoreconnect -> Apps, you should see your App on the list.

## Apple Store Connect resources
Here are some resources to help test and submit your app for review on the TVOS App Store

- https://developer.apple.com/testflight/
- https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
- https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-for-review


