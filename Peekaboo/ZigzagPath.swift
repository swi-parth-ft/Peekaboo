//
//  ZigzagPath.swift
//  Peekaboo
//
//  Created by Parth Antala on 2025-05-01.
//


import SwiftUI

/// A Shape that draws a zigzag path following the provided points.
struct ZigzagPath: Shape {
    /// The sequence of points the user dragged through.
    var points: [CGPoint]
    /// Optional per-segment amplitudes. If nil, uses `amplitude`.
    var amplitudes: [CGFloat]? = nil
    /// The amplitude of the zigzag offset.
    var amplitude: CGFloat = 10
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        // Start at the first point
        path.move(to: points[0])
        
        // For each segment, insert a midpoint offset by amplitude alternately
        for i in 1..<points.count {
            let p0 = points[i - 1]
            let p1 = points[i]
            
            // Midpoint
            let midX = (p0.x + p1.x) / 2
            let midY = (p0.y + p1.y) / 2
            
            // Direction vector
            let dx = p1.x - p0.x
            let dy = p1.y - p0.y
            let length = sqrt(dx * dx + dy * dy)
            let nx = length > 0 ? -dy / length : 0
            let ny = length > 0 ? dx / length : 0
            
            let segAmp = (amplitudes != nil && amplitudes!.count >= points.count - 1)
                ? amplitudes![i - 1]
                : amplitude
            // Alternate sign for zigzag
            let sign: CGFloat = (i % 2 == 0) ? 1 : -1
            let offsetX = midX + nx * segAmp * sign
            let offsetY = midY + ny * segAmp * sign
            let midPoint = CGPoint(x: offsetX, y: offsetY)
            
            // Draw to mid then to end
            path.addLine(to: midPoint)
            path.addLine(to: p1)
        }
        return path
    }
}



struct ZigzagPainterView: View {
    // Stroke data
    @State private var points: [CGPoint] = []
    @State private var amplitudes: [CGFloat] = []
    @State private var trimEnd: CGFloat = 0

    // Brush parameters now driven by state
    @State private var brushColor: Color = .yellow
    @State private var brushWidth: CGFloat = 50
    @State private var amplitude: CGFloat = 70

    // Debug toggle
    @State private var showDebug: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1) Faint wide, low-opacity understroke
                ZigzagPath(points: points, amplitudes: amplitudes, amplitude: amplitude)
                    .trim(from: 0, to: trimEnd)
                    .stroke(brushColor.opacity(0.4), style: StrokeStyle(
                        lineWidth: brushWidth * 1.3,
                        lineCap: .round,
                        lineJoin: .round
                    ))

                // 2) Main stroke
                ZigzagPath(points: points, amplitudes: amplitudes, amplitude: amplitude)
                    .trim(from: 0, to: trimEnd)
                    .stroke(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .bottomTrailing, endPoint: .topLeading)
                        , style: StrokeStyle(
                        lineWidth: brushWidth,
                        lineCap: .round,
                        lineJoin: .round
                    ))
                   

                // 3) Thin highlight
                ZigzagPath(points: points, amplitudes: amplitudes, amplitude: amplitude)
                    .trim(from: 0, to: trimEnd)
                    .stroke(brushColor.opacity(0.6), style: StrokeStyle(
                        lineWidth: brushWidth * 0.7,
                        lineCap: .round,
                        lineJoin: .round
                    ))
            }
            .rotationEffect(Angle(degrees: -45))
            .onAppear {
                // Generate base points on center line
                var generated: [CGPoint] = []
                let w = geo.size.width, h = geo.size.height
                let segmentCount = max(1, Int(w / 40))
                let dx = w / CGFloat(segmentCount)
                for i in 0...segmentCount {
                    generated.append(.init(x: CGFloat(i) * dx, y: h/2))
                }
                points = generated

                // Randomized per-segment amplitudes
                amplitudes = (0..<generated.count - 1).map { _ in
                    CGFloat.random(in: amplitude * 0.2...amplitude * 2.0)
                }

                // Animate the draw
                withAnimation(.linear(duration: 1.5)) {
                    trimEnd = 1
                }
            }
        }
    }
}

#if DEBUG
struct ZigzagPainterView_Previews: PreviewProvider {
    static var previews: some View {
        ZigzagPainterView()
           // .frame(height: 400)
            .padding()
    }
}
#endif
