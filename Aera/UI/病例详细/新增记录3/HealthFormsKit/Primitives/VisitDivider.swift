//
//  VisitDivider.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/22.
//

import SwiftUI


public struct VisitDivider: View {
    var color: Color
    var height: CGFloat
    var verticalPadding: CGFloat

    public init(color: Color = .gray, height: CGFloat = 1, verticalPadding: CGFloat = 4) {
        self.color = color
        self.height = height
        self.verticalPadding = verticalPadding
    }

    public var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
            .padding(.vertical, verticalPadding)
    }
}
