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

    // Customization properties
    var useGradient:    Bool    = false
    var gradientStart:  Color   = .white
    var gradientEnd:    Color   = .white
    var shadowEnabled:  Bool    = false
    var shadowColor:    Color   = .black
    var shadowRadius:   CGFloat = 3
    var shadowX:        CGFloat = 0
    var shadowY:        CGFloat = 0

    /// Explicit memberwise initializer including customization parameters
    init(
        text: String,
        font: Font,
        color: Color,
        isSelected: Bool,
        offset: Binding<CGSize>,
        scale: Binding<CGFloat>,
        angle: Binding<Angle>,
        onDelete: (() -> Void)? = nil,
        useGradient: Bool = false,
        gradientStart: Color = .white,
        gradientEnd: Color = .white,
        shadowEnabled: Bool = false,
        shadowColor: Color = .black,
        shadowRadius: CGFloat = 3,
        shadowX: CGFloat = 0,
        shadowY: CGFloat = 0
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.isSelected = isSelected
        self._offset = offset
        self._scale = scale
        self._angle = angle
        self.onDelete = onDelete
        self.useGradient = useGradient
        self.gradientStart = gradientStart
        self.gradientEnd = gradientEnd
        self.shadowEnabled = shadowEnabled
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowX = shadowX
        self.shadowY = shadowY
    }

    // live deltas while fingers are down
    @State private var liveDrag: CGSize = .zero
    @GestureState private var pinchΔ: CGFloat = 1
    @GestureState private var rotΔ:   Angle   = .zero
    @State private var isOverTrash = false   // ← new
    @State private var isDeleting: Bool = false
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
                    // convert the gesture’s local translation into unscaled offset
                    liveDrag = v.translation / (scale * pinchΔ)

                    // Highlight delete when dragged above the top or below the bottom threshold
                    let distance = (offset + liveDrag).height
                    let threshold = geo.size.height / 2 - 60
                    isOverTrash = abs(distance) > threshold
                }
                .onEnded { v in
                    // commit the drag using the gesture’s local translation scaled back
                    let newOffset = offset + (v.translation / scale)

                    // final trash check
                    let finalDist = newOffset.height
                    let threshold = geo.size.height / 2 - 60
                    if abs(finalDist) > threshold {
                        // commit position for in-place animation
                        offset = newOffset
                        liveDrag = .zero
                        withAnimation(.spring()) {
                            isDeleting = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDelete?()
                        }
                    } else {
                        offset = newOffset
                        liveDrag = .zero
                    }
                    isOverTrash = false
                }

            let combo = drag
                .simultaneously(with: pinch)
                .simultaneously(with: rotate)

            ZStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: geo.size.width, height: geo.size.height)

                // Text + optional gradient fill + optional shadow
                ZStack {
                    if useGradient {
                        Text(text)
                            .font(font)
                            .overlay(
                                LinearGradient(
                                    colors: [gradientStart, gradientEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .mask(Text(text).font(font))
                    } else {
                        Text(text)
                            .font(font)
                            .foregroundColor(color)
                    }
                }
                .shadow(
                    color: shadowEnabled ? shadowColor : .clear,
                    radius: shadowRadius,
                    x: shadowX,
                    y: shadowY
                )
                .if(isSelected) { view in
                    view.overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .inset(by: -8)
                            .stroke(style: StrokeStyle(lineWidth: 3, dash: [5]))
                            .foregroundColor(.black)
                    )
                }
                .rotationEffect(angle + rotΔ, anchor: .center)
                .scaleEffect((scale * pinchΔ) * (isDeleting ? 0.01 : 1), anchor: .center)
                .offset(offset + liveDrag)
                .gesture(isSelected ? combo : nil)

                // Trash bin icon at the top (only when selected & dragging)
                if isSelected && liveDrag != .zero {
                    Image(systemName: "trash")
                        .font(.title)
                        .bold()
                        .padding(18)
                        .background(isOverTrash ? .red.opacity(0.4) : .clear)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(radius: 2)
                        .foregroundColor(isOverTrash ? .red : .primary)
                        .offset(y: -(geo.size.height / 2 - 60))
                }
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
