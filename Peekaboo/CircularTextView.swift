import SwiftUI

/// A circular text view: lays your text around a circle of the given radius,
/// and sizes itself to 2×radius so it doesn’t fill the whole screen.
struct ArcTextView: View {
    let text: String
    let bend: CGFloat
    let radius: CGFloat
    let font: Font
    let color: Color

    private var letters: [String] { text.map { String($0) } }

    init(
        _ text: String,
        radius: CGFloat,
        bend: CGFloat,
        font: Font = .system(size: 20, weight: .regular),
        color: Color = .primary
    ) {
        self.text = text
        self.radius = radius
        self.bend = bend
        self.font = font
        self.color = color
    }

    var body: some View {
        ZStack {
            let count = letters.count
            let totalSpan = Double(bend) * .pi
            let step = count > 1 ? totalSpan / Double(count - 1) : 0
            let center = CGPoint(x: radius, y: radius)

            ForEach(0..<count, id: \.self) { i in
                let angle = -totalSpan / 2 + step * Double(i)
                let x = center.x + CGFloat(cos(angle)) * radius
                let y = center.y - CGFloat(sin(angle)) * radius

                Text(letters[i])
                    .font(font)
                    .foregroundColor(color)
                    .position(x: x, y: y)
                    .rotationEffect(Angle(radians: angle + .pi/2))
            }
        }
        .frame(width: radius * 2, height: radius * 2)
    }
}


#Preview {
    ArcTextView("Hello, SwiftUI!", radius: 150, bend: 0.5, font: .title, color: .blue)
}
