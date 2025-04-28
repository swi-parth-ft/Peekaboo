// Helper: Clamp offset so text stays fully inside rendered image area
private func clampedOffset(for newValue: CGSize, in geoSize: CGSize, background: UIImage?, textItem: TextItem) -> CGSize {
    let nsText = textItem.text as NSString
    let font = UIFont.systemFont(ofSize: 48, weight: textItem.isBold ? .bold : .regular)
    let textSize = nsText.size(withAttributes: [.font: font])

    let scaledWidth = textSize.width * textItem.scale
    let scaledHeight = textSize.height * textItem.scale

    let rad = CGFloat(textItem.angle.radians)
    let cosAngle = abs(cos(rad))
    let sinAngle = abs(sin(rad))
    let rotatedWidth = scaledWidth * cosAngle + scaledHeight * sinAngle
    let rotatedHeight = scaledWidth * sinAngle + scaledHeight * cosAngle

    var clampedX = newValue.width
    var clampedY = newValue.height

    if let bg = background {
        let imgW = bg.size.width
        let imgH = bg.size.height
        let geoW = geoSize.width
        let geoH = geoSize.height
        let scale = min(geoW / imgW, geoH / imgH)
        let renderedW = imgW * scale
        let renderedH = imgH * scale

        let maxX = renderedW / 2 - rotatedWidth / 2
        let maxY = renderedH / 2 - rotatedHeight / 2

        clampedX = max(-maxX, min(clampedX, maxX))
        clampedY = max(-maxY, min(clampedY, maxY))
    }

    return CGSize(width: clampedX, height: clampedY)
}
import SwiftUI
import PhotosUI
import Photos
import UIKit

struct TextItem: Identifiable, Equatable {
let id = UUID()
var text: String
var isBold: Bool
var color: Color
var offset: CGSize
var scale: CGFloat
var angle: Angle
}

