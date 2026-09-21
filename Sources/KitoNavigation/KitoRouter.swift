//
//  KitoRouter.swift
//  KitoNavigation
//
//  Created by Wycliff on 8/6/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import Observation
import KitoCore

/// A typed router for one `NavigationStack`. Owns the push stack and, since a
/// screen often needs both push navigation and a modal at once, an optional
/// full-screen cover route — kept separate from `KitoSheetPresenter`
/// (KitoModals) because full-screen covers are navigation-adjacent (often
/// used for auth gates / onboarding) while sheets are presentation-adjacent.
@Observable
public final class KitoRouter<Route: KitoRoute>: KitoViewModel {
    public var path: [Route] = []
    public var fullScreenCover: Route?

    public init() {}

    public func push(_ route: Route) {
        path.append(route)
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func popToRoot() {
        path.removeAll()
    }

    /// Pops back to (and including) the first occurrence of `route` in the
    /// stack. No-op if `route` isn't present.
    public func popTo(_ route: Route) {
        guard let index = path.firstIndex(of: route) else { return }
        path.removeSubrange((index + 1)...)
    }

    public func replaceStack(with routes: [Route]) {
        path = routes
    }

    public func presentFullScreen(_ route: Route) {
        fullScreenCover = route
    }

    public func dismissFullScreen() {
        fullScreenCover = nil
    }
}
