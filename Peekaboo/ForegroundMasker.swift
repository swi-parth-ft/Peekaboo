import UIKit
import Vision
import CoreImage

// MARK: - Lift the subject (foreground) onto a transparent background
enum ForegroundMasker {

    /// Returns a UIImage whose background is fully transparent, leaving only the main subject.
    static func liftSubject(from uiImage: UIImage) async throws -> UIImage {
        guard let cgImage = uiImage.cgImage else { throw MaskError.invalidInput }

        // 1. Ask Vision for a foreground‐instance mask.
        let request  = VNGenerateForegroundInstanceMaskRequest()
        let handler  = VNImageRequestHandler(cgImage: cgImage,
                                             orientation: CGImagePropertyOrientation(uiImage.imageOrientation))
        try handler.perform([request])

        // 2. CIImages
        guard
            let observation = request.results?.first
        else { throw MaskError.noMask }


        // Vision currently returns a pixel‑buffer; convert it to CGImage.
        let subjectBuffer = try observation.generateMaskedImage(
                                ofInstances: observation.allInstances,
                                from:        handler,
                                croppedToInstancesExtent: false)

        // Vision’s masked pixel buffer is already upright (no EXIF rotation)
        let ciSubject = CIImage(cvPixelBuffer: subjectBuffer)

        guard let subjectCG = CIContext().createCGImage(ciSubject,
                                                        from: ciSubject.extent)
        else { throw MaskError.composeFail }

        // Wrap the pixels with `.up` so SwiftUI won’t rotate them again
        return UIImage(cgImage: subjectCG,
                       scale: uiImage.scale,
                       orientation: .up)
    }

    enum MaskError: Error {
        case invalidInput, noMask, composeFail
    }
}

// MARK: - UIImage ⇆ CGImage orientation helper
private extension CGImagePropertyOrientation {
    init(_ o: UIImage.Orientation) {
        switch o {
        case .up:               self = .up
        case .down:             self = .down
        case .left:             self = .left
        case .right:            self = .right
        case .upMirrored:       self = .upMirrored
        case .downMirrored:     self = .downMirrored
        case .leftMirrored:     self = .leftMirrored
        case .rightMirrored:    self = .rightMirrored
        @unknown default:       self = .up
        }
    }
}
