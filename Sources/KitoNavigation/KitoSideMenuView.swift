//
//  KitoSideMenuView.swift
//  KitoNavigation
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

private struct KitoSideMenuModifier<Menu: View>: ViewModifier {
    @Bindable var viewModel: KitoSideMenuViewModel
    let menuWidth: CGFloat
    @ViewBuilder let menu: () -> Menu

    func body(content: Content) -> some View {
        let alignment: Alignment = viewModel.edge == .leading ? .leading : .trailing

        ZStack(alignment: alignment) {
            content
                // Content shifts aside rather than being covered, so the app
                // still reads as "in place" behind an open drawer.
                .offset(x: contentOffset)
                .disabled(viewModel.isOpen)

            if viewModel.isOpen {
                Color.black.opacity(0.001 + dimOpacity * 0.35)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { viewModel.close() } }
                    .offset(x: contentOffset)
                    .allowsHitTesting(true)
            }

            menu()
                .frame(width: menuWidth)
                .frame(maxHeight: .infinity)
                .background(.regularMaterial)
                .offset(x: menuOffset)
        }
        .gesture(dragGesture)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.isOpen)
    }

    private var sign: CGFloat { viewModel.edge == .leading ? 1 : -1 }

    private var menuOffset: CGFloat {
        let closed = -sign * menuWidth
        let open: CGFloat = 0
        let base = viewModel.isOpen ? open : closed
        return base + sign * CGFloat(viewModel.dragProgress) * menuWidth
    }

    private var contentOffset: CGFloat {
        let openContentShift = sign * menuWidth * 0.7
        let base = viewModel.isOpen ? openContentShift : 0
        return base + sign * CGFloat(viewModel.dragProgress) * menuWidth * 0.7
    }

    private var dimOpacity: Double {
        viewModel.isOpen ? 1 : viewModel.dragProgress
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { drag in
                let translation = (drag.translation.width * sign) / menuWidth
                if viewModel.isOpen {
                    viewModel.dragProgress = min(max(translation, -1), 0) + 1
                } else {
                    viewModel.dragProgress = min(max(translation, 0), 1)
                }
            }
            .onEnded { drag in
                let translation = (drag.translation.width * sign) / menuWidth
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if viewModel.isOpen {
                        viewModel.isOpen = translation > -0.3
                    } else {
                        viewModel.isOpen = translation > 0.3
                    }
                    viewModel.dragProgress = 0
                }
            }
    }
}

public extension View {
    /// Attaches a swipeable side menu/drawer. `menuWidth` defaults to 78% of
    /// a typical phone width's comfortable drawer size; pass a fixed value
    /// for tighter control. The edge (`viewModel.edge`) is `.leading` by
    /// default, which is already RTL-correct — it becomes the *visual*
    /// trailing edge automatically under a right-to-left locale.
    ///
    /// ```swift
    /// @State private var menu = KitoSideMenuViewModel()
    ///
    /// ContentView()
    ///     .kitoSideMenu(viewModel: menu) {
    ///         MenuContentView()
    ///     }
    ///     .toolbar {
    ///         Button("Menu", systemImage: "line.3.horizontal") { menu.toggle() }
    ///     }
    /// ```
    func kitoSideMenu<Menu: View>(
        viewModel: KitoSideMenuViewModel,
        menuWidth: CGFloat = 300,
        @ViewBuilder menu: @escaping () -> Menu
    ) -> some View {
        modifier(KitoSideMenuModifier(viewModel: viewModel, menuWidth: menuWidth, menu: menu))
    }
}
