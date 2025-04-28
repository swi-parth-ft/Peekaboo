import SwiftUI
import CoreGraphics   // sin / cos

// add two CGSize values
private extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        .init(width: lhs.width + rhs.width,
              height: lhs.height + rhs.height)
    }
    static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
        .init(width: lhs.width / rhs, height: lhs.height / rhs)
    }
}

/// Drag + Pinch + Rotate text overlay that stays under your finger
/// after any rotation and never freezes.
struct DraggableText: View {
    // fixed
    let text:  String
    let font:  Font
    let color: Color
    let isSelected: Bool   // <-- Add this new line
    // committed transform (parent owns these; exporter uses them)
    @Binding var offset: CGSize   // .zero
    @Binding var scale:  CGFloat  // 1
    @Binding var angle:  Angle    // .zero
    var onDelete: (() -> Void)? = nil

    // live deltas while fingers are down
    @State private var liveDrag: CGSize = .zero
    @GestureState private var pinchΔ: CGFloat = 1
    @GestureState private var rotΔ:   Angle   = .zero
    @State private var isOverTrash = false   // ← new
    var body: some View {

        // full-canvas transparent hit-area so gestures always register
        GeometryReader { geo in
            // ── GESTURES ───────────────────────────────────────────────
            let pinch = MagnificationGesture()
                .updating($pinchΔ) { v, s, _ in s = v }
                .onEnded { v in scale *= v }

            let rotate = RotationGesture()
                .updating($rotΔ) { v, s, _ in s = v }
                .onEnded { v in angle += v }

            let drag = DragGesture()
                .onChanged { v in
                    // keep the text under the finger
                    let totalRot = angle + rotΔ
                    let currentScale = scale * pinchΔ
                    let rad = CGFloat(totalRot.radians)
                    let tr  = v.translation
                    liveDrag = CGSize(
                        width:  (tr.width  * cos(rad) + tr.height * sin(rad)) / currentScale,
                        height: (-tr.width * sin(rad) + tr.height * cos(rad)) / currentScale
                    )

                    // live trash hit-test
                    isOverTrash = (offset + liveDrag).height > (geo.size.height / 2 - 60)
                }
                .onEnded { v in
                    // commit the drag
                    let rad = CGFloat(angle.radians)
                    let tr  = v.translation
                    let newOffset = offset + CGSize(
                        width:  (tr.width  * cos(rad) + tr.height * sin(rad)) / scale,
                        height: (-tr.width * sin(rad) + tr.height * cos(rad)) / scale
                    )

                    // final trash check
                    if newOffset.height > (geo.size.height / 2 - 60) {
                        onDelete?()
                    } else {
                        offset = newOffset
                    }
                    liveDrag   = .zero
                    isOverTrash = false
                }

            let combo = drag
                .simultaneously(with: pinch)
                .simultaneously(with: rotate)

            ZStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: geo.size.width, height: geo.size.height)

                ZStack(alignment: .topTrailing) {
                    Text(text)
                        .font(font)
                        .foregroundColor(color)
                        .shadow(radius: 3)
                }
                .if(isSelected) { view in
                    view.overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .inset(by: -8)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(.black)
                    )
                }
                .scaleEffect(scale * pinchΔ)
                .rotationEffect(angle + rotΔ, anchor: .center)
                .offset(offset + liveDrag)
                .gesture(combo)

                // Trash bin icon at the bottom
                Image(systemName: "trash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(isOverTrash ? .red : .gray)
                    .offset(y: geo.size.height / 2 - 60)
            }
        }
        .contentShape(Rectangle())
        
    }
}



extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool,
                              transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
