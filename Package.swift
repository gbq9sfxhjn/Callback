// swift-tools-version: 5.7

import PackageDescription

let exportedLibs = ["WorkingCopy"]

let package = Package(
    name: "Callback",
	platforms: [
		.iOS(.v16),
	],
    products: [
        .library(name: "Callback", targets: ["Callback"]),
	] + exportedLibs.map { .library(name: "\($0)Callback", targets: ["\($0)Callback"]) },
    dependencies: [
    ],
    targets: [
        .target(
            name: "Callback",
            dependencies: []),
        .testTarget(
            name: "CallbackTests",
            dependencies: ["Callback"]),
    ] + exportedLibs.map { .target(name: "\($0)Callback", dependencies: ["Callback"]) }
)
