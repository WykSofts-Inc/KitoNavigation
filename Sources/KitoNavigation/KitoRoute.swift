//
//  KitoRoute.swift
//  KitoNavigation
//
//  Created by Wycliff on 8/5/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

/// Conform an enum of your app's push destinations to this. `Hashable` is
/// what lets `NavigationStack` (and `NavigationPath`) store heterogeneous
/// routes; `KitoRouter` never needs to know your concrete route type beyond
/// this constraint.
public protocol KitoRoute: Hashable {}
