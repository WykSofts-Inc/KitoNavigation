//
//  KitoTabBarView.swift
//  KitoNavigation
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// How a `KitoTabBarView` looks and moves.
public enum KitoTabBarStyle: String, CaseIterable, Sendable {
    /// Edge to edge on the system bar material, a soft capsule behind the selected icon.
    case classic
    /// A capsule floating above the content, with a dot under the selected icon.
    case floating
    /// The selected tab grows into a filled pill that shows its title.
    case pill
    /// A short line slides along the top edge to the selected tab.
    case underline
    /// The selected icon rises into a circle that sits in a curved dip in the bar.
    case bubble
    /// A floating capsule of frosted glass with a sliding highlight.
    case glass
    /// A filled tile slides behind the selected icon and title.
    case segmented
    /// Icons only, a dot under the selected one.
    case minimal
    /// A raised centre action button sitting in a notch; pass `centerAction`.
    case notched

    /// Styles that float over content rather than sitting flush with the bottom edge.
    public var floats: Bool { [.floating, .pill, .glass, .segmented].contains(self) }
}

/// The raised button in the middle of a `.notched` tab bar.
public struct KitoTabCenterAction {
    public var systemImage: String
    public var accessibilityLabel: String
    public var action: () -> Void

    public init(systemImage: String = "plus", accessibilityLabel: String = "Create", action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
}

/// A themed, custom bottom tab bar — not `TabView`'s system chrome, so icon
/// scale/color, the selection indicator, and badges all follow `kitoTheme`
/// instead of the OS's tab bar appearance. Pick a look with `style`.
public struct KitoTabBarView: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var viewModel: KitoTabBarViewModel
    let style: KitoTabBarStyle
    let tint: Color?
    let centerAction: KitoTabCenterAction?
    @Namespace private var indicatorNamespace

    public init(viewModel: KitoTabBarViewModel, style: KitoTabBarStyle = .classic, tint: Color? = nil, centerAction: KitoTabCenterAction? = nil) {
        self.viewModel = viewModel
        self.style = style
        self.tint = tint
        self.centerAction = centerAction
    }

