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

/// A reusable full-screen dotted pattern background
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
    var gradientStart: Color = .white
    var gradientEnd:   Color = .white
    var shadowEnabled: Bool = false
    var shadowColor:   Color = .black
    var shadowRadius:  CGFloat = 3
    var shadowX:       CGFloat = 0
    var shadowY:       CGFloat = 0
}

struct PhotoEditorView: View {

@Environment(\.colorScheme) var colorScheme

// Show/hide controls for selected text
@State private var showingControls: Bool = false

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
                        onDelete: nil,
                        useGradient:    textItem.useGradient,
                        gradientStart:  textItem.gradientStart,
                        gradientEnd:    textItem.gradientEnd,
                        shadowEnabled:  textItem.shadowEnabled,
                        shadowColor:    textItem.shadowColor,
                        shadowRadius:   textItem.shadowRadius,
                        shadowX:        textItem.shadowX,
                        shadowY:        textItem.shadowY
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
                        },
                        useGradient:    selectedItem.wrappedValue.useGradient,
                        gradientStart:  selectedItem.wrappedValue.gradientStart,
                        gradientEnd:    selectedItem.wrappedValue.gradientEnd,
                        shadowEnabled:  selectedItem.wrappedValue.shadowEnabled,
                        shadowColor:    selectedItem.wrappedValue.shadowColor,
                        shadowRadius:   selectedItem.wrappedValue.shadowRadius,
                        shadowX:        selectedItem.wrappedValue.shadowX,
                        shadowY:        selectedItem.wrappedValue.shadowY
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }

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

                // Select the nearest text, or clear selection if none
                selectedTextID = nearestID
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
    if textItem.fontName == "System" {
        return .system(size: 48, weight: textItem.isBold ? .bold : .regular)
    } else {
        return .custom(textItem.fontName, size: 48)
    }
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
    ZStack {
        // Full-screen dotted background pattern
        DottedBackground()
        
        if background == nil {
            VStack {
                
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 75))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .shadow(radius: 10)
                }
                Text("Select an Image")
                    .font(.system(.title, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.bottom, 20)
                    .bold()
                    .multilineTextAlignment(.center)
                    .shadow(radius: 10)

            }
            .padding(.bottom, 100)


        }
           
        
        // Main image fills the space
        canvas
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 100)
        // Bottom toolbar
     //   if background != nil {
            VStack {
                Spacer()
                HStack {
                    // Spacer()
                    Button {
                        // add & select new text
                        let newItem = TextItem(text: "New text",
                                               isBold: false,
                                               color: .white,
                                               offset: .zero,
                                               scale: 1,
                                               angle: .zero)
                        texts.append(newItem)
                        selectedTextID = newItem.id
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .bold()
                            .padding(18)
                            .background(.ultraThinMaterial, in: Circle())
                            .shadow(radius: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    if selectedTextIndex != nil {
                        if !showingControls {
                            Button {
                                showingControls = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.title)
                                    .bold()
                                    .foregroundStyle(.green)
                                    .padding(18)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .shadow(radius: 2)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        exportImage()
                    } label: {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.title)
                            .bold()
                            .padding(18)
                            .background(.ultraThinMaterial, in: Circle())
                            .shadow(radius: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
      //  }
    }
    .sheet(isPresented: $showingControls) {
        controlBar
            .presentationBackground(.ultraThinMaterial)
    }
    .navigationTitle("Peekaboo")
    .toolbar {
        if background != nil {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text("Start New")
                    .font(.system(.title2, design: .rounded))
                    .bold()
                    .shadow(radius: 2)
            }
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
                .shadow(radius: 20)
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
   // .background(Color.black.opacity(0.05))
}

/// Controls
private var controlBar: some View {
    NavigationStack {
        ZStack {
            VStack {
                Spacer()
                HStack {
                    
                 
                    
                    if let selectedIndex = selectedTextIndex {
                        TextField("Overlay text", text: $texts[selectedTextIndex ?? 0].text)
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
                        
                    }
                }
                
                HStack {
                    Button {
                       
                    } label: {
                        Image(systemName: "textformat.size")
                            .font(.title)
                            .bold()
                            .padding(18)
                            .background(.ultraThinMaterial, in: Circle())
                            .shadow(radius: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    ZStack {
                        Image(systemName: "plus")
                            .foregroundColor(.white.opacity(0))
                            .font(.title)
                            .bold()
                            .padding(18)
                            .background(.ultraThinMaterial, in: Circle())
                            .shadow(radius: 2)
                        ColorPicker("", selection: $texts[selectedTextIndex ?? 0].color)
                            .labelsHidden()
                        
                            .frame(width: 44, height: 44)
                        
                    }
                    Button {
                        texts[selectedTextIndex ?? 0].shadowEnabled.toggle()
                    } label: {
                        Image(systemName: "shadow")
                            .font(.title)
                            .bold()
                            .padding(18)
                            .background(.ultraThinMaterial, in: Circle())
                            .shadow(radius: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if let selectedIndex = selectedTextIndex {
                    HStack {
                        // Font toggle and selection
                        Button("Aa") { texts[selectedIndex].isBold.toggle() }
                        Menu(texts[selectedIndex].fontName) {
                            Button("System") { texts[selectedIndex].fontName = "System" }
                            Button("Helvetica") { texts[selectedIndex].fontName = "Helvetica" }
                            Button("Courier") { texts[selectedIndex].fontName = "Courier" }
                            // add other fonts as desired
                        }
                        // Fill color or gradient
                        Toggle("Gradient", isOn: $texts[selectedIndex].useGradient)
                        if texts[selectedIndex].useGradient {
                            ColorPicker("Start", selection: $texts[selectedIndex].gradientStart)
                            ColorPicker("End",   selection: $texts[selectedIndex].gradientEnd)
                        } else {
                            ColorPicker("", selection: $texts[selectedIndex].color).labelsHidden()
                        }
                        Spacer()
                        Button("Export") { exportImage() }
                            .disabled(background == nil)
                    }
                    // Shadow controls
                    Toggle("Shadow", isOn: $texts[selectedIndex].shadowEnabled)
                    if texts[selectedIndex].shadowEnabled {
                        ColorPicker("Shadow Color", selection: $texts[selectedIndex].shadowColor)
                        HStack {
                            Text("Radius"); Slider(value: $texts[selectedIndex].shadowRadius, in: 0...10)
                        }
                        HStack {
                            Text("X"); Slider(value: $texts[selectedIndex].shadowX, in: -20...20)
                        }
                        HStack {
                            Text("Y"); Slider(value: $texts[selectedIndex].shadowY, in: -20...20)
                        }
                    }
                } else {
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
            
            .cornerRadius(22)
        }
      //  .navigationTitle("Edit")
        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingControls = false
                } label: {
                    Text("Done")
                        .font(.system(.title2, design: .rounded))
                        .bold()
                    
                }
            }
        }
        
    }
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
// MARK: - Export via SwiftUI snapshot
private func exportImage() {
    // Ensure we have something to render
    guard background != nil else { return }

    // Build the exact view we want to snapshot
    // Build the exact view to snapshot: no text selected (hides dashed border)
    let exportView = ZStack {
        if let bg = background {
            Image(uiImage: bg)
                .resizable()
                .scaledToFit()
        }
        TextLayerView(
            texts: $texts,
            selectedTextID: .constant(nil),
            background: background
        )
        if let fg = subject {
            Image(uiImage: fg)
                .resizable()
                .scaledToFit()
        }
    }
    .frame(
        width: previewImageSize.width,
        height: previewImageSize.height
    )
    .background(Color.clear)
    

    // Use SwiftUI's ImageRenderer to capture it
    let renderer = ImageRenderer(content: exportView)
    renderer.scale = UIScreen.main.scale

    // Retrieve the UIImage and save it
    if let uiImage = renderer.uiImage {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
            } completionHandler: { success, _ in
                DispatchQueue.main.async { exported = success }
            }
        }
    }
}



}


#Preview {
NavigationStack {
    PhotoEditorView()
}
}

