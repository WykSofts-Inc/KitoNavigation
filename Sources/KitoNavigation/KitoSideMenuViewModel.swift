//
//  KitoSideMenuViewModel.swift
//  KitoNavigation
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Observation
import KitoCore

public enum KitoSideMenuEdge: Equatable, Sendable {
    case leading, trailing
}

/// Owns open/closed state (and in-progress drag offset, for the interactive
/// swipe-to-open/close gesture) for one drawer. Separate from
/// `KitoSheetPresenter` — a side menu is a persistent navigation surface, not
/// a transient presentation, and it needs drag-progress state a sheet doesn't.
@Observable
public final class KitoSideMenuViewModel: KitoViewModel {
    public var isOpen: Bool
    public var edge: KitoSideMenuEdge
    public var dragProgress: Double = 0

    public init(isOpen: Bool = false, edge: KitoSideMenuEdge = .leading) {
        self.isOpen = isOpen
        self.edge = edge
    }

    public func open() {
        isOpen = true
    }

    public func close() {
        isOpen = false
    }

    public func toggle() {
        isOpen.toggle()
    }
}
