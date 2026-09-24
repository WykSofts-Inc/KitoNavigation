//
//  KitoDrawerComponents.swift
//  KitoNavigation
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

// Building blocks for side menus: a profile header, rows with badges, grouped sections, tiles,
// a callout card, toggles and a footer button. They use `.primary`/`.secondary` for text, so they
// read on light and dark drawers alike; `tint` colours selection and accents.

/// A round avatar: an image, or initials on a gradient, with an optional gradient ring.
public struct KitoAvatar: View {
    let image: Image?
    let initials: String
    let colors: [Color]
    let size: CGFloat
    let showsRing: Bool

    public init(initials: String, image: Image? = nil, colors: [Color] = [.orange, .pink, .purple], size: CGFloat = 56, showsRing: Bool = false) {
        self.initials = initials
        self.image = image
        self.colors = colors
        self.size = size
        self.showsRing = showsRing
    }

    public var body: some View {
        ZStack {
            if let image {
                image.resizable().scaledToFill()
            } else {
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Text(initials).font(.system(size: size * 0.36, weight: .bold, design: .rounded)).foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .padding(showsRing ? size * 0.06 : 0)
        .overlay {
            if showsRing { Circle().strokeBorder(AngularGradient(colors: colors + [colors.first ?? .clear], center: .center), lineWidth: max(size * 0.045, 2)) }
        }
        .accessibilityHidden(true)
    }
}

/// The person at the top of a drawer: avatar, name and a detail line (an email, a plan).
public struct KitoDrawerHeader: View {
    public enum Layout: Sendable { case stacked, inline }

    let name: String
    let detail: String?
    let avatar: KitoAvatar
    let layout: Layout

    public init(name: String, detail: String? = nil, avatar: KitoAvatar, layout: Layout = .stacked) {
        self.name = name
        self.detail = detail
        self.avatar = avatar
        self.layout = layout
    }

    public var body: some View {
        Group {
            switch layout {
            case .stacked:
                VStack(alignment: .leading, spacing: 12) {
                    avatar
                    text
                }
            case .inline:
                HStack(spacing: 14) {
                    avatar
                    text
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name).font(.title3.weight(.bold)).foregroundStyle(.primary)
            if let detail { Text(detail).font(.subheadline).foregroundStyle(.secondary) }
        }
    }
}

/// One destination in a drawer: an icon, a title, an optional badge ("$10", "New", "3"), and a
/// filled selected state.
public struct KitoDrawerItem: View {
    @Environment(\.kitoTheme) private var theme
    let title: String
    let systemImage: String
    let badge: String?
    let isSelected: Bool
    let tint: Color?
    let badgeTint: Color?
    let showsChevron: Bool
    let action: () -> Void

    /// `badgeTint` colours the badge when the row isn't selected; it defaults to `tint`.
    public init(_ title: String, systemImage: String, badge: String? = nil, isSelected: Bool = false, tint: Color? = nil,
                badgeTint: Color? = nil, showsChevron: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.badge = badge
        self.isSelected = isSelected
        self.tint = tint
        self.badgeTint = badgeTint
        self.showsChevron = showsChevron
        self.action = action
    }

    private var accent: Color { tint ?? theme.colors.primary }
    private var onAccent: Color { tint == nil ? theme.colors.onPrimary : .white }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage).font(.system(size: 17, weight: .medium)).frame(width: 26)
                Text(title).font(.body.weight(isSelected ? .semibold : .regular)).lineLimit(1)
                Spacer(minLength: 8)
                if let badge {
                    Text(badge).font(.caption.weight(.bold)).padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(isSelected ? Color.white.opacity(0.25) : (badgeTint ?? accent).opacity(0.15)))
                        .foregroundStyle(isSelected ? onAccent : (badgeTint ?? accent))
                }
                if showsChevron {
                    Image(systemName: "chevron.forward").font(.caption.weight(.bold)).foregroundStyle(isSelected ? onAccent.opacity(0.7) : Color.secondary)
                }
            }
            .foregroundStyle(isSelected ? onAccent : Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                if isSelected { RoundedRectangle(cornerRadius: 14, style: .continuous).fill(accent) }
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(KitoDrawerPressStyle())
        .accessibilityValue(badge ?? "")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// A switch in a drawer, e.g. dark mode or notifications.
public struct KitoDrawerToggle: View {
    @Environment(\.kitoTheme) private var theme
    let title: String
    let systemImage: String
    @Binding var isOn: Bool
    let tint: Color?

    public init(_ title: String, systemImage: String, isOn: Binding<Bool>, tint: Color? = nil) {
        self.title = title
        self.systemImage = systemImage
        self._isOn = isOn
        self.tint = tint
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 14) {
                Image(systemName: systemImage).font(.system(size: 17, weight: .medium)).frame(width: 26)
                Text(title)
            }
        }
        .tint(tint ?? theme.colors.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

/// A titled group of drawer rows.
public struct KitoDrawerSection<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content

    public init(_ title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title {
                Text(title.uppercased()).font(.caption.weight(.bold)).kerning(0.8).foregroundStyle(.secondary)
                    .padding(.horizontal, 14).padding(.bottom, 6)
                    .accessibilityAddTraits(.isHeader)
            }
            content()
        }
    }
}

/// A square shortcut for a grid at the top of a drawer.
public struct KitoDrawerTile: View {
    let title: String
    let systemImage: String
    let detail: String?
    let tint: Color
    let action: () -> Void

