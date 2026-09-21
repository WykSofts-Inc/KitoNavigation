//
//  KitoTabItem.swift
//  KitoNavigation
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

public struct KitoTabItem: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var systemImage: String
    public var selectedSystemImage: String?
    public var badgeCount: Int

    public init(
        id: String,
        title: String,
        systemImage: String,
        selectedSystemImage: String? = nil,
        badgeCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.selectedSystemImage = selectedSystemImage
        self.badgeCount = badgeCount
    }
}
