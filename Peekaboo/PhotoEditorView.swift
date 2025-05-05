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
        
        let margin: CGFloat = 20
        let maxX = renderedW / 2 - rotatedWidth / 2 + margin
        let maxY = renderedH / 2 - rotatedHeight / 2 + margin
        
        clampedX = max(-maxX, min(clampedX, maxX))
        clampedY = max(-maxY, min(clampedY, maxY))
    }
    
    return CGSize(width: clampedX, height: clampedY)
}
import SwiftUI
import PencilKit
import PhotosUI
import Photos
import UIKit
import StoreKit
/// A reusable full-screen dotted pattern background




struct PhotoEditorView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    // Show/hide controls for selected text
    @State private var showingControls: Bool = false
    @State private var subjectAboveText: Bool = false
    @State private var subjectAboveDrawing: Bool = false
    @State private var textInMid: Bool = true
    
    // Drawing state
    @State private var drawingEnabled: Bool = false
    @State private var drawing: PKDrawing = PKDrawing()
    @State private var isFlipping: Bool = false
    @State private var isOpeningSettings: Bool = false
    
   
    
    // MARK: – Image data
    @State private var pickerItem: PhotosPickerItem?
    @State private var background: UIImage?
    @State private var subject:    UIImage?          // lifted foreground
    @State private var OGsubject:    UIImage?          // lifted foreground

    @State private var previewImageSize: CGSize = .zero
    @State private var showStartText: Bool = false
    // MARK: – Text state
    @State private var texts: [TextItem] = []
    
    @State private var selectedTextID: UUID? = nil
    @State private var points: [CGPoint] = []
    @State private var amplitudes: [CGFloat] = []
    @State private var trimEnd: CGFloat = 0
    
    // Brush parameters now driven by state
    @State private var brushColor: Color = .yellow
    @State private var brushWidth: CGFloat = 80
    @State private var amplitude: CGFloat = 100
    
    // Debug toggle
    @State private var showDebug: Bool = false
    @State private var exported = false
  @State private var isEditingSubject = false
    @State private var showBorder: Bool = false
    @StateObject private var appState = AppState.shared
    @State private var isAddingBorder: Bool = false
    @State private var isShowingWall = false
    @State private var isShowingWall1 = false

    @State private var stickerColot: Color = .clear
    @AppStorage("count") private var count = 0
    
    
    init() {
        var titleFont = UIFont.preferredFont(forTextStyle: .largeTitle)
        titleFont = UIFont(
            descriptor: titleFont.fontDescriptor.withDesign(.rounded)?
                .withSymbolicTraits(.traitBold) ?? titleFont.fontDescriptor,
            size: titleFont.pointSize
        )
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: titleFont]
        
    }
    
    //--------------------------------------------------------------------
    // MARK: UI
    //--------------------------------------------------------------------
    var body: some View {
        ZStack {
            // Full-screen dotted background pattern
            DottedBackground()
            
            if background == nil {
                
                GeometryReader { geo in
                    ZStack {
                        
                        
                        // 2) Main stroke
                        ZigzagPath(points: points, amplitudes: amplitudes, amplitude: amplitude)
                            .trim(from: 0, to: trimEnd)
                            .stroke(
                                .secondary, style: StrokeStyle(
                                    lineWidth: brushWidth,
                                    lineCap: .round,
                                    lineJoin: .round
                                ))
                        
                        
                        
                    }
                    .opacity(0.3)
                    .rotationEffect(Angle(degrees: -10))
                    .padding(.bottom, 30)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
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
                            withAnimation(.linear(duration: 2)) {
                                trimEnd = 1
                            }
                        }
                    }
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        VStack(spacing: -20) {
                            Text("Get")
                                .font(.system(size: 50, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            //.padding(.bottom, 115)
                                .bold()
                                .multilineTextAlignment(.center)
                                .shadow(radius: 20)
                            //  .symbolEffect(.pulse)
                            Text("Started")
                                .font(.system(size: 90, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [.blue.opacity(1), .cyan], startPoint: .bottom, endPoint: .top)
                                )
                            
                                .padding(.bottom, UIDevice.isIpad ? 75 : 40)
                                .bold()
                                .shadow(radius: 30)
                                .multilineTextAlignment(.center)
                            
                        }
                    }
                    
                    .rotationEffect(Angle(degrees: -10))
                    .offset(y: showStartText ? 0 : UIScreen.main.bounds.height)
                    .animation(.bouncy(duration: 1.0), value: showStartText)
                    .onAppear { showStartText = true }
                    ZStack {
                        TimelineView(.animation) { timeline in
                            let x = (sin(timeline.date.timeIntervalSince1970) + 1) / 2
                            
                            MeshGradient(width: 3, height: 3, points: [
                                [0, 0], [0.5, 0], [1, 0],
                                [0, 0.5], [Float(x), 0.5], [1, Float(x)],
                                [0, 1], [0.5, 1], [1, 1]
                            ], colors: [
                                .clear, .clear, .cyan,
                                .blue, .cyan, .clear,
                                .clear, .blue, .clear
                            ])
                        }
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.4)
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.4)
                            .cornerRadius(22)
                            .shadow(radius: 10)
                    }
                    .rotationEffect(Angle(degrees: -10))
                    .scaleEffect(1.4)
                    
                    
                    
                    
                }
                .ignoresSafeArea()
                
                
            }
            
            
            // Main image fills the space
            VStack {
                canvas
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 100)
                
            }
            // Bottom toolbar
            if background != nil {
                VStack {
                    
                    if !drawingEnabled {
                        HStack {
                            if !texts.isEmpty {
                                Button {
                                    if !subjectAboveText && textInMid == false {
                                        textInMid = true
                                        
                                    } else if textInMid == true {
                                        subjectAboveText.toggle()
                                        textInMid = false
                                    } else {
                                        subjectAboveText.toggle()
                                    }
                                    HapticManager.shared.impact(style: .medium)
                                    
                                } label: {
                                    Image(systemName: subjectAboveText ? "square.3.layers.3d.top.filled" :
                                            textInMid ? "square.3.layers.3d.middle.filled" : "square.3.layers.3d.bottom.filled")
                                    
                                    .foregroundStyle(
                                        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 24, height: 24)
                                    .bold()
                                    .padding()
                                    .background(.thinMaterial)
                                    .cornerRadius(40)
                                    .shadow(radius: 2)
                                }
                                .padding()

                            }
                            
                            
                            Spacer()
                            Button {
                                if appState.isPremium {
                                    exportImage()

                                } else {
                                    isShowingWall = true
                                }
                            } label: {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .frame(width: 24, height: 24)
                                    .bold()
                                    .padding()
                                    .background(.thinMaterial)
                                    .cornerRadius(40)
                                    .shadow(radius: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                        .padding(.horizontal)
                    }
                    Spacer()
                    
                    
                    if !drawingEnabled {
                        
                        if subject == nil {
                            Text("⚠️ No Layers Found")
                                .font(.system(.title2, design: .rounded))
                                .bold()
                                .foregroundStyle(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(radius: 10)
                                .padding()
                                
                        }
                        
                        
                        HStack {
                            // Draw mode toggle
                            
                            Spacer()
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
                                HapticManager.shared.impact(style: .heavy)
                            } label: {
                                Image(systemName: "textbox")
                                    .foregroundStyle(
                                        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 24, height: 24)
                                    .bold()
                                    .padding()
                                    .background(.thinMaterial)
                                    .cornerRadius(40)
                                    .shadow(radius: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                            // Only show pencil when there is at least one text, one is selected, and controls are hidden
                            
                            Button {
                               // withAnimation {
                                    drawingEnabled.toggle()
                               // }
                                HapticManager.shared.impact(style: .medium)
                                
                            } label: {
                                Image(systemName: "scribble")
                                    .foregroundStyle(
                                        LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 24, height: 24)
                                    .bold()
                                    .padding()
                                    .background(.thinMaterial)
                                    .cornerRadius(40)
                                    .shadow(radius: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            
                            if !texts.isEmpty, selectedTextIndex != nil, !showingControls {
                                Button {
                                    showingControls = true
                                    HapticManager.shared.impact(style: .medium)
                                    
                                } label: {
                                    Image(systemName: "text.cursor")
                                    
                                        .foregroundStyle(
                                            LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .frame(width: 24, height: 24)
                                        .bold()
                                        .padding()
                                        .background(.thinMaterial)
                                        .cornerRadius(40)
                                        .shadow(radius: 2)
                                }
                            }
                            
                            if !texts.isEmpty, selectedTextIndex != nil, !showingControls {
                                Button {
                                    withAnimation {
                                        isEditingSubject = false
                                        isFlipping.toggle()
                                        HapticManager.shared.impact(style: .medium)
                                        
                                    }
                                } label: {
                                    Image(systemName: "flip.horizontal")
                                    
                                        .foregroundStyle(
                                            LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .frame(width: 24, height: 24)
                                        .bold()
                                        .padding()
                                        .background(.thinMaterial)
                                        .cornerRadius(40)
                                        .shadow(radius: 2)
                                }
                            }
                            
                            if subject != nil {
                                Button {
                                    isEditingSubject.toggle()
                                    isFlipping = false
                                } label: {
                                    ZStack(alignment: .center) {
                                        if isAddingBorder {
                                            ProgressView()
                                        } else {
                                            if showBorder {
                                                Image(systemName: colorScheme == .dark ? "smiley" : "smiley.fill")
                                                    .foregroundStyle(stickerColot)
                                                    .scaleEffect(1.2, anchor: .center)
                                            }
                                            Image(systemName: colorScheme == .dark ? "smiley" : "smiley.fill")
                                                .foregroundStyle(
                                                    LinearGradient(colors: [.brown, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                )
                                            
                                        }
                                        
                                    }
                                    
                                    .frame(width: 24, height: 24)
                                    .bold()
                                    .padding()
                                    .background(.thinMaterial)
                                    .cornerRadius(40)
                                    .shadow(radius: 2)
                                }
                                
                            }
                            
                            Spacer()
                            
                        }
                        .padding(.horizontal)
                        
                        if isFlipping {
                            if let idx = selectedTextIndex {
                                
                                RulerSlider(
                                    value: $texts[idx].rotation3D,
                                    range: -50...50,
                                    tickInterval: 2,
                                    majorTickInterval: 10
                                )
                                .frame(height: 60)
                                .padding(.horizontal)
                            }
                        }
                        
                        if isEditingSubject {
                            HStack {
                                ForEach([Color.clear, Color.black, Color.white, Color.red, Color.orange, Color.green, Color.blue], id: \.self) { preset in
                                    Button {
                                       
                                        stickerColot = preset
                                        
                                        // Show loader only when adding border
                                      //  if !showBorder {
                                            isAddingBorder = true
                                    //    }
                                        // Toggle border state
                                        showBorder = true
                                       
                                    } label: {
                                        ZStack {
                                            // Show a stroked circle for the “clear” preset
                                            Circle()
                                                .stroke(
                                                    stickerColot == preset ? Color.primary : Color.secondary.opacity(0.5),
                                                    lineWidth: 1
                                                )
                                                .frame(width: 24, height: 24)
                                            if preset != .clear {
                                                // Solid fill for color presets
                                                Circle()
                                                    .fill(preset)
                                                    .frame(width: 20, height: 20)
                                            } else {
                                                // X mark for clear
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                ColorPicker("Color", selection: $stickerColot)
                                    .labelsHidden()
                                    .frame(width: 44, height: 44)
                            }
                            .onChange(of: stickerColot) {
                                isAddingBorder = true
                                if let sub = OGsubject {
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        let newImage = addWhitePadding(to: sub, borderWidth: stickerColot != Color.clear ? 20 : 0, color: stickerColot)
                                        DispatchQueue.main.async {
                                            subject = newImage
                                            // Hide loader after processing
                                            isAddingBorder = false
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                }
                .frame(maxWidth: .infinity)
              //  .frame(height: UIScreen.main.bounds.height * 0.7)
                .padding(.bottom)
                // .ignoresSafeArea(edges: .top)
            }
        }
       //  .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $isOpeningSettings) {
            SettingsView()
        }
        .sheet(isPresented: $isShowingWall) {
            PayWallView(saving: true) {
                exportImage()
                isShowingWall = false
            }
            .if(!UIDevice.isIpad) { view in
                view.presentationDetents([.fraction(0.8)])

            }
        }
        .sheet(isPresented: $isShowingWall1) {
            PayWallView()
                .if(!UIDevice.isIpad) { view in
                    view.presentationDetents([.fraction(0.8)])

                }
        }
        .fullScreenCover(isPresented: $showingControls) {
            TextControlsView(
                texts: $texts,
                selectedTextID: $selectedTextID,
                showingControls: $showingControls,
                background: background,
                exportAction: exportImage
            )
         
        }
        .navigationTitle(background == nil ? "" : "Peekaboo")
        .toolbar {
            if background != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        HStack {
                            Image(systemName: "plus.arrow.trianglehead.clockwise")
                            //  Text("New")
                            
                        }
                        .font(.system(.title2, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .bottomTrailing, endPoint: .topLeading))
                        .bold()
                        
                    }
                }
            }
//            ToolbarItem(placement: .topBarLeading) {
//                Button {
//                    isOpeningSettings = true
//                } label: {
//                    Image(systemName: "gear")
//                        .font(.title2)
//                        .bold()
//                        .foregroundStyle(
//                            LinearGradient(colors: [.primary, .gray, .gray], startPoint: .bottomTrailing, endPoint: .topLeading)
//                        )
//                }
//                
//            }
            
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    
                    if !appState.isPremium {
                        Button {
                            isShowingWall1 = true
                        } label: {
                            Text("Get Plus")
                        }
                    } else {
                        Text("Peekaboo+")
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }
                    
                    
                    Link(destination: URL(string: "https://itshere.space/PeekabooPrivacy.html")!) {
                        Label("Privacy Policy", systemImage: "shield.lefthalf.filled")
                    }
                        
                        
                      
                    Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                        Label("Terms of Service", systemImage: "doc.append.fill")
                       }
                } label: {
                    Image(systemName: "gear")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(
                            LinearGradient(colors: [.primary, .gray, .gray], startPoint: .bottomTrailing, endPoint: .topLeading)
                        )
                }
                
            }
            
           
                ToolbarItem(placement: .topBarLeading) {
                    if appState.isPremium {
                    Image("ghost")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                        .shadow(color: .yellow.opacity(0.6), radius: 2)
                    
                    
                    
                }
            }
            
        }
        .onChange(of: pickerItem) { _ in loadPhoto() }
        .alert("Saved to Photos!", isPresented: $exported) { }
    }
    
    
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
                            font: textItem.fontName == "System"
                            ? Font.system(size: textItem.textSize)
                            : Font.custom(textItem.fontName, size: textItem.textSize),
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
                            shadowY:        textItem.shadowY,
                            bend:           textItem.bend,
                            textSize: textItem.textSize,
                            stroke: textItem.stroke,
                            strokeColor: textItem.strokeColor,
                            strokeWidth: textItem.strokeWidth,
                            background: textItem.background,
                            backgroundColor: textItem.backgroundColor,
                            gradientX: textItem.gradientX,
                            gradientY: textItem.gradientY,
                            bold: textItem.bold,
                            italic: textItem.italic,
                            underline: textItem.underline,
                            rotation3D: textItem.rotation3D
                        )
                        .frame(width: geo.size.width, height: geo.size.height)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                    
                    if let selectedID = selectedTextID,
                       let selectedIndex = texts.firstIndex(where: { $0.id == selectedID }) {
                        let selectedItem = $texts[selectedIndex]
                        
                        DraggableText(
                            text: selectedItem.wrappedValue.text,
                            font: selectedItem.wrappedValue.fontName == "System"
                            ? Font.system(size: selectedItem.wrappedValue.textSize)
                            : Font.custom(selectedItem.wrappedValue.fontName,
                                          size: selectedItem.wrappedValue.textSize),
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
                            shadowY:        selectedItem.wrappedValue.shadowY,
                            bend:           selectedItem.wrappedValue.bend,
                            textSize: selectedItem.wrappedValue.textSize,
                            stroke: selectedItem.wrappedValue.stroke,
                            strokeColor: selectedItem.wrappedValue.strokeColor,
                            strokeWidth: selectedItem.wrappedValue.strokeWidth,
                            background: selectedItem.wrappedValue.background,
                            backgroundColor: selectedItem.wrappedValue.backgroundColor,
                            gradientX: selectedItem.wrappedValue.gradientX,
                            gradientY: selectedItem.wrappedValue.gradientY,
                            bold: selectedItem.wrappedValue.bold,
                            italic: selectedItem.wrappedValue.italic,
                            underline: selectedItem.wrappedValue.underline,
                            rotation3D: selectedItem.wrappedValue.rotation3D
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
        
                // Drawing layer (only when drawingEnabled)
                
            }
            if subjectAboveText {
                
                if !subjectAboveDrawing {
                    DrawingCanvasView(
                        drawing: $drawing,
                        toolPickerVisible: .constant(drawingEnabled)
                    )
                    .frame(width: previewImageSize.width, height: previewImageSize.height)
                    .allowsHitTesting(drawingEnabled)
                    .zIndex(0)
                    
                    if let fg = subject {
                        Image(uiImage: fg)
                            .resizable()
                            .scaledToFit()
                            .allowsHitTesting(!drawingEnabled)
                    }
                    
                    if background != nil {
                        TextLayerView(texts: $texts, selectedTextID: $selectedTextID, background: background)
                            .allowsHitTesting(!drawingEnabled)
                        
                    }
                    
                    
                } else {
                    if let fg = subject {
                        Image(uiImage: fg)
                            .resizable()
                            .scaledToFit()
                            .allowsHitTesting(!drawingEnabled)
                    }
                    
                    DrawingCanvasView(
                        drawing: $drawing,
                        toolPickerVisible: .constant(drawingEnabled)
                    )
                    .frame(width: previewImageSize.width, height: previewImageSize.height)
                    .allowsHitTesting(drawingEnabled)
                    .zIndex(0)
                    
                    if background != nil {
                        TextLayerView(texts: $texts, selectedTextID: $selectedTextID, background: background)
                            .allowsHitTesting(!drawingEnabled)
                        
                    }
                }
                
                
                
                
                
                
                
            } else {
                
                
                if !subjectAboveDrawing {
                    if textInMid {
                        DrawingCanvasView(
                            drawing: $drawing,
                            toolPickerVisible: .constant(drawingEnabled)
                        )
                        .frame(width: previewImageSize.width, height: previewImageSize.height)
                        .allowsHitTesting(drawingEnabled)
                        .zIndex(0)
                        
                        if background != nil {
                            TextLayerView(texts: $texts, selectedTextID: $selectedTextID, background: background)
                                .allowsHitTesting(!drawingEnabled)
                        }
                        
                        
                        
                    } else {
                        if background != nil {
                            TextLayerView(texts: $texts, selectedTextID: $selectedTextID, background: background)
                                .allowsHitTesting(!drawingEnabled)
                        }
                        
                        
                        DrawingCanvasView(
                            drawing: $drawing,
                            toolPickerVisible: .constant(drawingEnabled)
                        )
                        .frame(width: previewImageSize.width, height: previewImageSize.height)
                        .allowsHitTesting(drawingEnabled)
                        .zIndex(0)
                    }
                    
                    
                    if let fg = subject {
                        Image(uiImage: fg)
                            .resizable()
                            .scaledToFit()
                            .allowsHitTesting(false)
                    }
                } else {
                    if background != nil {
                        TextLayerView(texts: $texts, selectedTextID: $selectedTextID, background: background)
                            .allowsHitTesting(!drawingEnabled)
                    }
                    
                    
                    if let fg = subject {
                        Image(uiImage: fg)
                            .resizable()
                            .scaledToFit()
                            .allowsHitTesting(false)
                    }
                    
                    DrawingCanvasView(
                        drawing: $drawing,
                        toolPickerVisible: .constant(drawingEnabled)
                    )
                    .frame(width: previewImageSize.width, height: previewImageSize.height)
                    .allowsHitTesting(drawingEnabled)
                    .zIndex(0)
                    
                }
            }
            
            // Drawing canvas always in the view hierarchy,
            // interactive only when drawingEnabled == true
            
            // Overlay controls when in draw mode
            if drawingEnabled {
                VStack {
                    HStack(spacing: 12) {
                        
                        Button {
                            if !subjectAboveDrawing && textInMid == false {
                                textInMid = true
                            } else if textInMid == true {
                                subjectAboveDrawing.toggle()
                                textInMid = false
                            } else {
                                subjectAboveDrawing.toggle()
                                
                            }
                            HapticManager.shared.impact(style: .medium)
                        } label: {
                            Image(systemName: subjectAboveDrawing ? "square.3.layers.3d.top.filled" :
                                    textInMid ? "square.3.layers.3d.bottom.filled" : "square.3.layers.3d.middle.filled")
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 24, height: 24)
                            .bold()
                            .padding()
                            .background(.thinMaterial)
                            .cornerRadius(40)
                            .shadow(radius: 2)
                        }
                        
                        Spacer()
                        // Done button
                        Button {
                            drawingEnabled = false
                            HapticManager.shared.notification(type: .success)
                            
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundStyle(
                                    LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 24, height: 24)
                                .bold()
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(40)
                                .shadow(radius: 2)
                            
                        }
                        
                        // Delete button
                        Button {
                            drawing = PKDrawing()
                            HapticManager.shared.notification(type: .success)
                        } label: {
                            Image(systemName: "eraser.line.dashed.fill")
                                .foregroundStyle(
                                    LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 24, height: 24)
                                .bold()
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(40)
                                .shadow(radius: 2)
                            
                        }
                        
                        // Spacer()
                        
                        
                        
                        
                    }
                    .padding(.horizontal)
                    Spacer()
                }
               
                .allowsHitTesting(true)
                .zIndex(1)
            }
        }
        .frame(maxHeight: .infinity)
        // .background(Color.black.opacity(0.05))
    }
    func addWhitePadding(to image: UIImage, borderWidth: CGFloat, color: Color) -> UIImage {
        guard borderWidth > 0, let cgImage = image.cgImage else { return image }
        
        let scale = image.scale
        // Convert pixel dimensions to points
        let widthPt = CGFloat(cgImage.width) / scale
        let heightPt = CGFloat(cgImage.height) / scale
        let padding = borderWidth
        let canvasSize = CGSize(width: widthPt + padding * 2, height: heightPt + padding * 2)
        
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        
        // Disable anti-aliasing and interpolation for a solid edge
        context.setAllowsAntialiasing(false)
        context.interpolationQuality = .none
        
        // Flip coordinate system for CoreGraphics
        context.translateBy(x: 0, y: canvasSize.height)
        context.scaleBy(x: 1, y: -1)
        
        let drawRect = CGRect(x: padding, y: padding, width: widthPt, height: heightPt)
        
        // Draw a solid white border by offsetting the mask at each degree
        for angle in stride(from: 0, to: 360, by: 1) {
            let radians = CGFloat(angle) * .pi / 180
            let dx = cos(radians) * padding
            let dy = sin(radians) * padding
            let offsetRect = drawRect.offsetBy(dx: dx, dy: dy)
            
            context.saveGState()
            context.clip(to: offsetRect, mask: cgImage)
            context.setFillColor(UIColor(color).cgColor)
            context.fill(offsetRect)
            context.restoreGState()
        }
        
        // Draw the original image on top
        context.draw(cgImage, in: drawRect)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        isAddingBorder = false
        return result ?? image
    }
    /// Controls
    func cropToAlphaBounds(image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage,
              let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data else { return image }

        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4

        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * bytesPerPixel
                let alpha = data[pixelIndex + 3]
                if alpha > 10 {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }

        guard minX < maxX, minY < maxY else { return image }

        // Compute the cropping rectangle in pixel coordinates (adjusting for Core Graphics origin)
        let cropRect = CGRect(
            x: minX,
            y: height - maxY,
            width: maxX - minX,
            height: maxY - minY
        )
        // Crop the CGImage to the computed bounds
        guard let croppedCgImage = cgImage.cropping(to: cropRect) else { return image }
        
       
        // Return a new UIImage preserving scale and orientation
        return UIImage(cgImage: croppedCgImage, scale: image.scale, orientation: image.imageOrientation)
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
                
                if let sub = subject {
                   OGsubject = sub
                }
                // reset texts transforms and selection
//                texts = [
//                    TextItem(text: "Your text", isBold: true, color: .white, offset: .zero, scale: 1, angle: .zero)
//                ]
//                selectedTextID = texts.first?.id
            }
        }
    }
    
    // MARK: - Export
   
    // MARK: - Export via SwiftUI snapshot
    private func exportImage() {
        // Ensure we have something to render
        guard background != nil else { return }
        
        // Render the drawing over the full canvas area (matching previewImageSize)
        let fullCanvasRect = CGRect(origin: .zero, size: previewImageSize)
        let drawingImage = drawing.image(from: fullCanvasRect, scale: 1)
        
        // Build the exact view we want to snapshot: no text selected (hides dashed border)
        let exportView = ZStack {
            if let bg = background {
                Image(uiImage: bg)
                    .resizable()
                    .scaledToFit()
                    .frame(width: previewImageSize.width, height: previewImageSize.height)
                    .if(!appState.isPremium) { view in
                        view.overlay(
                            
                            HStack(alignment: .center, spacing: 0) {
                                Image(.ghost2)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 45, height: 45)
                                    .opacity(0.5)

                                Text("Peekaboo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white)
                                    .opacity(0.5)
                                    .padding(8)
                                
                            }
                                .padding(.bottom, 30),
                            alignment: .center
                        )
                        
                    }
                    
            }
            
            if subjectAboveText {
                if !subjectAboveDrawing {
                    Image(uiImage: drawingImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: previewImageSize.width, height: previewImageSize.height)
                    
                    
                    if let fg = subject {
                        Image(uiImage: fg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: previewImageSize.width, height: previewImageSize.height)
                    }
                    TextLayerView(
                        texts: $texts,
                        selectedTextID: .constant(nil),
                        background: background
                    )
                } else {
                    if let fg = subject {
                        Image(uiImage: fg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: previewImageSize.width, height: previewImageSize.height)
                    }
                    
                    Image(uiImage: drawingImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: previewImageSize.width, height: previewImageSize.height)
                    
                    
                    
                    TextLayerView(
                        texts: $texts,
                        selectedTextID: .constant(nil),
                        background: background
                    )
                }
                // Include drawing strokes in the export
                
            } else {
                if !subjectAboveDrawing {
                    if textInMid {
                        Image(uiImage: drawingImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: previewImageSize.width, height: previewImageSize.height)
                        
                        
                        TextLayerView(
                            texts: $texts,
                            selectedTextID: .constant(nil),
                            background: background
                        )
                    } else {
                        
                        
                        TextLayerView(
                            texts: $texts,
                            selectedTextID: .constant(nil),
                            background: background
                        )
                        
                        Image(uiImage: drawingImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: previewImageSize.width, height: previewImageSize.height)
                        
                        
                    }
                    
                    if let fg = subject {
                        Image(uiImage: fg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: previewImageSize.width, height: previewImageSize.height)
                    }
                    
                    
                } else {
                    TextLayerView(
                        texts: $texts,
                        selectedTextID: .constant(nil),
                        background: background
                    )
                    if let fg = subject {
                        Image(uiImage: fg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: previewImageSize.width, height: previewImageSize.height)
                    }
                    
                    Image(uiImage: drawingImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: previewImageSize.width, height: previewImageSize.height)
                    
                    
                }
                // Include drawing strokes in the export
                
                
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
                    DispatchQueue.main.async {
                        exported = success
                        if success {
                            HapticManager.shared.notification(type: .success)
                            
                            count += 1
                          
                            if count == 2 {
                                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    SKStoreReviewController.requestReview(in: scene)
                                } else {
                                    SKStoreReviewController.requestReview()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Convenience
    /// In PhotoEditorView.swift
    private func font(for name: String, size: CGFloat) -> Font {
        if name == "System" {
            return .system(size: size)
        } else {
            return .custom(name, size: size)
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
    
}


#Preview {
    NavigationStack {
        PhotoEditorView()
    }
}

/// A simple warp effect: applies a vertical shear based on `bend`
struct BendEffect: GeometryEffect {
    var bend: CGFloat     // –1…1
    var animatableData: CGFloat {
        get { bend }
        set { bend = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        // Map bend to a vertical shear factor
        let shear = tan(bend * .pi/8)     // adjust π/8 for strength
        let transform = CGAffineTransform(a: 1, b: 0,
                                          c: shear, d: 1,
                                          tx: 0, ty: 0)
        return ProjectionTransform(transform)
    }
}


extension UIDevice {
    static var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
