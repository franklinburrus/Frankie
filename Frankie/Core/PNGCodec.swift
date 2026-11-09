import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
#endif

/// Image buffer helpers. On macOS, encoding/decoding uses ImageIO.
/// Linux cloud verification uses `Tools/run-cloud-fixtures.py`.
public struct RGBAImage: Sendable, Equatable {
    public var width: Int
    public var height: Int
    public var rgba: [UInt8]

    public init(width: Int, height: Int, rgba: [UInt8]) {
        self.width = width
        self.height = height
        self.rgba = rgba
    }

    public static func solid(
        width: Int,
        height: Int,
        r: UInt8,
        g: UInt8,
        b: UInt8,
        a: UInt8 = 255
    ) -> RGBAImage {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for i in stride(from: 0, to: pixels.count, by: 4) {
            pixels[i] = r
            pixels[i + 1] = g
            pixels[i + 2] = b
            pixels[i + 3] = a
        }
        return RGBAImage(width: width, height: height, rgba: pixels)
    }

    public mutating func fill(
        rect: PixelRect,
        r: UInt8,
        g: UInt8,
        b: UInt8,
        a: UInt8 = 255
    ) {
        let x0 = max(0, rect.x)
        let y0 = max(0, rect.y)
        let x1 = min(width, rect.x + rect.width)
        let y1 = min(height, rect.y + rect.height)
        guard x0 < x1, y0 < y1 else { return }
        for y in y0..<y1 {
            for x in x0..<x1 {
                let i = (y * width + x) * 4
                rgba[i] = r
                rgba[i + 1] = g
                rgba[i + 2] = b
                rgba[i + 3] = a
            }
        }
    }

    public mutating func blit(_ source: RGBAImage, into dest: PixelRect) {
        guard dest.width > 0, dest.height > 0 else { return }
        for y in 0..<dest.height {
            let sy = min(source.height - 1, y * source.height / dest.height)
            let dy = dest.y + y
            if dy < 0 || dy >= height { continue }
            for x in 0..<dest.width {
                let sx = min(source.width - 1, x * source.width / dest.width)
                let dx = dest.x + x
                if dx < 0 || dx >= width { continue }
                let si = (sy * source.width + sx) * 4
                let di = (dy * width + dx) * 4
                let alpha = Int(source.rgba[si + 3])
                if alpha == 0 { continue }
                if alpha == 255 {
                    rgba[di] = source.rgba[si]
                    rgba[di + 1] = source.rgba[si + 1]
                    rgba[di + 2] = source.rgba[si + 2]
                    rgba[di + 3] = 255
                } else {
                    let inv = 255 - alpha
                    rgba[di] = UInt8((Int(source.rgba[si]) * alpha + Int(rgba[di]) * inv) / 255)
                    rgba[di + 1] = UInt8((Int(source.rgba[si + 1]) * alpha + Int(rgba[di + 1]) * inv) / 255)
                    rgba[di + 2] = UInt8((Int(source.rgba[si + 2]) * alpha + Int(rgba[di + 2]) * inv) / 255)
                    rgba[di + 3] = 255
                }
            }
        }
    }
}

public struct PixelRect: Sendable, Equatable {
    public var x: Int
    public var y: Int
    public var width: Int
    public var height: Int

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public enum ImageIOBridge {
    public static func loadRGBA(from url: URL) throws -> RGBAImage {
        #if canImport(CoreGraphics)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw FrankieError.generatorFailed("Unable to decode image at \(url.path)")
        }
        return try rgba(from: cgImage)
        #else
        throw FrankieError.generatorFailed(
            "ImageIO unavailable on this platform; use Tools/run-cloud-fixtures.py"
        )
        #endif
    }

    public static func encode(_ image: RGBAImage, format: ExportProfile.ImageFormat) throws -> Data {
        #if canImport(CoreGraphics)
        let cgImage = try cgImage(from: image)
        let data = NSMutableData()
        let type: UTType = format == .png ? .png : .jpeg
        guard let dest = CGImageDestinationCreateWithData(
            data as CFMutableData,
            type.identifier as CFString,
            1,
            nil
        ) else {
            throw FrankieError.generatorFailed("CGImageDestinationCreateWithData failed")
        }
        var props: [CFString: Any] = [:]
        if format == .jpeg {
            props[kCGImageDestinationLossyCompressionQuality] = 0.92
        }
        CGImageDestinationAddImage(dest, cgImage, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw FrankieError.generatorFailed("CGImageDestinationFinalize failed")
        }
        return data as Data
        #else
        // Portable fallback used by unit tests that construct known buffers:
        // write a Frankie-raw container the cloud harness also understands.
        return try FrankieRaw.encode(image)
        #endif
    }

    public static func decodeEncoded(_ data: Data) throws -> RGBAImage {
        #if canImport(CoreGraphics)
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw FrankieError.generatorFailed("Unable to decode encoded image data")
        }
        return try rgba(from: cgImage)
        #else
        return try FrankieRaw.decode(data)
        #endif
    }

    #if canImport(CoreGraphics)
    private static func rgba(from cgImage: CGImage) throws -> RGBAImage {
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw FrankieError.generatorFailed("CGContext create failed")
        }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return RGBAImage(width: width, height: height, rgba: pixels)
    }

    private static func cgImage(from image: RGBAImage) throws -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        var pixels = image.rgba
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let cgImage = CGImage(
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: image.width * 4,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            throw FrankieError.generatorFailed("CGImage create failed")
        }
        return cgImage
    }
    #endif
}

/// Simple portable RGBA container for non-Apple test hosts.
enum FrankieRaw {
    static let magic = Data("FRRAW1\n".utf8)

    static func encode(_ image: RGBAImage) throws -> Data {
        var data = Data()
        data.append(magic)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(image.width).bigEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt32(image.height).bigEndian, Array.init))
        data.append(contentsOf: image.rgba)
        return data
    }

    static func decode(_ data: Data) throws -> RGBAImage {
        guard data.starts(with: magic) else {
            throw FrankieError.generatorFailed("Not a FrankieRaw image")
        }
        let width = Int(data.subdata(in: 7..<11).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })
        let height = Int(data.subdata(in: 11..<15).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })
        let rgba = Array(data.dropFirst(15))
        guard rgba.count == width * height * 4 else {
            throw FrankieError.generatorFailed("FrankieRaw size mismatch")
        }
        return RGBAImage(width: width, height: height, rgba: rgba)
    }
}
