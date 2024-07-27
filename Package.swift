// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "DiagSoup.Templates",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "DiagSoup.Templates", targets: ["DiagSoup_Templates"]),
        .executable(name: "DevTester_Templates", targets: ["DevTester_Templates"])
    ],
    dependencies: [
        //.package(url: "https://github.com/diagsoup/diagsoup", from: "0.1.0"),
        .package(path: "../DiagSoup")
    ],
    targets: [
        .target(
            name: "DiagSoup_Templates",
            path: "Sources",
            resources: [
                .copy("Resources/")
            ]
        ),
        .executableTarget(
            name: "DevTester_Templates",
            dependencies: [
                "DiagSoup_Templates",
                .product(name: "DiagSoup", package: "DiagSoup")
            ],
            path: "DevTester"
        ),
        .testTarget(
            name: "DiagSoup_Templates_Tests",
            path: "Tests"
        ),
    ]
)
