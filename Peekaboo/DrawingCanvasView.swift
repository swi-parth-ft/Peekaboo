//
//  DrawingCanvasView.swift
//  Peekaboo
//
//  Created by Parth Antala on 2025-04-29.
//


import SwiftUI
import PencilKit

/// A SwiftUI view wrapping PKCanvasView for freehand drawing with Apple Pencil or finger.
struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var toolPickerVisible: Bool

    private let canvasView = PKCanvasView()
    private let toolPicker = PKToolPicker()

    func makeUIView(context: Context) -> PKCanvasView {
        // Configure canvas
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = .clear

        // Configure tool picker
        toolPicker.setVisible(toolPickerVisible, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        if toolPickerVisible {
            canvasView.becomeFirstResponder()
        }
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Sync drawing state
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        // Show/hide tool picker
        toolPicker.setVisible(toolPickerVisible, forFirstResponder: uiView)
        toolPicker.addObserver(uiView)
        if toolPickerVisible {
            uiView.becomeFirstResponder()
        } else {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var drawing: Binding<PKDrawing>
        init(drawing: Binding<PKDrawing>) {
            self.drawing = drawing
        }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            DispatchQueue.main.async {
                self.drawing.wrappedValue = canvasView.drawing
            }
        }
    }
}

/// The main drawing screen: canvas + toolbar actions (clear, save, share, toggle tool picker)
struct DrawingView: View {
    @State private var drawing = PKDrawing()
    @State private var toolPickerVisible = true
    @State private var showShareSheet = false
    @State private var showSaveAlert = false
    @State private var shareImage: Image?

    var body: some View {
        NavigationStack {
            ZStack {
                // White background
               
                // Canvas layer
                DrawingCanvasView(
                    drawing: $drawing,
                    toolPickerVisible: $toolPickerVisible
                )
                .gesture(
                    // Single tap hides keyboard/tool if needed
                    TapGesture().onEnded { _ in
                        toolPickerVisible = false
                    }
                )
            }
            .navigationTitle("Draw")
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: { drawing = PKDrawing() }) {
                        Image(systemName: "trash")
                    }
                    Spacer()
                    Button(action: { toolPickerVisible.toggle() }) {
                        Image(systemName: toolPickerVisible ? "wand.and.rays" : "wand.and.rays.inverse")
                    }
                    Spacer()
                    Button(action: saveToPhotos) {
                        Image(systemName: "arrow.down.to.line")
                    }
                    Spacer()
                    Button(action: shareDrawing) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareImage = shareImage {
                    ShareLink(item: shareImage, preview: SharePreview("My Drawing", image: shareImage)) { }
                }
            }
            .alert("Saved!", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func saveToPhotos() {
        let uiImage = drawing.image(from: drawing.bounds, scale: 1)
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        showSaveAlert = true
    }

    private func shareDrawing() {
        let uiImage = drawing.image(from: drawing.bounds, scale: 1)
        shareImage = Image(uiImage: uiImage)
        showShareSheet = true
    }
}

#if DEBUG
struct DrawingView_Previews: PreviewProvider {
    static var previews: some View {
        DrawingView()
    }
}
#endif
