// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "EluvioCore",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v17),
    .tvOS(.v17),
  ],
  products: [
    .library(name: "EluvioCore", targets: ["EluvioCore"]),
  ],
  dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.11.0"),
    .package(url: "https://github.com/keefertaylor/Base58Swift.git", from: "2.1.14"),
    .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.2"),
    .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.20.1"),
    .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "2.2.7"),
    .package(url: "https://github.com/SDWebImage/SDWebImageSVGCoder.git", from: "1.8.0"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.11.0"),
    .package(url: "https://github.com/swift-libp2p/swift-varint.git", from: "0.2.0"),
  ],
  targets: [
    .target(
      name: "EluvioCore",
      dependencies: [
        "Alamofire",
        "Base58Swift",
        "SwiftyJSON",
        "SDWebImage",
        .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
        .product(name: "SDWebImageSVGCoder", package: "SDWebImageSVGCoder"),
        .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
        .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
        .product(name: "VarInt", package: "swift-varint"),
      ]
    ),
  ]
)
