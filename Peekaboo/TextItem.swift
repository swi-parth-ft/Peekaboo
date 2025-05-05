//
//  TextItem.swift
//  Peekaboo
//
//  Created by Parth Antala on 2025-05-01.
//

import Foundation
import UIKit
import SwiftUI
import Drops

struct TextItem: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var isBold: Bool
    var color: Color
    var offset: CGSize
    var scale: CGFloat
    var angle: Angle
    // New customization
    var fontName: String = "System"
    var useGradient: Bool = false
    var gradientStart: Color = .orange
    var gradientEnd:   Color = .yellow
    var shadowEnabled: Bool = false
    var shadowColor:   Color = .black
    var shadowRadius:  CGFloat = 3
    var shadowX:       CGFloat = 0
    var shadowY:       CGFloat = 0
    var bend: CGFloat = 0
    var textSize: CGFloat = 36
    var stroke: Bool = true
    var strokeColor: Color = .clear
    var strokeWidth: CGFloat = 1
    var background: Bool = false
    var backgroundColor: Color = .clear
    var gradientX: UnitPoint = .leading
    var gradientY: UnitPoint = .trailing
    var bold: Bool = false
    var italic: Bool = false
    var underline: Bool = false
    var rotation3D: Double = 0
}
