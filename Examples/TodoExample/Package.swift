// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TodoExample",
    platforms: [
        .iOS(.v13),
        .macOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(
            name: "TodoExample",
            targets: ["TodoExample"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(path: "../../"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "TodoExample",
            dependencies: ["UniFlow"]),
        // TodoExampleUITests (Tests/TodoExampleUITests) is a real Xcode UI Testing
        // Bundle, generated via `xcodegen generate` from project.yml -- SwiftPM can only
        // produce unit-test bundles, which can't host XCUIApplication, so it's
        // intentionally not listed as a target here. Run it via TodoExample.xcodeproj.
    ]
)