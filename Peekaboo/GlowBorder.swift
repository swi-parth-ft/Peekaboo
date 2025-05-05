//
//  GlowBorder.swift
//  Peekaboo
//
//  Created by Parth Antala on 2025-05-01.
//

import SwiftUI
import UIKit

struct GlowBorder: ViewModifier {
    var color: Color
    var linewidth: Int
    
    
    func body (content: Content) -> some View {
        applyShadow(content: AnyView(content), lineWidth: linewidth)
    }
    func applyShadow(content: AnyView, lineWidth: Int) -> AnyView {
        if lineWidth == 0 {
            return content
        }
        else {
            return applyShadow(content: AnyView(content.shadow(color: color, radius: 1)), lineWidth: lineWidth
            - 1)
        }
    }
}
extension View {
    func glowBorder (color: Color, lineWidth: Int) -> some View { self.modifier(GlowBorder(color: color, linewidth: lineWidth))
    }
}
