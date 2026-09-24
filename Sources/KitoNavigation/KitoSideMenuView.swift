//
//  KitoSideMenuView.swift
//  KitoNavigation
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// How the drawer and the screen move when the menu opens.
public enum KitoSideMenuStyle: String, CaseIterable, Sendable {
    /// The drawer slides in and pushes the screen aside with it.
    case push
    /// The drawer slides over the screen, which dims and stays put.
    case overlay
    /// The drawer waits underneath; the screen slides away to reveal it.
    case reveal
    /// The screen shrinks into a rounded card and slides aside, the drawer behind it.
    case scale
    /// The screen swings away in 3D.
    case rotate3D
    /// The drawer is a rounded card inset from the edges, over a dimmed screen.
    case floating

    /// Styles that draw the drawer behind the screen, on a full-screen background.
    public var drawerIsBehind: Bool { [.reveal, .scale, .rotate3D].contains(self) }
}

/// What the drawer sits on.
public enum KitoSideMenuBackground: Sendable {
    case material
    case color(Color)
    case gradient([Color])
}

enum KitoSideMenuMath {
    /// How open the drawer looks, 0…1, from its resting state and a drag along the opening
    /// direction (positive opens).
    static func progress(isOpen: Bool, translation: CGFloat, width: CGFloat) -> CGFloat {
        guard width > 0 else { return isOpen ? 1 : 0 }
        return min(max((isOpen ? 1 : 0) + translation / width, 0), 1)
    }

    /// Where a released drag settles: open past halfway, counting the fling.
    static func settlesOpen(isOpen: Bool, predictedTranslation: CGFloat, width: CGFloat) -> Bool {
        progress(isOpen: isOpen, translation: predictedTranslation, width: width) > 0.5
    }
}

private struct KitoSideMenuModifier<Menu: View>: ViewModifier {
    @Bindable var viewModel: KitoSideMenuViewModel
    let menuWidth: CGFloat
    let style: KitoSideMenuStyle
    let background: KitoSideMenuBackground
    @ViewBuilder let menu: () -> Menu

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection
    /// Drag distance along the layout direction (positive = toward trailing), so the
    /// math below stays semantic: drag values are physical, offsets mirror in RTL.
    @State private var translation: CGFloat = 0

    /// Converts a physical drag width into the layout direction.
    private func semantic(_ width: CGFloat) -> CGFloat { layoutDirection == .rightToLeft ? -width : width }

    private var sign: CGFloat { viewModel.edge == .leading ? 1 : -1 }
    private var progress: CGFloat { KitoSideMenuMath.progress(isOpen: viewModel.isOpen, translation: translation * sign, width: menuWidth) }
    private var animation: Animation { reduceMotion ? .easeInOut(duration: 0.22) : .spring(response: 0.42, dampingFraction: 0.86) }

