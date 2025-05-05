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
    var bend: CGFloat = 0
    var textSize: CGFloat = 16
    var stroke: Bool = false
    var strokeColor: Color = .black
    var strokeWidth: CGFloat = 1
    var background: Bool = false
    var backgroundColor: Color = .clear
    var gradientX: UnitPoint = .leading
    var gradientY: UnitPoint = .trailing
    var bold: Bool = false
    var italic: Bool = false
    var underline: Bool = false
    var rotation3D: Double = 0

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
        shadowY: CGFloat = 0,
        bend: CGFloat = 0,
        textSize: CGFloat = 16,
        stroke: Bool = false,
        strokeColor: Color = .black,
        strokeWidth: CGFloat = 1,
        background: Bool = false,
        backgroundColor: Color = .clear,
        gradientX: UnitPoint = .leading,
        gradientY: UnitPoint = .trailing,
        bold: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        rotation3D: Double = 0
        
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
        self.bend = bend
        self.textSize = textSize
        self.stroke = stroke
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.background = background
        self.backgroundColor = backgroundColor
        self.gradientX = gradientX
        self.gradientY = gradientY
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.rotation3D = rotation3D
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
                    isOverTrash = distance < -threshold
                }
                .onEnded { v in
                    // commit the drag using the gesture’s local translation scaled back
                    let newOffset = offset + (v.translation / scale)

                    // final trash check
                    let finalDist = newOffset.height
                    let threshold = geo.size.height / 2 - 60
                    if finalDist < -threshold {
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

                // Build the styled text view (no transforms or gesture)
                Text(text)
                    .font(font)
                    .if(bold) { $0.bold() }
                    .if(italic) { $0.italic() }
                    .rotation3DEffect(Angle(degrees: rotation3D), axis: (x: 0, y: 1, z: 0))
                    .underline(underline, color: color)
                    .if(stroke) { view in
                        view.glowBorder(color: strokeColor, lineWidth: Int(strokeWidth))
                    }
                    .if(background) { view in
                        view.background(RoundedRectangle(cornerRadius: 4).fill(backgroundColor))
                    }
                    .if(useGradient) { view in
                        view.foregroundStyle(
                            LinearGradient(
                                colors: [gradientStart, gradientEnd],
                                startPoint: gradientX,
                                endPoint: gradientY
                            )
                        )
                    }
                    .if(!useGradient) { view in view.foregroundStyle(color) }
                    .shadow(
                        color: shadowEnabled ? shadowColor : .clear,
                        radius: shadowRadius,
                        x: shadowX,
                        y: shadowY
                    )
                    .if(stroke) { view in
                        view
                            .customeStrok(color: strokeColor, width: strokeWidth)
                    }
                    .modifier(BendEffect(bend: bend))
                    .if(isSelected) { view in
                        view.overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .inset(by: -8)
                                .stroke(style: StrokeStyle(lineWidth: 3, dash: [5]))
                                .foregroundColor(.black)
                        )
                    }

                // Apply transforms and gesture separately
              
                    .rotationEffect(angle + rotΔ, anchor: .center)
                    .scaleEffect((scale * pinchΔ) * (isDeleting ? 0.01 : 1), anchor: .center)
                    .offset(offset + liveDrag)
                    .gesture(isSelected ? combo : nil)

                // Trash bin icon at the top (only when selected & dragging)
                if isSelected && liveDrag != .zero {
                    Image(systemName: "trash")
                    
                        .frame(width: 24, height: 24)
                        .bold()
                        .padding()
                       
                      
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

struct StrokeModifier: ViewModifier {
    var strokeSize: CGFloat = 1
    var strokeColor: Color = .blue

    func body(content: Content) -> some View {
        content
            .padding(strokeSize)
            .background(
                Rectangle()
                    .foregroundStyle(strokeColor)
                    .mask(outline(context: content))
            )
    }

    private func outline(context: Content) -> some View {
        Canvas { context, size in
            context.addFilter(.alphaThreshold(min: 0.01))
            context.drawLayer { layer in
                if let text = context.resolveSymbol(id: UUID()) {
                    layer.draw(text, at: CGPoint(x: size.width / 2, y: size.height / 2))
                }
            }
        } symbols: {
            context.tag(UUID()).blur(radius: strokeSize)
        }
    }
}

extension View {
    func customeStrok(color: Color, width: CGFloat) -> some View {
        self.modifier(StrokeModifier(strokeSize: width, strokeColor: color))
    }
}

/// GeometryEffect for simple text bending

