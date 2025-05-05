//
//  TextControlsView.swift
//  Peekaboo
//
//  Created by Parth Antala on 2025-04-29.
//

import SwiftUI
import UIKit

struct TextControlsView: View {
    @Binding var texts: [TextItem]
    @Binding var selectedTextID: UUID?
    @Binding var showingControls: Bool
    let background: UIImage?
    let exportAction: () -> Void

    private var selectedIndex: Int? {
        guard let id = selectedTextID else { return nil }
        return texts.firstIndex(where: { $0.id == id })
    }
    
    let allFonts: [String] = {
        let playfulFamilies = ["Pacifico", "Chewy", "Fredoka", "Grandstander", "LuckiestGuy", "Bangers", "Caveat", "Lobster", "HennyPenny", "FingerPaint", "Amatic", "Monoton", "SourGummy", "Hurricane"]

        let all = UIFont.familyNames.sorted()
            .flatMap { UIFont.fontNames(forFamilyName: $0).sorted() }
      
        return playfulFamilies + all
    }()
    
    
    @State private var isEditingText: Bool = true
    @State private var showingFontPicker = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var isChoosingColor: Bool = false
    @State private var isShadowing: Bool = false
    @State private var isGlowing: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DottedBackground().ignoresSafeArea()
                VStack(spacing: 16) {
                    
                    Spacer()
                    if let idx = selectedIndex {
                        ZStack {
                            Text(texts[idx].text)
                                .if(texts[idx].stroke) { view in
                                    view.glowBorder(color: texts[idx].strokeColor, lineWidth: Int(texts[idx].strokeWidth))
                                }
                                .multilineTextAlignment(.center)
                            //                        .padding(.horizontal)
                            
                                .font(
                                    texts[idx].fontName == "System"
                                    ? .system(size: texts[idx].textSize)
                                    : .custom(texts[idx].fontName, size: texts[idx].textSize)
                                )
                            // Bold and italic
                                .if(texts[idx].bold)   { $0.bold() }
                                .if(texts[idx].italic) { $0.italic() }
                            // Underline
                                .underline(texts[idx].underline, color: texts[idx].useGradient ? .primary : texts[idx].color)
                            // Background fill
                            
                            // Fill style: gradient or solid
                                .if(texts[idx].useGradient) { view in
                                    view.foregroundStyle(
                                        LinearGradient(
                                            colors: [texts[idx].gradientStart, texts[idx].gradientEnd],
                                            startPoint: texts[idx].gradientX,
                                            endPoint: texts[idx].gradientY
                                        )
                                    )
                                }
                                .if(!texts[idx].useGradient) { view in
                                    view.foregroundStyle(texts[idx].color)
                                }
                            //                        // Shadow
                                .shadow(
                                    color: texts[idx].shadowColor,
                                    radius: texts[idx].shadowRadius,
                                    x: texts[idx].shadowX,
                                    y: texts[idx].shadowY
                                )
                            // White stroke effect if bold, italic, and underline are all enabled
                            
                            //                        // Bend effect
                                .modifier(BendEffect(bend: texts[idx].bend))
                            // Constrain preview size
                                .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100)
                                .padding(.horizontal)
                            
                            
                            
                            TextField("", text: $texts[idx].text)
                                .multilineTextAlignment(.center)
                                .focused($isTextFieldFocused)
                                .onAppear {
                                    isTextFieldFocused = true
                                }
                                .font(
                                    texts[idx].fontName == "System"
                                    ? .system(size: texts[idx].textSize)
                                    : .custom(texts[idx].fontName, size: texts[idx].textSize)
                                )
                                .if(texts[idx].bold)   { $0.bold() }
                                .if(texts[idx].italic) { $0.italic() }
                                .underline(texts[idx].underline, color: texts[idx].color)
                                .foregroundColor(.clear)   // hide its own text
                                .accentColor(.white) // caret color
                        }
                        
                    }
                    
                    Spacer()
                    
                    // Top row of controls
                    HStack {
                        Spacer()
                        Button {
                            withAnimation {
                                isShadowing = false
                                isChoosingColor = false
                                isGlowing = false
                                isEditingText.toggle()
                            }
                        } label: {
                            Image(systemName: "textformat.size")
                                .foregroundStyle(
                                    LinearGradient(colors: [.cyan, .blue], startPoint: .bottomTrailing, endPoint: .topLeading)
                                )
                                .frame(width: 24, height: 24)
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .opacity(isEditingText ? 1 : 0)
                                )
                        }
                        
