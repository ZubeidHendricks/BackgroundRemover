import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

enum BGError: Error { case badImage, noSubject }

struct BGOption: Identifiable, Hashable {
    let id: String
    let name: String
    let color: UIColor?     // nil = transparent
    let isPremium: Bool

    static let all: [BGOption] = [
        .init(id: "clear", name: "Transparent", color: nil, isPremium: false),
        .init(id: "white", name: "White", color: .white, isPremium: false),
        .init(id: "black", name: "Black", color: .black, isPremium: true),
        .init(id: "blue", name: "Studio Blue", color: UIColor(red: 0.16, green: 0.36, blue: 0.7, alpha: 1), isPremium: true),
        .init(id: "green", name: "Chroma", color: UIColor(red: 0.0, green: 0.7, blue: 0.25, alpha: 1), isPremium: true),
    ]
}

/// Subject lifting via Vision's foreground-instance mask (iOS 17+). Works on any
/// salient subject, not just people. Fully on-device.
struct BackgroundRemoverService {
    private let context = CIContext()

    func removeBackground(from image: UIImage, option: BGOption) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            try Self.render(image: image, option: option, context: context)
        }.value
    }

    private static func render(image: UIImage, option: BGOption, context: CIContext) throws -> UIImage {
        guard let cg = image.normalizedUp().cgImage else { throw BGError.badImage }
        let input = CIImage(cgImage: cg)
        let extent = input.extent

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        try handler.perform([request])
        guard let result = request.results?.first else { throw BGError.noSubject }
        let maskBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
        var mask = CIImage(cvPixelBuffer: maskBuffer)
        mask = mask.transformed(by: CGAffineTransform(
            scaleX: extent.width / mask.extent.width,
            y: extent.height / mask.extent.height))

        let background: CIImage
        if let color = option.color {
            background = CIImage(color: CIColor(color: color)).cropped(to: extent)
        } else {
            background = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0)).cropped(to: extent)
        }

        let blend = CIFilter.blendWithMask()
        blend.inputImage = input
        blend.backgroundImage = background
        blend.maskImage = mask
        guard let output = blend.outputImage,
              let out = context.createCGImage(output, from: extent, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB()) else {
            throw BGError.badImage
        }
        return UIImage(cgImage: out)
    }
}

extension UIImage {
    func normalizedUp() -> UIImage {
        if imageOrientation == .up { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// PNG data preserving transparency.
    func pngForExport() -> Data? { pngData() }
}
