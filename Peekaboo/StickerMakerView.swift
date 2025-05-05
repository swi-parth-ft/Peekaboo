//
//  StickerMakerView.swift
//  Peekaboo
//
//  Created by Parth Antala on 2025-05-01.
//


import SwiftUI
import PhotosUI

struct StickerMakerView: View {
    @State private var selectedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var showPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showBorder: Bool = true

    var body: some View {
        VStack(spacing: 20) {
            if let processedImage {
                Image(uiImage: processedImage)
                    .resizable()
                    .scaledToFit()
                    .background(.red)
                    .onTapGesture {
                        showBorder.toggle()
                        Task {
                            await processImage()
                        }
                    }
            } else {
                Text("Pick an image to make a sticker")
                    .foregroundColor(.gray)
            }

          
        }
        PhotosPicker("Sticker", selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { newItem in
                guard let newItem else { return }
                Task {
                    do {
                        if let data = try await newItem.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                            isProcessing = true
                            await processImage()
                        }
                    } catch {
                        print("Failed to load image: \(error)")
                    }
                }
            }
    }
    
    

    func processImage() async {
        guard let image = selectedImage else { return }
        do {
            let masked = try await ForegroundMasker.liftSubject(from: image)
            let cropped = cropToAlphaBounds(image: masked)
            let sticker = addWhitePadding(to: cropped, borderWidth: showBorder ? 20 : 0)
            processedImage = sticker
        } catch {
            print("Masking failed: \(error)")
        }
        isProcessing = false
    }

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

        let cropRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        if let croppedCgImage = cgImage.cropping(to: cropRect) {
            return UIImage(cgImage: croppedCgImage, scale: image.scale, orientation: image.imageOrientation)
        }

        return image
    }

    func addWhitePadding(to image: UIImage, borderWidth: CGFloat) -> UIImage {
        let padding: CGFloat = 60
        let outlineWidth = borderWidth
        let size = CGSize(width: image.size.width + padding * 2,
                          height: image.size.height + padding * 2)

        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext(),
              let cgImage = image.cgImage else {
            return image
        }

        let drawRect = CGRect(x: padding, y: padding, width: image.size.width, height: image.size.height)

        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // Draw solid white outline by repeatedly filling white where the alpha exists
        for angle in stride(from: 0, to: 360, by: 10) {
            let radians = CGFloat(angle) * .pi / 180
            let dx = cos(radians) * outlineWidth
            let dy = sin(radians) * outlineWidth
            let offsetRect = drawRect.offsetBy(dx: dx, dy: dy)

            context.saveGState()
            context.clip(to: offsetRect, mask: cgImage) // use image alpha as clip
            context.setFillColor(UIColor.white.cgColor)
            context.fill(offsetRect)
            context.restoreGState()
        }

        // Draw original image on top
        context.draw(cgImage, in: drawRect)

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result ?? image
    }
    
}


#Preview {
    StickerMakerView()
}