                        Button {
                            withAnimation {
                                isEditingText = false
                                isShadowing = false
                                isGlowing = false
                                isChoosingColor.toggle()
                            }
                        } label: {
                            Image(systemName: "circle.fill")
                            
                                .foregroundStyle((texts[selectedIndex ?? 0].color))
                                .frame(width: 24, height: 24)
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .opacity(isChoosingColor ? 1 : 0)
                                )
                            
                        }
                        
                        
                        Button {
                            if let idx = selectedIndex {
                                texts[idx].shadowEnabled = true
                            }
                            isEditingText = false
                            isChoosingColor = false
                            isGlowing = false
                            isShadowing = true
                        } label: {
                            Image(systemName: "shadow")
                                .foregroundStyle(
                                    LinearGradient(colors: [.primary, .secondary], startPoint: .bottomTrailing, endPoint: .topLeading)
                                )
                                .frame(width: 24, height: 24)
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .opacity(isShadowing ? 1 : 0)
                                )
                            
                        }
                        
                        Button {
                            isEditingText = false
                            isChoosingColor = false
                            isShadowing = false
                            isGlowing = true
                        } label: {
                            
                            
                            Image(systemName: "textformat.size.smaller")
                                .font(.title)
                                .frame(width: 24, height: 24)
                                .glowBorder(color: .pink, lineWidth: 4)
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .opacity(isGlowing ? 1 : 0)
                                )
                            
                            
                        }
                        Spacer()
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if isEditingText {
                        VStack {
                            HStack {
                                Spacer()
                                Button {
                                    texts[selectedIndex ?? 0].bold.toggle()
                                } label: {
                                    ZStack {
                                        Image(systemName: "bold")
                                            .foregroundStyle(
                                                LinearGradient(colors: [.brown, .primary], startPoint: .bottomTrailing, endPoint: .topLeading)
                                            )
                                            .frame(width: 24, height: 24)
                                            .padding()
                                            .background(.thinMaterial)
                                            .cornerRadius(40)
                                    }
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .opacity(texts[selectedIndex ?? 0].bold ? 1 : 0)
                                    )
                                }
                                Button {
                                    texts[selectedIndex ?? 0].italic.toggle()
                                    
                                } label: {
                                    Image(systemName: "italic")
                                        .foregroundStyle(
                                            LinearGradient(colors: [.pink, .primary], startPoint: .bottomTrailing, endPoint: .topLeading)
                                        )
                                        .frame(width: 24, height: 24)
                                        .padding()
                                        .background(.thinMaterial)
                                        .cornerRadius(40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .opacity(texts[selectedIndex ?? 0].italic ? 1 : 0)
                                        )
                                }
                                Button {
                                    texts[selectedIndex ?? 0].underline.toggle()
                                } label: {
                                    Image(systemName: "underline")
                                        .foregroundStyle(
                                            LinearGradient(colors: [.green, .primary], startPoint: .bottomTrailing, endPoint: .topLeading)
                                        )
                                        .frame(width: 24, height: 24)
                                        .padding()
                                        .background(.thinMaterial)
                                        .cornerRadius(40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .opacity(texts[selectedIndex ?? 0].underline ? 1 : 0)
                                        )
                                }
                                
                                if selectedIndex != nil {
                                    Button {
                                        showingFontPicker = true
                                    } label: {
                                        Image(systemName: "textformat")
                                            .foregroundStyle(
                                                LinearGradient(colors: [.cyan, .blue], startPoint: .bottomTrailing, endPoint: .topLeading)
                                            )
                                            .frame(width: 24, height: 24)
                                            .padding()
                                            .background(.thinMaterial)
                                            .cornerRadius(40)
                                    }
                                }
                                
                                Spacer()
                                
                                
                            }
                            .buttonStyle(PlainButtonStyle())
                            if let idx = selectedIndex {
                                HStack {
                                    
                                    Slider(value: $texts[idx].textSize, in: 8...102)
                                    
                                }
                                .accentColor(.white)
                                .padding()
                            }
                        }
                        
                    }
                    
                    if isChoosingColor, let idx = selectedIndex {
                        VStack(spacing: 12) {
                            // Fill type selector
                            Picker("Fill Type", selection: $texts[idx].useGradient) {
                                Text("Solid").tag(false)
                                Text("Gradient").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            // Color pickers
                            if texts[idx].useGradient {
                                VStack {
                                    HStack {
                                        ForEach([Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple], id: \.self) { preset in
                                            Button {
                                                texts[idx].gradientStart = preset
                                            } label: {
                                                Circle()
                                                    .fill(preset)
                                                    .frame(width: 24, height: 24)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                                    )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        ColorPicker("Start", selection: $texts[idx].gradientStart)
                                            .labelsHidden()
                                            .frame(width: 44, height: 44)
                                    }
                                    HStack {
                                        ForEach([Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple], id: \.self) { preset in
                                            Button {
                                                texts[idx].gradientEnd = preset
                                            } label: {
                                                Circle()
                                                    .fill(preset)
                                                    .frame(width: 24, height: 24)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                                    )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        ColorPicker("End", selection: $texts[idx].gradientEnd)
                                            .labelsHidden()
                                            .frame(width: 44, height: 44)
                                    }
                                    
                                    
                                    // Gradient direction presets
                                    HStack(spacing: 12) {
                                        ForEach([
                                            (UnitPoint.leading, UnitPoint.trailing),
                                            (UnitPoint.bottomLeading, UnitPoint.topTrailing),
                                            (UnitPoint.bottomTrailing, UnitPoint.topLeading),
                                            (UnitPoint.top, UnitPoint.bottom)
                                        ], id: \.0) { start, end in
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [texts[idx].gradientStart, texts[idx].gradientEnd]),
                                                        startPoint: start,
                                                        endPoint: end
                                                    )
                                                )
                                                .frame(width: 44, height: 44)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(
                                                            (texts[idx].gradientX == start && texts[idx].gradientY == end)
                                                            ? texts[idx].gradientStart
                                                            : Color.clear,
                                                            lineWidth: 2
                                                        )
                                                )
                                                .onTapGesture {
                                                    texts[idx].gradientX = start
                                                    texts[idx].gradientY = end
                                                }
                                        }
                                    }
                                    
                                }
                            } else {
                                HStack {
                                    // Preset color buttons
                                    ForEach([Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple], id: \.self) { preset in
                                        Button {
                                            texts[idx].color = preset
                                        } label: {
                                            Circle()
                                                .fill(preset)
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    // Custom color picker
                                    ColorPicker("Color", selection: $texts[idx].color)
                                        .labelsHidden()
                                        .frame(width: 44, height: 44)
                                }
                            }
                        }
                        
                        .animation(.bouncy, value: texts[selectedIndex ?? 0].useGradient)
                        .padding()
                        
                    }
                    
                    if isShadowing, let idx = selectedIndex {
                        HStack {
                            ForEach([Color.clear, Color.black, Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple], id: \.self) { preset in
                                Button {
                                    texts[idx].shadowColor = preset
                                } label: {
                                    ZStack {
                                        // Show a stroked circle for the “clear” preset
                                        Circle()
                                            .stroke(
                                                texts[idx].shadowColor == preset ? Color.primary : Color.secondary.opacity(0.5),
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
                            ColorPicker("Color", selection: $texts[idx].shadowColor)
                                .labelsHidden()
                                .frame(width: 44, height: 44)
                        }
                        HStack {
                            Slider(value: $texts[idx].shadowRadius, in: 0...10)
                        }
                        .accentColor(.white)
                        HStack {
                            Image(systemName: "arrow.up.and.down")
                            Slider(value: $texts[idx].shadowX, in: -20...20)
                            Spacer()
                            Image(systemName: "arrow.up.and.down")
                                .rotationEffect(.init(degrees: 90))
                            Slider(value: $texts[idx].shadowY, in: -20...20)
                        }
                        .accentColor(.white)
                    }
                    
                    
                    if isGlowing, let idx = selectedIndex {
                        HStack {
                            ForEach([Color.clear, Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple], id: \.self) { preset in
                                Button {
                                    texts[idx].strokeColor = preset
                                } label: {
                                    ZStack {
                                        // Show a stroked circle for the “clear” preset
                                        Circle()
                                            .stroke(
                                                texts[idx].strokeColor == preset ? Color.primary : Color.secondary.opacity(0.5),
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
                            ColorPicker("Color", selection: $texts[idx].strokeColor)
                                .labelsHidden()
                                .frame(width: 44, height: 44)
                        }
                        HStack {
                            Slider(value: $texts[idx].strokeWidth, in: 5...15)
                        }
                        .accentColor(.white)
                    }
                    
                    
                    Button {
                        showingControls = false
                    } label: {
                        Text("Done")
                            .font(.system(.title2, design: .rounded))
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.clear, .cyan, .clear], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(22)
                            .shadow(color: .cyan, radius: 10)
                    }
                    .buttonStyle(.plain)
                    .padding()
                    
                    
                }
            }
            .padding()
            .presentationBackground(.ultraThinMaterial)
          
        }
        .sheet(isPresented: $showingFontPicker) {
            FontPickerView(
                selectedFontName: Binding(
                    get: { texts[selectedIndex!].fontName },
                    set: { texts[selectedIndex!].fontName = $0 }
                ),
                fonts: allFonts
            )
            .presentationBackground(.thinMaterial)
        }
        .preferredColorScheme(.dark)
    }
}



struct TextControlsView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State var texts: [TextItem] = [
            TextItem(
                text: "Sample Text",
                isBold: true,
                color: .red,
                offset: .zero,
                scale: 1,
                angle: .zero
            )
        ]
        @State var selectedTextID: UUID? = nil
        @State var showingControls: Bool = true

        var body: some View {
            // Pre-select the first text to show controls
            TextControlsView(
                texts: $texts,
                selectedTextID: $selectedTextID,
                showingControls: $showingControls,
                background: UIImage(systemName: "photo"),
                exportAction: { /* noop */ }
            )
            .onAppear {
                // Select the text after state initialization
                selectedTextID = texts.first?.id
            }
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .preferredColorScheme(.dark)
    }
}



