import UIKit

enum ImageTools {
    /// Screenshot for the server: max 1280 px long edge, JPEG ~0.7, under 1.5 MB.
    static func uploadJPEG(from image: UIImage) -> Data? {
        let resized = downscale(image, maxEdge: 1280)
        var quality: CGFloat = 0.7
        var data = resized.jpegData(compressionQuality: quality)
        while let d = data, d.count > 1_500_000, quality > 0.3 {
            quality -= 0.1
            data = resized.jpegData(compressionQuality: quality)
        }
        return data
    }

    /// Small preview kept in local history.
    static func thumbnail(from image: UIImage) -> Data? {
        downscale(image, maxEdge: 320).jpegData(compressionQuality: 0.6)
    }

    static func downscale(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxEdge else { return redraw(image, size: size) }
        let scale = maxEdge / longest
        return redraw(image, size: CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded()))
    }

    private static func redraw(_ image: UIImage, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
