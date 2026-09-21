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
    public let items: [KitoTabItem]
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
}
