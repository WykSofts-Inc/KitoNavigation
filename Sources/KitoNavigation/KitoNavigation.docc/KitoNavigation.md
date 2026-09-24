# ``KitoNavigation``

A typed, MVVM-friendly router for navigation stacks, plus themed tab bars, top tabs and a side menu.

## Overview

``KitoRouter`` drives a `NavigationStack` from one `@Observable` object instead
of scattered `@State` booleans. It supports push, pop, pop to root, pop to a
specific route, replacing the whole stack, and a full-screen cover slot for auth
gates and onboarding. Define your routes as an enum conforming to ``KitoRoute``
and let ``KitoRouterView`` resolve each one through a single destination builder.

```swift
enum AppRoute: KitoRoute {
    case productDetails(id: String)
    case cart
}

struct RootView: View {
    @State private var router = KitoRouter<AppRoute>()

    var body: some View {
        KitoRouterView(router: router, root: { HomeScreen() }) { route in
            switch route {
            case .productDetails(let id): ProductDetailsScreen(id: id)
            case .cart: CartScreen()
            }
        }
        .environment(router)
    }
}
```

Because the router is a plain object, a view model can call `router.push(_:)`
directly, which keeps navigation testable.

``KitoTabContainerView`` is a custom bottom tab bar in one of nine
``KitoTabBarStyle`` looks that keeps each tab's navigation stack alive while it
is hidden. ``KitoTopTabs`` provides scrollable tabs for the top of a screen, and
the `kitoSideMenu(viewModel:style:background:menu:)` modifier attaches a
swipeable drawer, with drawer building blocks such as ``KitoDrawerHeader`` and
``KitoDrawerItem`` for its content.

## Topics

### Routing

- ``KitoRoute``
- ``KitoRouter``
- ``KitoRouterView``

### Tab Bar

- ``KitoTabContainerView``
- ``KitoTabBarView``
- ``KitoTabBarViewModel``
- ``KitoTabItem``
- ``KitoTabBarStyle``
- ``KitoTabCenterAction``
- ``KitoTabBarShape``

### Top Tabs

- ``KitoTopTabs``
- ``KitoTopTabsStyle``

### Side Menu

- ``KitoSideMenuViewModel``
- ``KitoSideMenuStyle``
- ``KitoSideMenuBackground``
- ``KitoSideMenuEdge``
- ``KitoSideMenuRow``
- ``KitoSideRail``

### Drawer Components

- ``KitoDrawerHeader``
- ``KitoAvatar``
- ``KitoDrawerSection``
- ``KitoDrawerItem``
- ``KitoDrawerToggle``
- ``KitoDrawerTile``
- ``KitoDrawerTileGrid``
- ``KitoDrawerCallout``
- ``KitoDrawerFooterButton``
