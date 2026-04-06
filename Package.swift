// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ModelHike.Blueprints",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "ModelHike.Blueprints", targets: ["ModelHike_Blueprints"]),
        .executable(name: "DevTester_Blueprints", targets: ["DevTester_Blueprints"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelhike/modelhike", from: "0.2.1"),
        //.package(path: "../modelhike")
    ],
    targets: [
        .target(
            name: "ModelHike_Blueprints",
            dependencies: [
                .product(name: "ModelHike", package: "ModelHike")
            ],
            path: "Sources",
            resources: [
                .copy("Resources/")
            ]
        ),
        .executableTarget(
            name: "DevTester_Blueprints",
            dependencies: [
                "ModelHike_Blueprints",
                .product(name: "ModelHike", package: "ModelHike"),
            ],
            path: "DevTester"
        ),
        //.testTarget(
        //    name: "ModelHike_Blueprints_Tests",
        //    path: "Tests"
        //),
    ]
)
