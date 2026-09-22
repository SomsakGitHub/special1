import AppKit
import Foundation

let args = CommandLine.arguments
let shotPath = args[1]
let outPath = args[2]

let W: CGFloat = 1320
let H: CGFloat = 2868

let shot = NSImage(contentsOfFile: shotPath)!

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
ctx.clear(CGRect(x: 0, y: 0, width: W, height: H))

// background gradient (Man U red)
let top = NSColor(calibratedRed: 0.93, green: 0.12, blue: 0.07, alpha: 1).cgColor
let bottom = NSColor(calibratedRed: 0.42, green: 0.03, blue: 0.09, alpha: 1).cgColor
let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                      colors: [top, bottom] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: W / 2, y: H), end: CGPoint(x: W / 2, y: 0), options: [])

// faint huge soccerball watermark bottom
ctx.saveGState()
ctx.setFillColor(NSColor.white.withAlphaComponent(0.06).cgColor)
ctx.fillEllipse(in: CGRect(x: -360, y: -380, width: 900, height: 900))
ctx.restoreGState()

// headline
func drawText(_ s: String, size: CGFloat, weight: NSFont.Weight, y: CGFloat) {
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
    let str = NSAttributedString(string: s, attributes: attrs)
    let sz = str.size()
    str.draw(at: NSPoint(x: (W - sz.width) / 2, y: y))
}
drawText("YOUR CLUB", size: 84, weight: .bold, y: H - 300)
drawText("LIVE", size: 150, weight: .heavy, y: H - 560)

// app screenshot with rounded corners + shadow
let sw: CGFloat = 1080
let sh = sw * shot.size.height / shot.size.width
let rect = CGRect(x: (W - sw) / 2, y: H - 560 - sh - 60, width: sw, height: sh)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -24), blur: 40,
              color: NSColor.black.withAlphaComponent(0.5).cgColor)
let path = CGPath(roundedRect: rect, cornerWidth: 90, cornerHeight: 90, transform: nil)
ctx.addPath(path)
ctx.clip()
shot.draw(in: rect)
ctx.restoreGState()

let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: outPath))
print("composed -> \(outPath)")