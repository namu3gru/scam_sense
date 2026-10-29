// Draws the ScamSense app icon (1024x1024, no alpha): a white shield on a deep-blue gradient
// holding a traffic light (red / amber / green). Run: swift design/make_icon.swift <out.png>
import AppKit
import CoreGraphics

let size = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

// Flip so y grows downward (easier to reason about).
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: 1, y: -1)

// Background gradient
let bg = CGGradient(colorsSpace: cs, colors: [color(0x0C1440), color(0x1E3A9E), color(0x3866FF)] as CFArray,
                    locations: [0, 0.55, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 1024, y: 1024), options: [])

// Soft radar rings
ctx.setLineWidth(10)
for (i, r) in [300.0, 410.0, 520.0].enumerated() {
    ctx.setStrokeColor(color(0xFFFFFF, 0.07 - CGFloat(i) * 0.015))
    ctx.strokeEllipse(in: CGRect(x: 512 - r, y: 520 - r, width: r * 2, height: r * 2))
}

// Shield path
func shield(_ r: CGRect) -> CGPath {
    let p = CGMutablePath()
    let w = r.width, h = r.height
    p.move(to: CGPoint(x: r.minX + w * 0.5, y: r.minY))
    p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.14),
               control1: CGPoint(x: r.minX + w * 0.68, y: r.minY + h * 0.09),
               control2: CGPoint(x: r.minX + w * 0.86, y: r.minY + h * 0.12))
    p.addCurve(to: CGPoint(x: r.minX + w * 0.5, y: r.maxY),
               control1: CGPoint(x: r.maxX, y: r.minY + h * 0.58),
               control2: CGPoint(x: r.minX + w * 0.8, y: r.minY + h * 0.86))
    p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.14),
               control1: CGPoint(x: r.minX + w * 0.2, y: r.minY + h * 0.86),
               control2: CGPoint(x: r.minX, y: r.minY + h * 0.58))
    p.addCurve(to: CGPoint(x: r.minX + w * 0.5, y: r.minY),
               control1: CGPoint(x: r.minX + w * 0.14, y: r.minY + h * 0.12),
               control2: CGPoint(x: r.minX + w * 0.32, y: r.minY + h * 0.09))
    p.closeSubpath()
    return p
}

let shieldRect = CGRect(x: 512 - 318, y: 150, width: 636, height: 730)
// Shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 26), blur: 60, color: color(0x000000, 0.4))
ctx.addPath(shield(shieldRect))
ctx.setFillColor(color(0xFFFFFF))
ctx.fillPath()
ctx.restoreGState()
// Shield subtle gradient
ctx.saveGState()
ctx.addPath(shield(shieldRect))
ctx.clip()
let sg = CGGradient(colorsSpace: cs, colors: [color(0xFFFFFF), color(0xE3E9FB)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(sg, start: CGPoint(x: 512, y: 150), end: CGPoint(x: 512, y: 880), options: [])
ctx.restoreGState()

// Traffic light housing
let housing = CGRect(x: 512 - 104, y: 270, width: 208, height: 454)
ctx.addPath(CGPath(roundedRect: housing, cornerWidth: 112, cornerHeight: 112, transform: nil))
ctx.setFillColor(color(0x121A44))
ctx.fillPath()

// Lights with glow
let lights: [(UInt32, CGFloat)] = [(0xFF4D3D, 360), (0xFFB020, 497), (0x2BD47D, 634)]
for (hex, cy) in lights {
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 46, color: color(hex, 0.85))
    ctx.setFillColor(color(hex))
    ctx.fillEllipse(in: CGRect(x: 512 - 62, y: cy - 62, width: 124, height: 124))
    ctx.restoreGState()
    // highlight
    ctx.setFillColor(color(0xFFFFFF, 0.35))
    ctx.fillEllipse(in: CGRect(x: 512 - 36, y: cy - 46, width: 44, height: 30))
}

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
