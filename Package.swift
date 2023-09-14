// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScreenMeetSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "ScreenMeetLive", targets: ["ScreenMeetLiveWrapper"])
    ],
    dependencies: [
        .package(url: "https://github.com/socketio/socket.io-client-swift", .upToNextMinor(from: "15.2.0")),
        .package(url: "https://github.com/screenmeet/UniversalWebRTC", .upToNextMinor(from: "16.0.7"))
    ],
    targets: [
        .target(
            name: "ScreenMeetLiveWrapper",
            dependencies: [
                .target(name: "ScreenMeetLive"),
                .product(name: "WebRTC", package: "UniversalWebRTC"),
                .product(name: "SocketIO", package: "socket.io-client-swift")
            ],
            path: "ScreenMeetLiveWrapper"
        ),
        .binaryTarget(name: "ScreenMeetLive", path: "ScreenMeetLive.xcframework")
    ]
)
