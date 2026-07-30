// swift-tools-version: 6.2
//  Package.swift
//
//  The Swift Package Manager manifest for UniFlow.`

import PackageDescription

let package = Package(
    name: "UniFlow",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "UniFlow",
            targets: ["UniFlow"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "UniFlow",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "UniFlowTests",
            dependencies: ["UniFlow"],
            path: "Tests"
        )
    ]
)