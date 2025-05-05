//
//  DottedBackground.swift
//  Peekaboo
//
//  Created by Parth Antala on 2025-05-01.
//
import SwiftUI

struct DottedBackground: View {
    var dotSize: CGFloat = 4
    var spacing: CGFloat = 24
    var color: Color = .gray.opacity(0.3)

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let columns = Int(size.width / spacing) + 1
                let rows    = Int(size.height / spacing) + 1
                for col in 0..<columns {
                    for row in 0..<rows {
                        let x = CGFloat(col) * spacing
                        let y = CGFloat(row) * spacing
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                            with: .color(color)
                        )
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}