struct PhotoEditorView: View {

// MARK: - Text Layer View
private struct TextLayerView: View {
    @Binding var texts: [TextItem]
    @Binding var selectedTextID: UUID?
    var background: UIImage?
    private func rotatedBoundingSize(for textItem: TextItem) -> CGSize {
        let nsText = textItem.text as NSString
        let font = UIFont.systemFont(ofSize: 48, weight: textItem.isBold ? .bold : .regular)
        let textSize = nsText.size(withAttributes: [.font: font])

        let scaledWidth = textSize.width * textItem.scale
        let scaledHeight = textSize.height * textItem.scale

        let rad = CGFloat(textItem.angle.radians)
        let cosAngle = abs(cos(rad))
        let sinAngle = abs(sin(rad))

        let rotatedWidth = scaledWidth * cosAngle + scaledHeight * sinAngle
        let rotatedHeight = scaledWidth * sinAngle + scaledHeight * cosAngle

        return CGSize(width: rotatedWidth, height: rotatedHeight)
    }
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach($texts.filter { $0.id != selectedTextID }) { $textItem in
                    DraggableText(
                        text: textItem.text,
                        font: .system(size: 48, weight: textItem.isBold ? .bold : .regular),
                        color: textItem.color,
                        isSelected: false,
                        offset: Binding(
                            get: { textItem.offset },
                            set: { newValue in
                                textItem.offset = clampedOffset(for: newValue, in: geo.size, background: background, textItem: textItem)
                            }
                        ),
                        scale: $textItem.scale,
                        angle: $textItem.angle,
                        onDelete: nil
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }

                if let selectedID = selectedTextID,
                   let selectedIndex = texts.firstIndex(where: { $0.id == selectedID }) {
                    let selectedItem = $texts[selectedIndex]

                    DraggableText(
                        text: selectedItem.wrappedValue.text,
                        font: .system(size: 48, weight: selectedItem.wrappedValue.isBold ? .bold : .regular),
                        color: selectedItem.wrappedValue.color,
                        isSelected: true,
                        offset: Binding(
                            get: { selectedItem.wrappedValue.offset },
                            set: { newValue in
                                selectedItem.wrappedValue.offset = clampedOffset(for: newValue, in: geo.size, background: background, textItem: selectedItem.wrappedValue)
                            }
                        ),
                        scale: selectedItem.scale,
                        angle: selectedItem.angle,
                        onDelete: {
                            if let idx = texts.firstIndex(where: { $0.id == selectedID }) {
                                texts.remove(at: idx)
                                selectedTextID = nil
                            }
                        }
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                // Draw selected text on top, maintaining correct bindings for drag/scale/rotate
//                ForEach($texts) { $textItem in
//                    DraggableText(
//                        text: textItem.text,
//                        font: .system(size: 48, weight: textItem.isBold ? .bold : .regular),
//                        color: textItem.color,
//                        isSelected: textItem.id == selectedTextID,
//                        offset: Binding(
//                            get: { textItem.offset },
//                            set: { newValue in
//                                textItem.offset = clampedOffset(for: newValue, in: geo.size, background: background, textItem: textItem)
//                            }
//                        ),
//                        scale: $textItem.scale,
//                        angle: $textItem.angle
//                    )
//                    .frame(width: geo.size.width, height: geo.size.height)
//                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
//                    .id(textItem.id == selectedTextID) // 👈 ADD THIS
//                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let tapPoint = CGPoint(x: location.x - center.x, y: location.y - center.y)

                var nearestID: UUID? = nil
                var nearestDistance = CGFloat.greatestFiniteMagnitude
                let threshold: CGFloat = 100

                for textItem in texts {
                    let rotatedSize = rotatedBoundingSize(for: textItem)

                    let dx = tapPoint.x - textItem.offset.width
                    let dy = tapPoint.y - textItem.offset.height

                    let withinX = abs(dx) <= rotatedSize.width / 2 + threshold
                    let withinY = abs(dy) <= rotatedSize.height / 2 + threshold

                    if withinX && withinY {
                        let dist = sqrt(dx * dx + dy * dy)
                        if dist < nearestDistance {
                            nearestDistance = dist
                            nearestID = textItem.id
                        }
                    }
                }

                if let nearest = nearestID {
                    selectedTextID = nearest
                }
            }
        }
    }
}

// MARK: – Image data
@State private var pickerItem: PhotosPickerItem?
@State private var background: UIImage?
@State private var subject:    UIImage?          // lifted foreground
    @State private var previewImageSize: CGSize = .zero
// MARK: – Text state
@State private var texts: [TextItem] = [
    TextItem(text: "Your text", isBold: true, color: .white, offset: .zero, scale: 1, angle: .zero)
]
@State private var selectedTextID: UUID? = nil

// Convenience
private func font(for textItem: TextItem) -> Font {
    .system(size: 48, weight: textItem.isBold ? .bold : .regular)
}

private var selectedTextIndex: Int? {
    guard let id = selectedTextID else { return nil }
    return texts.firstIndex(where: { $0.id == id })
}

// Helper: Calculate rotated bounding box size for a TextItem
private func rotatedBoundingSize(for textItem: TextItem) -> CGSize {
    let nsText = textItem.text as NSString
    let font = UIFont.systemFont(ofSize: 48, weight: textItem.isBold ? .bold : .regular)
    let textSize = nsText.size(withAttributes: [.font: font])

    let scaledWidth = textSize.width * textItem.scale
    let scaledHeight = textSize.height * textItem.scale

    let rad = CGFloat(textItem.angle.radians)
    let cosAngle = abs(cos(rad))
    let sinAngle = abs(sin(rad))

    let rotatedWidth = scaledWidth * cosAngle + scaledHeight * sinAngle
    let rotatedHeight = scaledWidth * sinAngle + scaledHeight * cosAngle

    return CGSize(width: rotatedWidth, height: rotatedHeight)
}

//--------------------------------------------------------------------
// MARK: UI
//--------------------------------------------------------------------
var body: some View {
    VStack {
        canvas
        controlBar
    }
    .navigationTitle("Peekaboo")
    .toolbar {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            Label("Pick", systemImage: "photo")
        }
    }
    .onChange(of: pickerItem) { _ in loadPhoto() }
    .alert("Saved to Photos!", isPresented: $exported) { }
}

/// Live preview
private var canvas: some View {
    ZStack {
        if let bg = background {
            Image(uiImage: bg)
                .resizable()
                .scaledToFit()
                .background(
                    GeometryReader { imgGeo in
                        Color.clear
                            .onAppear { previewImageSize = imgGeo.size }
                            .onChange(of: imgGeo.size) { previewImageSize = $0 }
                    }
                )
                .allowsHitTesting(false)
        }

        if background != nil {
            TextLayerView(texts: $texts, selectedTextID: $selectedTextID, background: background)
        }

        if let fg = subject {
            Image(uiImage: fg)
                .resizable()
                .scaledToFit()
                .allowsHitTesting(false)
        }
    }
    .frame(maxHeight: .infinity)
    .background(Color.black.opacity(0.05))
}