    public init(_ title: String, systemImage: String, detail: String? = nil, tint: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.detail = detail
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage).font(.title3.weight(.semibold)).foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint.opacity(0.15)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary).lineLimit(1)
                    if let detail { Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.primary.opacity(0.06)))
        }
        .buttonStyle(KitoDrawerPressStyle())
    }
}

/// Lays tiles out in equal columns.
public struct KitoDrawerTileGrid<Content: View>: View {
    let columns: Int
    @ViewBuilder let content: () -> Content

    public init(columns: Int = 2, @ViewBuilder content: @escaping () -> Content) {
        self.columns = max(columns, 1)
        self.content = content
    }

    public var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10, content: content)
    }
}

/// A card that asks for something: verify your email, finish your profile, upgrade.
public struct KitoDrawerCallout: View {
    let systemImage: String
    let title: String
    let message: String
    let actionTitle: String?
    let tint: Color
    let action: () -> Void
    let onDismiss: (() -> Void)?

    public init(systemImage: String, title: String, message: String, actionTitle: String? = nil, tint: Color = .orange,
                action: @escaping () -> Void = {}, onDismiss: (() -> Void)? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.tint = tint
        self.action = action
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage).font(.headline).foregroundStyle(.white)
                .frame(width: 36, height: 36).background(Circle().fill(tint))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.bold)).foregroundStyle(.primary)
                Text(message).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                if let actionTitle {
                    Button(actionTitle, action: action).font(.caption.weight(.bold)).foregroundStyle(tint).padding(.top, 4)
                }
            }
            Spacer(minLength: 0)
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark").font(.caption.weight(.bold)).foregroundStyle(.secondary).padding(6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(tint.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(tint.opacity(0.25), lineWidth: 1))
    }
}

/// The button at the foot of a drawer, e.g. Sign out.
public struct KitoDrawerFooterButton: View {
    let title: String
    let systemImage: String
    let role: ButtonRole?
    let action: () -> Void

    public init(_ title: String, systemImage: String = "rectangle.portrait.and.arrow.right", role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    public var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage).font(.subheadline.weight(.semibold))
                .foregroundStyle(role == .destructive ? Color.red : Color.primary)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(Capsule().fill(role == .destructive ? Color.red.opacity(0.12) : Color.primary.opacity(0.08)))
        }
        .buttonStyle(KitoDrawerPressStyle())
    }
}

struct KitoDrawerPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Rail

/// A slim column of icons, for a compact sidebar or an iPad-style rail.
public struct KitoSideRail<Header: View, Footer: View>: View {
    @Environment(\.kitoTheme) private var theme
    let items: [KitoTabItem]
    @Binding var selection: String
    let tint: Color?
    @ViewBuilder let header: () -> Header
    @ViewBuilder let footer: () -> Footer
    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(items: [KitoTabItem], selection: Binding<String>, tint: Color? = nil,
                @ViewBuilder header: @escaping () -> Header, @ViewBuilder footer: @escaping () -> Footer) {
        self.items = items
        self._selection = selection
        self.tint = tint
        self.header = header
        self.footer = footer
    }