    func body(content: Content) -> some View {
        let p = progress
        ZStack(alignment: viewModel.edge == .leading ? .leading : .trailing) {
            if style.drawerIsBehind {
                backdrop.ignoresSafeArea()
                drawer
                    .opacity(style == .reveal || reduceMotion ? 1 : Double(p))
                    .offset(x: style == .reveal ? 0 : -sign * 40 * (1 - p))
            }

            styled(content, progress: p)

            if !style.drawerIsBehind {
                if style == .floating {
                    drawer
                        .background(backdrop.clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous)))
                        .shadow(color: .black.opacity(0.25 * p), radius: 30, y: 10)
                        .padding(12)
                        .offset(x: -sign * (menuWidth + 30) * (1 - p))
                } else {
                    drawer
                        .background(backdrop.ignoresSafeArea())
                        .shadow(color: .black.opacity(style == .overlay ? 0.2 * p : 0), radius: 20)
                        .offset(x: -sign * menuWidth * (1 - p))
                }
            }
        }
        .gesture(dragGesture)
        .animation(animation, value: viewModel.isOpen)
        .onChange(of: p) { _, value in viewModel.dragProgress = Double(value) }
        .accessibilityAction(.escape) { if viewModel.isOpen { viewModel.close() } }
    }

    private var drawer: some View {
        menu()
            .frame(width: menuWidth)
            .frame(maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(viewModel.isOpen)
            .accessibilityHidden(!viewModel.isOpen)
    }

    @ViewBuilder
    private var backdrop: some View {
        switch background {
        case .material: Rectangle().fill(.regularMaterial)
        case .color(let color): Rectangle().fill(color)
        case .gradient(let colors): LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    @ViewBuilder
    private func styled(_ content: Content, progress p: CGFloat) -> some View {
        let screen = content
            .disabled(viewModel.isOpen)
            .overlay {
                // Content shifts aside rather than being covered, so the app
                // still reads as "in place" behind an open drawer; a tap on it closes.
                Color.black.opacity(dim * Double(p))
                    .contentShape(Rectangle())
                    .allowsHitTesting(viewModel.isOpen)
                    .onTapGesture { withAnimation(animation) { viewModel.close() } }
                    .ignoresSafeArea()
            }
        let corner = 34 * p
        switch style {
        case .push:
            screen.offset(x: sign * menuWidth * p)
        case .overlay, .floating:
            screen.blur(radius: style == .floating ? 3 * p : 0)
        case .reveal:
            screen
                .shadow(color: .black.opacity(0.3 * p), radius: 24)
                .offset(x: sign * menuWidth * p)
        case .scale:
            screen
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .shadow(color: .black.opacity(0.3 * p), radius: 30, x: -sign * 8)
                .scaleEffect(1 - 0.16 * p)
                .offset(x: sign * menuWidth * 0.9 * p)
        case .rotate3D:
            screen
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .shadow(color: .black.opacity(0.3 * p), radius: 30)
                .rotation3DEffect(.degrees(Double(-sign * 28 * p)), axis: (x: 0, y: 1, z: 0),
                                  anchor: sign > 0 ? .leading : .trailing, perspective: 0.5)
                .scaleEffect(1 - 0.1 * p)
                .offset(x: sign * menuWidth * 0.95 * p)
        }
    }

    private var dim: Double {
        switch style {
        case .overlay, .floating: return 0.4
        case .push: return 0.2
        case .reveal, .scale, .rotate3D: return 0.08
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { translation = semantic($0.translation.width) }
            .onEnded { value in
                let open = KitoSideMenuMath.settlesOpen(isOpen: viewModel.isOpen, predictedTranslation: semantic(value.predictedEndTranslation.width) * sign, width: menuWidth)
                withAnimation(animation) {
                    viewModel.isOpen = open
                    translation = 0
                }
            }
    }
}

public extension View {
    /// Attaches a swipeable side menu/drawer. The edge (`viewModel.edge`) is
    /// `.leading` by default. `style` picks how the drawer and the screen move:
    /// push, overlay, reveal, scale, 3D or a floating card. `background` is what
    /// the drawer sits on — for `.reveal`, `.scale` and `.rotate3D` it fills the
    /// whole screen behind, so a colour or gradient reads best.
    ///
    /// ```swift
    /// @State private var menu = KitoSideMenuViewModel()
    ///
    /// ContentView()
    ///     .kitoSideMenu(viewModel: menu, style: .scale, background: .color(.indigo)) {
    ///         MenuContentView()
    ///     }
    ///     .toolbar {
    ///         Button("Menu", systemImage: "line.3.horizontal") { menu.toggle() }
    ///     }
    /// ```
    func kitoSideMenu<Menu: View>(
        viewModel: KitoSideMenuViewModel,
        menuWidth: CGFloat = 300,
        style: KitoSideMenuStyle = .push,
        background: KitoSideMenuBackground = .material,
        @ViewBuilder menu: @escaping () -> Menu
    ) -> some View {
        modifier(KitoSideMenuModifier(viewModel: viewModel, menuWidth: menuWidth, style: style, background: background, menu: menu))
    }
}