/// Controls
private var controlBar: some View {
    VStack(spacing: 12) {
        // New Text button at the top of the control bar
        Button(action: {
            // Add a new text overlay and select it
            let newItem = TextItem(text: "New text", isBold: false, color: .white, offset: .zero, scale: 1, angle: .zero)
            texts.append(newItem)
            selectedTextID = newItem.id
        }) {
            Label("New Text", systemImage: "plus")
                .font(.headline)
        }
        if let selectedIndex = selectedTextIndex {
            TextField("Overlay text", text: $texts[selectedIndex].text)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Aa") { texts[selectedIndex].isBold.toggle() }
                ColorPicker("", selection: $texts[selectedIndex].color).labelsHidden()
                Spacer()
                Button("Export") { exportImage() }
                    .disabled(background == nil)
            }
        } else {
            TextField("Overlay text", text: .constant(""))
                .textFieldStyle(.roundedBorder)
                .disabled(true)
            
            HStack {
                Button("Aa") { }
                    .disabled(true)
                ColorPicker("", selection: .constant(.white)).labelsHidden().disabled(true)
                Spacer()
                Button("Export") { exportImage() }
                    .disabled(background == nil)
            }
        }
    }
    .padding()
}

//--------------------------------------------------------------------
// MARK: Load photo & lift subject
//--------------------------------------------------------------------
private func loadPhoto() {
    guard let pickerItem else { return }
    Task {
        if let data = try? await pickerItem.loadTransferable(type: Data.self),
           let uiImg = UIImage(data: data) {
            background = uiImg
            subject    = try? await ForegroundMasker.liftSubject(from: uiImg)
            // reset texts transforms and selection
            texts = [
                TextItem(text: "Your text", isBold: true, color: .white, offset: .zero, scale: 1, angle: .zero)
            ]
            selectedTextID = texts.first?.id
        }
    }
}

// MARK: - Export
@State private var exported = false
    private func exportImage() {
        guard let bg = background else { return }

        // 1. Compute points→pixels from the real preview size
        let pts2px: CGFloat = previewImageSize.width > 0
            ? bg.size.width / previewImageSize.width
            : 1

        // 2. Cap output resolution to avoid OOM (max 2048 px on long edge)
        let maxDim: CGFloat = 2048
        let outScale = min(1, maxDim / max(bg.size.width, bg.size.height))
        let renderSize = CGSize(
            width: bg.size.width * outScale,
            height: bg.size.height * outScale
        )

        let img = UIGraphicsImageRenderer(size: renderSize).image { ctx in
            // Down-scale once at the end
            ctx.cgContext.scaleBy(x: outScale, y: outScale)

            // ── Draw background ──────────────────────────
            bg.draw(in: CGRect(origin: .zero, size: bg.size))

            // ── Draw every textItem ──────────────────────
            let centre = CGPoint(x: bg.size.width/2, y: bg.size.height/2)
            for item in texts {
                ctx.cgContext.saveGState()

                // Convert your SwiftUI offset into image pixels
                let offPx = CGPoint(
                    x: item.offset.width  * pts2px,
                    y: item.offset.height * pts2px
                )
                let rad = CGFloat(item.angle.radians)

                // Move to the final text center: image center + offset (unaffected by rotation)
                ctx.cgContext.translateBy(x: centre.x + offPx.x,
                                          y: centre.y + offPx.y)
                // Apply rotation then scale around the text center
                ctx.cgContext.rotate(by: rad)
                ctx.cgContext.scaleBy(x: item.scale, y: item.scale)

                // Draw the text centered around (0,0)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(
                        ofSize: 48 * pts2px,
                        weight: item.isBold ? .bold : .regular
                    ),
                    .foregroundColor: UIColor(item.color)
                ]
                let ns = item.text as NSString
                let sz = ns.size(withAttributes: attrs)
                ns.draw(
                    at: CGPoint(x: -sz.width/2, y: -sz.height/2),
                    withAttributes: attrs
                )

                ctx.cgContext.restoreGState()
            }

            // ── Draw lifted subject on top ───────────────
            if let fg = subject {
                fg.draw(in: CGRect(origin: .zero, size: bg.size))
            }
        }

        // 3. Save to Photos
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: img)
            } completionHandler: { success, _ in
                DispatchQueue.main.async { exported = success }
            }
        }
    }



}


#Preview {
NavigationStack {
    PhotoEditorView()
}
}