    private var accent: Color { tint ?? theme.colors.primary }
    private var onAccent: Color { tint == nil ? theme.colors.onPrimary : .white }

    public var body: some View {
        VStack(spacing: 10) {
            header().padding(.bottom, 10)
            ForEach(items) { item in
                let selected = item.id == selection
                Button { withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.78)) { selection = item.id } } label: {
                    Image(systemName: selected ? (item.selectedSystemImage ?? item.systemImage) : item.systemImage)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(selected ? onAccent : Color.secondary)
                        .frame(width: 50, height: 50)
                        .background {
                            if selected { RoundedRectangle(cornerRadius: 16, style: .continuous).fill(accent).matchedGeometryEffect(id: "rail", in: namespace) }
                        }
                        .overlay(alignment: .topTrailing) {
                            if item.badgeCount > 0 { Circle().fill(theme.colors.danger).frame(width: 9, height: 9).offset(x: -8, y: 8) }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
            Spacer(minLength: 10)
            footer()
        }
        .padding(.vertical, 20)
        .frame(width: 76)
    }
}

public extension KitoSideRail where Header == EmptyView, Footer == EmptyView {
    init(items: [KitoTabItem], selection: Binding<String>, tint: Color? = nil) {
        self.init(items: items, selection: selection, tint: tint, header: { EmptyView() }, footer: { EmptyView() })
    }
}

// MARK: - Top tabs

/// Look of `KitoTopTabs`.
public enum KitoTopTabsStyle: String, CaseIterable, Sendable {
    /// Text with a line sliding under the selected tab.
    case underline
    /// A filled capsule sliding behind the selected tab.
    case pill
    /// Separate chips; the selected one fills.
    case chips
}

/// Scrollable tabs for the top of a screen, keeping the selected tab in view.
public struct KitoTopTabs: View {
    @Environment(\.kitoTheme) private var theme
    let titles: [String]
    @Binding var selection: String
    let style: KitoTopTabsStyle
    let tint: Color?
    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ titles: [String], selection: Binding<String>, style: KitoTopTabsStyle = .underline, tint: Color? = nil) {
        self.titles = titles
        self._selection = selection
        self.style = style
        self.tint = tint
    }

    private var accent: Color { tint ?? theme.colors.primary }
    private var onAccent: Color { tint == nil ? theme.colors.onPrimary : .white }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: style == .chips ? 8 : 2) {
                    ForEach(titles, id: \.self) { title in
                        tab(title).id(title)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, style == .pill ? 4 : 0)
                .background {
                    if style == .pill { Capsule().fill(Color.primary.opacity(0.06)).padding(.horizontal, 12) }
                }
            }
            .overlay(alignment: .bottom) { if style == .underline { Divider() } }
            .onChange(of: selection) { _, value in withAnimation(reduceMotion ? nil : .snappy) { proxy.scrollTo(value, anchor: .center) } }
        }
    }

    private func tab(_ title: String) -> some View {
        let selected = title == selection
        // With Reduce Motion on, the indicator jumps to the new tab instead of sliding.
        return Button { withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) { selection = title } } label: {
            Text(title)
                .font(.subheadline.weight(selected ? .semibold : .medium))
                .foregroundStyle(foreground(selected))
                .padding(.horizontal, 14)
                .padding(.vertical, style == .underline ? 12 : 8)
                .background { background(selected) }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func foreground(_ selected: Bool) -> Color {
        switch style {
        case .underline: return selected ? accent : .secondary
        case .pill, .chips: return selected ? onAccent : .primary
        }
    }

    @ViewBuilder
    private func background(_ selected: Bool) -> some View {
        switch style {
        case .underline:
            if selected {
                Capsule().fill(accent).frame(height: 3).frame(maxHeight: .infinity, alignment: .bottom)
                    .matchedGeometryEffect(id: "top", in: namespace)
            }
        case .pill:
            if selected { Capsule().fill(accent).matchedGeometryEffect(id: "top", in: namespace) }
        case .chips:
            Capsule().fill(selected ? accent : Color.primary.opacity(0.06))
        }
    }
}
