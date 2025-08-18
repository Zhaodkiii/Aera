//
//  FlowLayout.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//
import SwiftUI



struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let runSpacing: CGFloat
    @ViewBuilder let content: Content
    
    init(spacing: CGFloat = 8, runSpacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.runSpacing = runSpacing
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { proxy in
            self.generateContent(in: proxy.size)
        }
        .frame(minHeight: 0)
    }
    
    private func generateContent(in size: CGSize) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        return ZStack(alignment: .topLeading) {
            content
                .padding(.trailing, spacing)
                .alignmentGuide(.leading) { d in
                    if abs(width - d.width) > size.width {
                        width = 0
                        height -= (d.height + runSpacing)
                    }
                    let result = width
                    width -= d.width + spacing
                    return result
                }
                .alignmentGuide(.top) { d in
                    let result = height
                    return result
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
