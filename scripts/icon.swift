import AppKit

// Usage: icon <output.png>  — draws the 1024px Overfold app icon.
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
    // macOS icon grid: an 824pt rounded square centred on the canvas.
    let body = NSRect(x: 100, y: 100, width: 824, height: 824)
    let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.shadowBlurRadius = 24
    shadow.set()
    NSColor.black.setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    shape.addClip()
    NSGradient(colors: [NSColor(srgbRed: 0.20, green: 0.22, blue: 0.27, alpha: 1), NSColor(srgbRed: 0.07, green: 0.08, blue: 0.10, alpha: 1)])!
        .draw(in: body, angle: -90)

    // A menu bar strip: three icons fading into the fold, then the chevron.
    let bar = NSRect(x: body.minX, y: body.midY - 110, width: body.width, height: 220)
    NSColor.white.withAlphaComponent(0.08).setFill()
    bar.fill()
    for (index, alpha) in [0.18, 0.4, 0.75].enumerated() {
        NSColor.white.withAlphaComponent(alpha).setFill()
        let x = body.minX + 100 + CGFloat(index) * 150
        NSBezierPath(ovalIn: NSRect(x: x, y: bar.midY - 45, width: 90, height: 90)).fill()
    }
    let config = NSImage.SymbolConfiguration(pointSize: 170, weight: .bold)
    if let chevron = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let tinted = NSImage(size: chevron.size, flipped: false) { rect in
            chevron.draw(in: rect)
            NSColor.white.set()
            rect.fill(using: .sourceAtop)
            return true
        }
        let x = body.maxX - 110 - chevron.size.width
        tinted.draw(in: NSRect(x: x, y: bar.midY - chevron.size.height / 2, width: chevron.size.width, height: chevron.size.height))
    }
    NSGraphicsContext.restoreGraphicsState()
    return true
}

let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