    private var accent: Color { tint ?? theme.colors.primary }
    private var onAccent: Color { tint == nil ? theme.colors.onPrimary : .white }
    private var muted: Color { theme.colors.onBackground.opacity(0.5) }
    private var selectedIndex: Int { viewModel.items.firstIndex { $0.id == viewModel.selectedID } ?? 0 }
    private var animation: Animation { reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.36, dampingFraction: 0.76) }

    public var body: some View {
        Group {
            switch style {
            case .classic: classic
            case .floating: floating
            case .pill: pill
            case .underline: underline
            case .bubble: bubble
            case .glass: glass
            case .segmented: segmented
            case .minimal: minimal
            case .notched: if let centerAction { notched(centerAction) } else { floating }
            }
        }
        .animation(animation, value: viewModel.selectedID)
    }

    // MARK: Styles

    private var classic: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.items) { item in
                tab(item) { selected in
                    VStack(spacing: 4) {
                        ZStack {
                            if selected {
                                Capsule().fill(accent.opacity(0.14)).frame(width: 44, height: 28)
                                    .matchedGeometryEffect(id: "indicator", in: indicatorNamespace)
                            }
                            icon(item, selected: selected, color: selected ? accent : muted)
                        }
                        .frame(height: 28)
                        Text(item.title).font(theme.typography.caption).foregroundStyle(selected ? accent : muted)
                    }
                }
            }
        }
        .padding(.top, theme.spacing.sm)
        .padding(.bottom, theme.spacing.xs)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private var floating: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.items) { item in
                tab(item) { selected in
                    VStack(spacing: 6) {
                        icon(item, selected: selected, color: selected ? accent : muted, size: 21)
                        Circle().fill(accent).frame(width: 5, height: 5)
                            .scaleEffect(selected ? 1 : 0.2).opacity(selected ? 1 : 0)
                    }
                    .padding(.vertical, 14)
                }
            }
        }
        .padding(.horizontal, 8)
        .background(Capsule().fill(theme.colors.surface).shadow(color: .black.opacity(0.16), radius: 22, y: 10))
        .padding(.horizontal, 24)
        .padding(.bottom, 6)
    }

    private var pill: some View {
        HStack(spacing: 4) {
            ForEach(viewModel.items) { item in
                let selected = item.id == viewModel.selectedID
                Button { viewModel.select(item.id) } label: {
                    HStack(spacing: 8) {
                        icon(item, selected: selected, color: selected ? onAccent : muted)
                        if selected {
                            Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(onAccent).lineLimit(1).fixedSize()
                                .transition(.opacity.combined(with: .scale(scale: 0.6, anchor: .leading)))
                        }
                    }
                    .padding(.horizontal, selected ? 18 : 12)
                    .frame(height: 48)
                    .frame(maxWidth: selected ? .infinity : nil)
                    .background {
                        if selected { Capsule().fill(accent).matchedGeometryEffect(id: "pill", in: indicatorNamespace) }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: selected ? .infinity : nil)
                .modifier(TabAccessibility(item: item, selected: selected))
            }
        }
        .padding(7)
        .background(Capsule().fill(theme.colors.surface).shadow(color: .black.opacity(0.14), radius: 20, y: 8))
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    private var underline: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.items) { item in
                tab(item) { selected in
                    VStack(spacing: 4) {
                        icon(item, selected: selected, color: selected ? accent : muted)
                        Text(item.title).font(.caption2.weight(selected ? .bold : .medium)).foregroundStyle(selected ? accent : muted)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .top) {
                        if selected {
                            Capsule().fill(accent).frame(width: 30, height: 3)
                                .matchedGeometryEffect(id: "line", in: indicatorNamespace)
                        }
                    }
                }
            }
        }
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private var bubble: some View {
        let count = CGFloat(max(viewModel.items.count, 1))
        return HStack(spacing: 0) {
            ForEach(viewModel.items) { item in
                tab(item) { selected in
                    ZStack {
                        Circle().fill(accent).frame(width: 52, height: 52)
                            .shadow(color: accent.opacity(0.35), radius: 10, y: 6)
                            .scaleEffect(selected ? 1 : 0.4).opacity(selected ? 1 : 0)
                        icon(item, selected: selected, color: selected ? onAccent : muted, size: 21)
                    }
                    .offset(y: selected ? -26 : 0)
                    .frame(height: 58)
                }
            }
        }
        .padding(.horizontal, 10)
        .background {
            KitoTabBarShape(notchCenter: (CGFloat(selectedIndex) + 0.5) / count, horizontalInset: 10, notchRadius: 36, notchDepth: 34)
                .fill(theme.colors.surface)
                .shadow(color: .black.opacity(0.12), radius: 16, y: -2)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var glass: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.items) { item in
                tab(item) { selected in
                    VStack(spacing: 3) {
                        icon(item, selected: selected, color: selected ? accent : theme.colors.onBackground.opacity(0.7), size: 19)
                        Text(item.title).font(.system(size: 10, weight: .semibold)).foregroundStyle(selected ? accent : theme.colors.onBackground.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background {
                        if selected { Capsule().fill(accent.opacity(0.16)).matchedGeometryEffect(id: "glass", in: indicatorNamespace) }
                    }
                }
            }
        }
        .padding(6)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
        .padding(.horizontal, 18)
        .padding(.bottom, 6)
    }

    private var segmented: some View {
        HStack(spacing: 4) {
            ForEach(viewModel.items) { item in
                tab(item) { selected in
                    VStack(spacing: 4) {
                        icon(item, selected: selected, color: selected ? onAccent : muted, size: 19)
                        Text(item.title).font(.caption2.weight(.semibold)).foregroundStyle(selected ? onAccent : muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(accent)
                                .matchedGeometryEffect(id: "tile", in: indicatorNamespace)
                        }
                    }
                }
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(theme.colors.surface).shadow(color: .black.opacity(0.14), radius: 20, y: 8))
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private var minimal: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.items) { item in
                tab(item) { selected in
                    VStack(spacing: 6) {
                        icon(item, selected: selected, color: selected ? accent : muted, size: 23)
                            .symbolEffect(.bounce, value: selected)
                        Capsule().fill(accent).frame(width: selected ? 16 : 4, height: 4).opacity(selected ? 1 : 0)
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 6)
                }
            }
        }
        .background(theme.colors.background.ignoresSafeArea(edges: .bottom))
    }

    private func notched(_ center: KitoTabCenterAction) -> some View {
        let half = viewModel.items.count / 2
        let leading = Array(viewModel.items.prefix(half))
        let trailing = Array(viewModel.items.dropFirst(half))
        return HStack(spacing: 0) {
            ForEach(leading) { item in notchedTab(item) }
            Color.clear.frame(width: 84, height: 1)
            ForEach(trailing) { item in notchedTab(item) }
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .padding(.horizontal, 6)
        .background {
            KitoTabBarShape(notchCenter: 0.5, horizontalInset: 0, notchRadius: 42, notchDepth: 38)
                .fill(theme.colors.surface)
                .shadow(color: .black.opacity(0.12), radius: 16, y: -2)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Button(action: center.action) {
                Image(systemName: center.systemImage).font(.title2.weight(.bold)).foregroundStyle(onAccent)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(accent).shadow(color: accent.opacity(0.45), radius: 12, y: 6))
            }
            .buttonStyle(KitoTabPressStyle())
            .offset(y: -30)
            .accessibilityLabel(center.accessibilityLabel)
        }
    }

    private func notchedTab(_ item: KitoTabItem) -> some View {
        tab(item) { selected in
            VStack(spacing: 4) {
                icon(item, selected: selected, color: selected ? accent : muted)
                Text(item.title).font(.caption2.weight(selected ? .bold : .medium)).foregroundStyle(selected ? accent : muted)
            }
        }
    }

    // MARK: Pieces

    private func tab<Label: View>(_ item: KitoTabItem, @ViewBuilder label: (Bool) -> Label) -> some View {
        let selected = item.id == viewModel.selectedID
        return Button { viewModel.select(item.id) } label: {
            label(selected).frame(maxWidth: .infinity).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(TabAccessibility(item: item, selected: selected))
    }

    private func icon(_ item: KitoTabItem, selected: Bool, color: Color, size: CGFloat = 20) -> some View {
        Image(systemName: selected ? (item.selectedSystemImage ?? item.systemImage) : item.systemImage)
            .font(.system(size: size, weight: selected ? .semibold : .regular))
            .foregroundStyle(color)
            .frame(height: 26)
            .overlay(alignment: .topTrailing) {
                if item.badgeCount > 0 { badge(item.badgeCount) }
            }
    }

    private func badge(_ count: Int) -> some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .frame(minWidth: 16, minHeight: 16)
            .background(theme.colors.danger, in: Capsule())
            .overlay(Capsule().stroke(theme.colors.surface, lineWidth: 1.5))
            .offset(x: 10, y: -4)
    }
}

