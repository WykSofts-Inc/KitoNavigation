//
//  KitoTabBarViewModel.swift
//  KitoNavigation
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Observation
import KitoCore

/// Owns which tab is selected, and re-selection state ("tapped the already-
/// selected tab") so a screen can distinguish "switch tabs" from "scroll to
/// top / reset this tab's own stack" — the two things a re-tap conventionally
/// means, and which need different handling.
@Observable
public final class KitoTabBarViewModel: KitoViewModel {
    /// The tabs, in order. Mutable so badges, titles or the tab set itself can
    /// change without rebuilding the view model; the selection is kept when the
    /// selected tab is still present, and falls back to the first tab otherwise.
    public var items: [KitoTabItem] {
        didSet {
            if !items.isEmpty, !items.contains(where: { $0.id == selectedID }) {
                selectedID = items[0].id
            }
        }
    }
    public var selectedID: String
    public var onReselect: (String) -> Void

    public init(items: [KitoTabItem], selectedID: String? = nil, onReselect: @escaping (String) -> Void = { _ in }) {
        precondition(!items.isEmpty, "KitoTabBarViewModel needs at least one tab")
        self.items = items
        self.selectedID = selectedID ?? items[0].id
        self.onReselect = onReselect
    }

    public func select(_ id: String) {
        if id == selectedID {
            onReselect(id)
        } else {
            selectedID = id
        }
    }

    public func badgeCount(for id: String) -> Int {
        items.first { $0.id == id }?.badgeCount ?? 0
    }

    /// Updates one tab's badge (e.g. a bag count). Negative counts are treated
    /// as zero; unknown ids are ignored. The selection is unchanged.
    public func setBadge(_ count: Int, for id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let value = max(0, count)
        guard items[index].badgeCount != value else { return }
        items[index].badgeCount = value
    }
}
