//
//  KitoTabBarView.swift
//  KitoNavigation
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A themed, custom bottom tab bar — not `TabView`'s system chrome, so icon
/// scale/color, the selection indicator, and badges all follow `kitoTheme`
/// instead of the OS's tab bar appearance.
public struct KitoTabBarView: View {
    @Environment(\.kitoTheme) private var theme
    @Bindable var viewModel: KitoTabBarViewModel
    @Namespace private var indicatorNamespace

    public init(viewModel: KitoTabBarViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.items) { item in
                tabButton(item)
            }
        }
        .padding(.top, theme.spacing.sm)
        .padding(.bottom, theme.spacing.xs)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func tabButton(_ item: KitoTabItem) -> some View {
        let isSelected = item.id == viewModel.selectedID
        return Button {
            viewModel.select(item.id)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(theme.colors.primary.opacity(0.14))
                            .frame(width: 44, height: 28)
                            .matchedGeometryEffect(id: "indicator", in: indicatorNamespace)
                    }
                    Image(systemName: isSelected ? (item.selectedSystemImage ?? item.systemImage) : item.systemImage)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? theme.colors.primary : theme.colors.onBackground.opacity(0.5))
                        .overlay(alignment: .topTrailing) {
                            if item.badgeCount > 0 {
                                badge(item.badgeCount)
                            }
                        }
                }
                .frame(height: 28)

                Text(item.title)
                    .font(theme.typography.caption)
                    .foregroundStyle(isSelected ? theme.colors.primary : theme.colors.onBackground.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: viewModel.selectedID)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func badge(_ count: Int) -> some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .frame(minWidth: 16, minHeight: 16)
            .background(theme.colors.danger, in: Capsule())
            .offset(x: 10, y: -6)
    }
}

/// Wraps per-tab content and the tab bar together — pass a view builder that
/// switches on the tab id. Each tab's content should own its own
/// `NavigationStack`/`KitoRouterView` so switching tabs doesn't reset the
/// other tabs' navigation state (content is kept alive via the `ForEach` +
/// `opacity`/`zIndex` pattern below rather than an `if/else`, which would
/// destroy and recreate the hidden tab's view hierarchy on every switch).
public struct KitoTabContainerView<Content: View>: View {
    @Bindable var viewModel: KitoTabBarViewModel
    @ViewBuilder let content: (String) -> Content

    public init(viewModel: KitoTabBarViewModel, @ViewBuilder content: @escaping (String) -> Content) {
        self.viewModel = viewModel
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(viewModel.items) { item in
                    content(item.id)
                        .opacity(item.id == viewModel.selectedID ? 1 : 0)
                        .zIndex(item.id == viewModel.selectedID ? 1 : 0)
                        .allowsHitTesting(item.id == viewModel.selectedID)
                }
            }
            KitoTabBarView(viewModel: viewModel)
        }
        .ignoresSafeArea(.keyboard)
    }
}