private struct TabAccessibility: ViewModifier {
    let item: KitoTabItem
    let selected: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(item.title)
            .accessibilityValue(item.badgeCount > 0 ? "\(item.badgeCount) new" : "")
            .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

struct KitoTabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A bar with a smooth dip cut into its top edge. `notchCenter` (0…1) animates, so the dip
/// glides between tabs.
public struct KitoTabBarShape: Shape {
    public var notchCenter: CGFloat
    public var horizontalInset: CGFloat
    public var notchRadius: CGFloat
    public var notchDepth: CGFloat

    public init(notchCenter: CGFloat, horizontalInset: CGFloat = 0, notchRadius: CGFloat = 36, notchDepth: CGFloat = 34) {
        self.notchCenter = notchCenter
        self.horizontalInset = horizontalInset
        self.notchRadius = notchRadius
        self.notchDepth = notchDepth
    }

    public var animatableData: CGFloat {
        get { notchCenter }
        set { notchCenter = newValue }
    }

    /// The dip's centre in the rect's coordinates.
    func notchX(in rect: CGRect) -> CGFloat {
        rect.minX + horizontalInset + min(max(notchCenter, 0), 1) * (rect.width - horizontalInset * 2)
    }

    public func path(in rect: CGRect) -> Path {
        let x = notchX(in: rect)
        let r = notchRadius
        let shoulder: CGFloat = 18
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: x - r - shoulder, y: rect.minY))
        path.addCurve(to: CGPoint(x: x, y: rect.minY + notchDepth),
                      control1: CGPoint(x: x - r + 4, y: rect.minY),
                      control2: CGPoint(x: x - r + 2, y: rect.minY + notchDepth))
        path.addCurve(to: CGPoint(x: x + r + shoulder, y: rect.minY),
                      control1: CGPoint(x: x + r - 2, y: rect.minY + notchDepth),
                      control2: CGPoint(x: x + r - 4, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Wraps per-tab content and the tab bar together — pass a view builder that
/// switches on the tab id. Each tab's content should own its own
/// `NavigationStack`/`KitoRouterView` so switching tabs doesn't reset the
/// other tabs' navigation state (content is kept alive via the `ForEach` +
/// `opacity`/`zIndex` pattern below rather than an `if/else`, which would
/// destroy and recreate the hidden tab's view hierarchy on every switch).
/// Content scrolls under the bar, so floating styles look right.
public struct KitoTabContainerView<Content: View>: View {
    @Bindable var viewModel: KitoTabBarViewModel
    let style: KitoTabBarStyle
    let tint: Color?
    let centerAction: KitoTabCenterAction?
    @ViewBuilder let content: (String) -> Content

    public init(viewModel: KitoTabBarViewModel, style: KitoTabBarStyle = .classic, tint: Color? = nil,
                centerAction: KitoTabCenterAction? = nil, @ViewBuilder content: @escaping (String) -> Content) {
        self.viewModel = viewModel
        self.style = style
        self.tint = tint
        self.centerAction = centerAction
        self.content = content
    }

    public var body: some View {
        ZStack {
            ForEach(viewModel.items) { item in
                content(item.id)
                    .opacity(item.id == viewModel.selectedID ? 1 : 0)
                    .zIndex(item.id == viewModel.selectedID ? 1 : 0)
                    .allowsHitTesting(item.id == viewModel.selectedID)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            KitoTabBarView(viewModel: viewModel, style: style, tint: tint, centerAction: centerAction)
        }
        .ignoresSafeArea(.keyboard)
    }
}
