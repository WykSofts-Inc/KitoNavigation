# KitoNavigation

A typed, MVVM-friendly router for `NavigationStack` — push/pop/popToRoot,
pop-to-a-specific-route, and a full-screen-cover slot for auth gates and
onboarding, all driven by one `@Observable` router instead of scattered
`@State` booleans.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoNavigation.git", from: "1.0.0"),
```

## Samples

**Define routes, wire the stack:**
```swift
enum AppRoute: KitoRoute {
    case productDetails(id: String)
    case cart
    case checkout
}

struct RootView: View {
    @State private var router = KitoRouter<AppRoute>()

    var body: some View {
        KitoRouterView(router: router, root: { HomeScreen() }) { route in
            switch route {
            case .productDetails(let id): ProductDetailsScreen(id: id)
            case .cart: CartScreen()
            case .checkout: CheckoutScreen()
            }
        }
        .environment(router)
    }
}
```

**Push from a ViewModel (not the view) — keeps navigation testable:**
```swift
@Observable final class HomeViewModel {
    let router: KitoRouter<AppRoute>
    func productTapped(_ id: String) { router.push(.productDetails(id: id)) }
}
```

**Pop to a known point after checkout completes:**
```swift
func onCheckoutComplete() {
    router.popTo(.cart)   // back to cart, not all the way to root
    router.pop()          // now drop cart too — back at home
}
```

**Auth gate via full-screen cover:**
```swift
enum AppRoute: KitoRoute { case signIn, home }

.onAppear {
    if !session.isAuthenticated { router.presentFullScreen(.signIn) }
}
// after sign-in succeeds:
router.dismissFullScreen()
```

**Deep link handling:**
```swift
func handle(url: URL) {
    guard let id = productID(from: url) else { return }
    router.popToRoot()
    router.push(.productDetails(id: id))
}
```

## Tab bar

A themed, custom bottom tab bar — not `TabView`'s system chrome — that keeps
each tab's own navigation stack alive while it's hidden.

```swift
@State private var tabs = KitoTabBarViewModel(items: [
    KitoTabItem(id: "home", title: "Home", systemImage: "house", selectedSystemImage: "house.fill"),
    KitoTabItem(id: "cart", title: "Cart", systemImage: "cart", badgeCount: 2),
    KitoTabItem(id: "profile", title: "Profile", systemImage: "person"),
])

KitoTabContainerView(viewModel: tabs) { tabID in
    switch tabID {
    case "home": KitoRouterView(router: homeRouter, root: { HomeScreen() }, destination: homeDestination)
    case "cart": CartScreen()
    case "profile": ProfileScreen()
    default: EmptyView()
    }
}
```

**React to tapping the already-selected tab** (the conventional "scroll to
top" / "reset this tab" gesture):
```swift
let tabs = KitoTabBarViewModel(items: items, onReselect: { id in
    if id == "home" { homeRouter.popToRoot() }
})
```

## Side menu / drawer

A swipeable drawer — drag from the edge or tap a hamburger button, dims and
shifts the main content aside, closes on outside tap or a swipe back.

```swift
@State private var menu = KitoSideMenuViewModel()   // .leading by default, RTL-correct automatically

RootView()
    .kitoSideMenu(viewModel: menu) {
        VStack(alignment: .leading, spacing: 4) {
            KitoSideMenuRow(systemImage: "house", title: "Home", isSelected: true) { menu.close() }
            KitoSideMenuRow(systemImage: "gearshape", title: "Settings") { router.push(.settings); menu.close() }
            KitoSideMenuRow(systemImage: "bell", title: "Notifications", badgeCount: 4) { menu.close() }
        }
        .padding(.top, 60)
    }
    .toolbar {
        Button("Menu", systemImage: "line.3.horizontal") { menu.toggle() }
    }
```

## License

MIT
