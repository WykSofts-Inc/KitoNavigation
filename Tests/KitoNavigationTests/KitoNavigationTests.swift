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

    // MARK: - Side menu maths

    func testSideMenuProgressFollowsTheDrag() {
        XCTAssertEqual(KitoSideMenuMath.progress(isOpen: false, translation: 0, width: 300), 0)
        XCTAssertEqual(KitoSideMenuMath.progress(isOpen: false, translation: 150, width: 300), 0.5)
        XCTAssertEqual(KitoSideMenuMath.progress(isOpen: true, translation: -75, width: 300), 0.75)
    }

    func testSideMenuProgressIsClamped() {
        XCTAssertEqual(KitoSideMenuMath.progress(isOpen: false, translation: -80, width: 300), 0)
        XCTAssertEqual(KitoSideMenuMath.progress(isOpen: true, translation: 500, width: 300), 1)
        XCTAssertEqual(KitoSideMenuMath.progress(isOpen: true, translation: 0, width: 0), 1)
    }

    func testSideMenuSettlesPastHalfway() {
        XCTAssertTrue(KitoSideMenuMath.settlesOpen(isOpen: false, predictedTranslation: 160, width: 300))
        XCTAssertFalse(KitoSideMenuMath.settlesOpen(isOpen: false, predictedTranslation: 100, width: 300))
        XCTAssertFalse(KitoSideMenuMath.settlesOpen(isOpen: true, predictedTranslation: -200, width: 300))
        XCTAssertTrue(KitoSideMenuMath.settlesOpen(isOpen: true, predictedTranslation: -60, width: 300))
    }

    func testDrawerBehindStyles() {
        XCTAssertEqual(KitoSideMenuStyle.allCases.filter(\.drawerIsBehind), [.reveal, .scale, .rotate3D])
    }

    // MARK: - Tab bar

    func testFloatingTabStyles() {
        XCTAssertEqual(KitoTabBarStyle.allCases.filter(\.floats), [.floating, .pill, .glass, .segmented])
    }

    func testTabBarShapeDipFollowsTheSelectedTab() {
        let rect = CGRect(x: 0, y: 0, width: 400, height: 80)
        let first = KitoTabBarShape(notchCenter: 0.125, horizontalInset: 0)
        XCTAssertEqual(first.notchX(in: rect), 50)
        XCTAssertEqual(KitoTabBarShape(notchCenter: 2, horizontalInset: 10).notchX(in: rect), 390)
        let path = first.path(in: rect)
        XCTAssertFalse(path.contains(CGPoint(x: 50, y: 10)), "the dip is cut out")
        XCTAssertTrue(path.contains(CGPoint(x: 300, y: 10)))
    }

    func testTabBarShapeAnimatesItsDip() {
        var shape = KitoTabBarShape(notchCenter: 0.2)
        shape.animatableData = 0.8
        XCTAssertEqual(shape.notchCenter, 0.8)
    }
}
