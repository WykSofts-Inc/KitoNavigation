// swift-tools-version: 5.9
//
//  Package.swift
//  KitoNavigation
//
//  Created by Wycliff on 8/4/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//


import PackageDescription

let package = Package(
    name: "KitoNavigation",
    platforms: [.iOS(.v17)],
    products: [.library(name: "KitoNavigation", targets: ["KitoNavigation"])],
    dependencies: [
        .package(url: "https://github.com/WykSofts-Inc/KitoCore.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "KitoNavigation", dependencies: [.product(name: "KitoCore", package: "KitoCore")]),
        .testTarget(name: "KitoNavigationTests", dependencies: ["KitoNavigation"]),
    ]
)
