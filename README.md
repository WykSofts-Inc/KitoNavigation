# KitoNavigation

A typed, MVVM-friendly router for `NavigationStack` — push/pop/popToRoot,
pop-to-a-specific-route, and a full-screen-cover slot for auth gates and
onboarding, all driven by one `@Observable` router instead of scattered
`@State` booleans.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoNavigation.git", from: "1.1.0"),
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

**Styles.** Pass `style:` (and optionally `tint:`) to `KitoTabContainerView` or `KitoTabBarView`:

| Style | Look |
|---|---|
| `.classic` | Edge to edge, a soft capsule behind the selected icon |
| `.floating` | A capsule above the content, a dot under the selected icon |
| `.pill` | The selected tab grows into a filled pill showing its title |
| `.underline` | A line glides along the top edge |
| `.bubble` | The selected icon rises into a circle in a curved dip that follows it |
| `.glass` | Frosted glass floating over the content |
| `.segmented` | A filled tile slides behind the icon and title |
| `.minimal` | Icons only; the dot stretches, the icon bounces |
| `.notched` | A raised centre button in a notch — pass `centerAction` |

```swift
KitoTabContainerView(viewModel: tabs, style: .notched, tint: .indigo,
                     centerAction: KitoTabCenterAction(systemImage: "plus") { compose() }) { id in
    screen(for: id)
}
```

Content scrolls under the bar, so floating styles look right. `KitoTabBarShape` is the curved
bar on its own if you want the dip elsewhere.

## Top tabs

Scrollable tabs for the top of a screen, keeping the selected one in view:

```swift
KitoTopTabs(["For you", "Following", "Nearby"], selection: $feed, style: .underline)   // or .pill, .chips
```

## Side menu / drawer

A swipeable drawer — drag or tap a hamburger button; it closes on an outside tap, a swipe
back or the accessibility escape gesture.

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

**Transitions.** `style:` picks how the drawer and the screen move, and `background:` what the
drawer sits on (`.material`, `.color(_:)` or `.gradient(_:)`):

| Style | Motion |
|---|---|
| `.push` | The drawer pushes the screen aside |
| `.overlay` | Slides over a dimmed screen |
| `.reveal` | The screen slides away to show the drawer underneath |
| `.scale` | The screen shrinks into a rounded card |
| `.rotate3D` | The screen swings away in perspective |
| `.floating` | An inset, rounded drawer over a softened screen |

```swift
RootView()
    .kitoSideMenu(viewModel: menu, style: .scale, background: .gradient([.indigo, .purple])) {
        DrawerContent()
    }
```

**Drawer building blocks** — they use `.primary`/`.secondary`, so they read on light and dark
drawers:

```swift
VStack(alignment: .leading, spacing: 22) {
    KitoDrawerHeader(name: "Wycliff N", detail: "wycliff@example.com",
                     avatar: KitoAvatar(initials: "WN", size: 60, showsRing: true))
    KitoDrawerCallout(systemImage: "envelope.badge.fill", title: "Verify your email",
                      message: "Confirm it to keep your account secure.", actionTitle: "Send link")
    KitoDrawerTileGrid {
        KitoDrawerTile("Orders", systemImage: "shippingbox.fill", detail: "2 on the way", tint: .blue) { }
        KitoDrawerTile("Wallet", systemImage: "creditcard.fill", detail: "$248.50", tint: .green) { }
    }
    KitoDrawerSection("Messages") {
        KitoDrawerItem("Home", systemImage: "house.fill", isSelected: true) { }
        KitoDrawerItem("My wallet", systemImage: "wallet.pass.fill", badge: "$10") { }
        KitoDrawerItem("Password", systemImage: "key.fill", showsChevron: true) { }
    }
    KitoDrawerToggle("Dark mode", systemImage: "moon.fill", isOn: $dark)
    Spacer()
    KitoDrawerFooterButton("Sign out") { signOut() }
}
```

`KitoSideRail` is a slim column of icons with a sliding highlight, for a compact sidebar or a
workspace switcher.

## License

MIT
