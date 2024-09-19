// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Engage",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Engage",
            targets: ["Engage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", "8.7.0"..<"12.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Engage",
            dependencies: [
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "engage-iosTests",
            dependencies: ["Engage"]
        ),
    ]
)
