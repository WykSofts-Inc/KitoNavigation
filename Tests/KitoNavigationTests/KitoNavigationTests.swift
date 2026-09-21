//
//  KitoNavigationTests.swift
//  KitoNavigation
//
//  Created by Wycliff on 8/8/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoNavigation

private enum TestRoute: KitoRoute {
    case a, b, c
}

@MainActor
final class KitoNavigationTests: XCTestCase {
    func testPushAppendsToPath() {
        let router = KitoRouter<TestRoute>()
        router.push(.a)
        router.push(.b)
        XCTAssertEqual(router.path, [.a, .b])
    }

    func testPopRemovesLast() {
        let router = KitoRouter<TestRoute>()
        router.push(.a)
        router.push(.b)
        router.pop()
        XCTAssertEqual(router.path, [.a])
    }

    func testPopOnEmptyStackIsNoOp() {
        let router = KitoRouter<TestRoute>()
        router.pop()
        XCTAssertTrue(router.path.isEmpty)
    }

    func testPopToRouteTrimsStack() {
        let router = KitoRouter<TestRoute>()
        router.push(.a)
        router.push(.b)
        router.push(.c)
        router.popTo(.a)
        XCTAssertEqual(router.path, [.a])
    }

    func testPopToRootClearsStack() {
        let router = KitoRouter<TestRoute>()
        router.push(.a)
        router.push(.b)
        router.popToRoot()
        XCTAssertTrue(router.path.isEmpty)
    }

    func testFullScreenCoverLifecycle() {
        let router = KitoRouter<TestRoute>()
        router.presentFullScreen(.a)
        XCTAssertEqual(router.fullScreenCover, .a)
        router.dismissFullScreen()
        XCTAssertNil(router.fullScreenCover)
    }

    // MARK: - KitoTabBarViewModel

    private func tabItems() -> [KitoTabItem] {
        [
            KitoTabItem(id: "home", title: "Home", systemImage: "house"),
            KitoTabItem(id: "search", title: "Search", systemImage: "magnifyingglass"),
            KitoTabItem(id: "profile", title: "Profile", systemImage: "person", badgeCount: 3),
        ]
    }

    func testTabBarDefaultsToFirstItem() {
        let viewModel = KitoTabBarViewModel(items: tabItems())
        XCTAssertEqual(viewModel.selectedID, "home")
    }

    func testTabBarSelectSwitchesTab() {
        let viewModel = KitoTabBarViewModel(items: tabItems())
        viewModel.select("search")
        XCTAssertEqual(viewModel.selectedID, "search")
    }

    func testTabBarReselectFiresCallbackWithoutChangingSelection() {
        var reselectedID: String?
        let viewModel = KitoTabBarViewModel(items: tabItems(), onReselect: { reselectedID = $0 })
        viewModel.select("home")
        XCTAssertEqual(reselectedID, "home")
        XCTAssertEqual(viewModel.selectedID, "home")
    }

    func testTabBarBadgeCountLookup() {
        let viewModel = KitoTabBarViewModel(items: tabItems())
        XCTAssertEqual(viewModel.badgeCount(for: "profile"), 3)
        XCTAssertEqual(viewModel.badgeCount(for: "home"), 0)
    }

    // MARK: - KitoSideMenuViewModel

    func testSideMenuStartsClosedByDefault() {
        XCTAssertFalse(KitoSideMenuViewModel().isOpen)
    }

    func testSideMenuToggleFlipsState() {
        let viewModel = KitoSideMenuViewModel()
        viewModel.toggle()
        XCTAssertTrue(viewModel.isOpen)
        viewModel.toggle()
        XCTAssertFalse(viewModel.isOpen)
    }

    func testSideMenuOpenAndClose() {
        let viewModel = KitoSideMenuViewModel()
        viewModel.open()
        XCTAssertTrue(viewModel.isOpen)
        viewModel.close()
        XCTAssertFalse(viewModel.isOpen)
    }

    func testSideMenuDefaultEdgeIsLeading() {
        XCTAssertEqual(KitoSideMenuViewModel().edge, .leading)
    }
}
