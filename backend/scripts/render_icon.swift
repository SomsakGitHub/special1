import AppKit
import CoreGraphics
import Foundation

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let base: CGFloat = 1024
let c = base / 2

func makeContext(_ size: CGFloat, transparent: Bool = false) -> (NSBitmapImageRep, CGContext) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    ctx.interpolationQuality = .high
    if !transparent {
        ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))
    }
    return (rep, ctx)
}

func save(_ rep: NSBitmapImageRep, _ name: String) throws {
    let png = rep.representation(using: .png, properties: [:])!
    try png.write(to: outDir.appendingPathComponent(name))
}

// ---------- drawing primitives ----------

func drawIcon(size: CGFloat, dark: Bool = false, tinted: Bool = false) throws {
    let (rep, ctx) = makeContext(size)
    ctx.saveGState()
    ctx.scaleBy(x: size / base, y: size / base)

    if tinted {
        // single-color silhouette: solid ball shape in black, transparent background
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fillEllipse(in: CGRect(x: c - 300, y: c - 300, width: 600, height: 600))
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(14)
        // seams
        let p1 = pentagonVertices(center: CGPoint(x: c, y: c), radius: 118, flatTop: true)
        strokePolygon(ctx, p1, closed: true)
        var i = 0
        for v in p1 {
            let ang = atan2(v.y - c, v.x - c)
            let end = CGPoint(x: c + cos(ang) * 266, y: c + sin(ang) * 266)
            ctx.move(to: v); ctx.addLine(to: end); ctx.strokePath()
            let p2 = pentagonVertices(center: CGPoint(x: c + cos(ang) * 252, y: c + sin(ang) * 252), radius: 62, flatTop: true)
            strokePolygon(ctx, p2, closed: true)
        }
        ctx.restoreGState()
        try save(rep, "AppIcon~tinted.png")
        return
    }

    // background gradient
    let colorTop = NSColor(calibratedRed: 0.93, green: 0.13, blue: 0.08, alpha: 1).cgColor
    let colorMid = NSColor(calibratedRed: 0.85, green: 0.07, blue: 0.09, alpha: 1).cgColor
    let colorBot = NSColor(calibratedRed: 0.48, green: 0.04, blue: 0.10, alpha: 1).cgColor
    let colors: CFArray = dark
        ? [NSColor.black.cgColor, colorBot] as CFArray
        : [colorTop, colorBot] as CFArray
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: c, y: base), end: CGPoint(x: c, y: 0), options: [])

    // subtle diagonal light sweep
    ctx.saveGState()
    let sweep = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [NSColor.white.withAlphaComponent(0.16).cgColor, NSColor.clear.cgColor] as CFArray,
                           locations: [0, 1])!
    ctx.drawLinearGradient(sweep, start: CGPoint(x: 0, y: base), end: CGPoint(x: base, y: 0), options: [])
    ctx.restoreGState()

    // ground shadow under ball
    ctx.setFillColor(NSColor.black.withAlphaComponent(0.28).cgColor)
    ctx.fillEllipse(in: CGRect(x: c - 230, y: c - 372, width: 460, height: 60))
    ctx.fillEllipse(in: CGRect(x: c - 210, y: c - 360, width: 420, height: 44))

    // ball body
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillEllipse(in: CGRect(x: c - 300, y: c - 320, width: 600, height: 600))

    // seam color
    let seam = NSColor(calibratedRed: 0.70, green: 0.08, blue: 0.13, alpha: 1).cgColor
    ctx.setStrokeColor(seam)
    ctx.setLineWidth(12)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // center pentagon
    let p1 = pentagonVertices(center: CGPoint(x: c, y: c), radius: 118, flatTop: true)
    strokePolygon(ctx, p1, closed: true)

    // spokes + rim pentagons
    let rimOuter: CGFloat = 288
    for v in p1 {
        let ang = atan2(v.y - c, v.x - c)
        let end = CGPoint(x: c + cos(ang) * rimOuter, y: c + sin(ang) * rimOuter)
        ctx.move(to: v)
        ctx.addLine(to: end)
        ctx.strokePath()
    }

    // outer visible pentagons hugging the rim
    for k in 0..<5 {
        let ang = -CGFloat.pi / 2 + CGFloat(k) * 2 * CGFloat.pi / 5 + CGFloat.pi / 5
        let centerP = CGPoint(x: c + cos(ang) * 240, y: c + sin(ang) * 240)
        let p2 = pentagonVertices(center: centerP, radius: 70, flatTop: true)
        // clip just inside the ball so pentagons peek over the rim
        ctx.saveGState()
        ctx.beginPath()
        ctx.addEllipse(in: CGRect(x: c - 280, y: c - 280, width: 560, height: 560))
        ctx.clip()
        ctx.setLineWidth(14)
        strokePolygon(ctx, p2, closed: true)
        ctx.restoreGState()
    }

    // gloss highlight
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: c - 300, y: c - 320, width: 600, height: 600))
    ctx.clip()
    let gloss = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [NSColor.white.withAlphaComponent(0.65).cgColor,
                                    NSColor.white.withAlphaComponent(0.02).cgColor] as CFArray,
                           locations: [0, 1])!
    ctx.drawRadialGradient(gloss,
                           startCenter: CGPoint(x: c - 140, y: c + 150), startRadius: 0,
                           endCenter: CGPoint(x: c - 140, y: c + 150), endRadius: 360,
                           options: [])
    ctx.restoreGState()

    ctx.restoreGState()
    try save(rep, dark ? "AppIcon~dark.png" : "AppIcon.png")
}

func pentagonVertices(center: CGPoint, radius: CGFloat, flatTop: Bool) -> [CGPoint] {
    let offset = flatTop ? CGFloat.pi / 2 + CGFloat.pi / 5 : CGFloat.pi / 2
    return (0..<5).map { k in
        let a = -offset + CGFloat(k) * 2 * CGFloat.pi / 5
        return CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius)
    }
}

func strokePolygon(_ ctx: CGContext, _ pts: [CGPoint], closed: Bool) {
    ctx.beginPath()
    ctx.move(to: pts[0])
    for p in pts.dropFirst() { ctx.addLine(to: p) }
    if closed { ctx.closePath() }
    ctx.strokePath()
}

// ---------- generate ----------

try drawIcon(size: base)                              // AppIcon.png
try drawIcon(size: base, dark: true)                  // AppIcon~dark.png
try drawIcon(size: base, tinted: true)                // AppIcon~tinted.png

print("icon art generated into \(outDir.path)")