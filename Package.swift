// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "DiagSoup.Blueprints",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "DiagSoup.Blueprints", targets: ["DiagSoup_Blueprints"]),
        .executable(name: "DevTester_Blueprints", targets: ["DevTester_Blueprints"])
    ],
    dependencies: [
        //.package(url: "https://github.com/diagsoup/diagsoup", from: "0.1.0"),
        .package(path: "../diagsoup")
    ],
    targets: [
        .target(
            name: "DiagSoup_Blueprints",
            dependencies: [
                .product(name: "DiagSoup", package: "DiagSoup")
            ],
            path: "Sources",
            resources: [
                .copy("Resources/")
            ]
        ),
        .executableTarget(
            name: "DevTester_Blueprints",
            dependencies: [
                "DiagSoup_Blueprints",
                .product(name: "DiagSoup", package: "DiagSoup")
            ],
            path: "DevTester"
        ),
        //.testTarget(
        //    name: "DiagSoup_Blueprints_Tests",
        //    path: "Tests"
        //),
    ]
)
