//
//  RulerSlider.swift
//  Peekaboo
//
//  Created by Parth Antala on 2025-04-30.
//


import SwiftUI
import UIKit

struct RulerSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let tickInterval: Double      // e.g. every 1 unit
    let majorTickInterval: Double // e.g. every 5 units
    let trackHeight: CGFloat = 2
    let minorTickHeight: CGFloat = 12
    let majorTickHeight: CGFloat = 24
    let thumbDiameter: CGFloat = 28

    @State private var lastValue: Double = 0
    private let feedback = UISelectionFeedbackGenerator()

    var body: some View {
        GeometryReader { geo in
            let totalSteps = Int((range.upperBound - range.lowerBound) / tickInterval)
            let pixelsPerStep = geo.size.width / CGFloat(totalSteps)

            ZStack(alignment: .center) {
                // 1) Ticks Row
                HStack(spacing: 0) {
                    ForEach(0...totalSteps, id: \.self) { i in
                        let isMajor = (Double(i) * tickInterval).truncatingRemainder(dividingBy: majorTickInterval) == 0
                        Rectangle()
                            .fill(Color.primary.opacity(isMajor ? 1 : 0.6))
                            .frame(width: 1, height: isMajor ? majorTickHeight : minorTickHeight)
                        if i < totalSteps {
                            Spacer()
                                .frame(width: pixelsPerStep - 1)
                        }
                    }
                }
                .frame(height: max(majorTickHeight, minorTickHeight))
                .offset(x: offsetForValue(in: geo.size.width))

                // 2) Center Indicator
                Rectangle()
                    .fill(LinearGradient(colors: [.pink, .orange], startPoint: .bottomLeading, endPoint: .topTrailing))
                    .frame(width: 4, height: majorTickHeight + 8)
                    .cornerRadius(40)
                    .shadow(radius: 5)
                    .zIndex(1)

                // 3) Invisible Drag Area
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { g in
                                let x = g.location.x
                                let pct = min(max(0, x / geo.size.width), 1)
                                let rawVal = range.lowerBound + (range.upperBound - range.lowerBound) * Double(pct)
                                let newVal = (rawVal / tickInterval).rounded() * tickInterval
                                if newVal != lastValue {
                                    feedback.selectionChanged()
                                    lastValue = newVal
                                }
                                value = newVal
                            }
                            .onEnded { g in
                                let predictedX = g.predictedEndLocation.x
                                let pct = min(max(0, predictedX / geo.size.width), 1)
                                let rawPred = range.lowerBound + (range.upperBound - range.lowerBound) * Double(pct)
                                let targetVal = (rawPred / tickInterval).rounded() * tickInterval
                                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    value = targetVal
                                }
                            }
                    )
                    .zIndex(2)
            }
        }
        .frame(height: max(majorTickHeight, thumbDiameter))
    }

    private func offsetForValue(in totalWidth: CGFloat) -> CGFloat {
        let pct = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        // we push the ticks opposite to thumb
        return (totalWidth * (pct - 0.5))
    }
}

struct RulerSliderPreviewWrapper: View {
    @State private var value: Double = 0.0 // starting at mid-range
    var body: some View {
        VStack(spacing: 16) {
            Text("Value: \(Int(value))")
                .foregroundColor(.white)
                .font(.headline)
            RulerSlider(
                value: $value,
                range: -50...50,
                tickInterval: 2,
                majorTickInterval: 10
            )
            .frame(height: 60)
            .padding(.horizontal)
        }
        .padding()
       
    }
}

struct RulerSlider_Previews: PreviewProvider {
    static var previews: some View {
        RulerSliderPreviewWrapper()
            .previewLayout(.sizeThatFits)
    }
}
