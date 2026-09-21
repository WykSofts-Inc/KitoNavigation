//
//  KitoRouterView.swift
//  KitoNavigation
//
//  Created by Wycliff on 8/7/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Wraps a `NavigationStack` bound to `router.path`, resolving each pushed
/// `Route` and the optional full-screen cover route through your
/// `destination` builder. One call sets up an entire flow's navigation.
///
/// ```swift
/// enum Route: KitoRoute { case details(Item), settings }
/// @State var router = KitoRouter<Route>()
///
/// KitoRouterView(router: router, root: { HomeView() }) { route in
///     switch route {
///     case .details(let item): DetailsView(item: item)
///     case .settings: SettingsView()
///     }
/// }
/// ```
public struct KitoRouterView<Route: KitoRoute, Root: View, Destination: View>: View {
    @Bindable var router: KitoRouter<Route>
    @ViewBuilder let root: () -> Root
    @ViewBuilder let destination: (Route) -> Destination

    public init(
        router: KitoRouter<Route>,
        @ViewBuilder root: @escaping () -> Root,
        @ViewBuilder destination: @escaping (Route) -> Destination
    ) {
        self.router = router
        self.root = root
        self.destination = destination
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            root()
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { router.fullScreenCover != nil },
                set: { if !$0 { router.fullScreenCover = nil } }
            )
        ) {
            if let route = router.fullScreenCover {
                destination(route)
            }
        }
    }
}
