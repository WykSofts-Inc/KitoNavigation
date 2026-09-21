//
//  KitoSideMenuRow.swift
//  KitoNavigation
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// The common icon + title (+ optional trailing badge) row most side menus
/// are built from — themed, tappable, with a selected-state background so a
/// menu can highlight "where you are" the same way a tab bar does.
public struct KitoSideMenuRow: View {
    @Environment(\.kitoTheme) private var theme
    let systemImage: String
    let title: String
    let badgeCount: Int
    let isSelected: Bool
    let action: () -> Void

    public init(
        systemImage: String,
        title: String,
        badgeCount: Int = 0,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.title = title
        self.badgeCount = badgeCount
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                    .frame(width: 24)
                    .foregroundStyle(isSelected ? theme.colors.primary : theme.colors.onBackground.opacity(0.7))
                Text(title)
                    .font(isSelected ? theme.typography.bodyEmphasized : theme.typography.body)
                    .foregroundStyle(isSelected ? theme.colors.primary : theme.colors.onBackground)
                Spacer()
                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(theme.typography.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.colors.danger, in: Capsule())
                }
            }
            .padding(.vertical, theme.spacing.sm)
            .padding(.horizontal, theme.spacing.md)
            .background(isSelected ? theme.colors.primary.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: theme.radii.md))
        }
        .buttonStyle(.plain)
    }
}
