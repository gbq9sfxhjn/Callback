// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Callback",
	platforms: [
		.iOS(.v16),
	],
    products: [
        .library(
            name: "Callback",
            targets: ["Callback"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Callback",
            dependencies: []),
        .testTarget(
            name: "CallbackTests",
            dependencies: ["Callback"]),
    ]
)
