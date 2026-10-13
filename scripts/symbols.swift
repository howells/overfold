import AppKit

// Usage: symbols <output dir>  — renders the site's menu bar icons from SF Symbols as large greyscale
// PGM bitmaps for potrace (see scripts/symbols.sh). Each symbol is drawn into its whole status item
// slot (slot × 22pt) at the position macOS uses, so the page needs no centring of its own.
// macOS hints symbols when it draws them at 2x, so sizes and origins were fitted by downsampling
// the vector to 2x against captures of the real macOS 26 menu bar: Wi-Fi is 15.2pt medium at (1, 3)
// in a 22pt slot, Control Centre 14pt medium at (4.25, 3.25) in 26pt, and Overfold's arrow 13pt
// medium at (10.25, 4.125) in 30pt. Universal Control and Time Machine are fitted the same way, and
// Twingate is its own vector icon from /Applications/Twingate.app. The battery and Tailscale's dot
// grid are drawn by hand in index.html.
let out = URL(fileURLWithPath: CommandLine.arguments[1])
let scale: CGFloat = 32

struct Layer {
    let file: String
    let name: String
    var slot: CGFloat = 24
    var size: CGFloat = 13
    var weight: NSFont.Weight = .medium
    var variable: Double? = nil
    /// An image from another app's asset catalogue, as "bundle path#name", instead of an SF Symbol.
    var asset: String? = nil
    /// Top-left of the symbol's frame in the slot; nil centres it on the backing pixel grid.
    var origin: NSPoint? = nil
}

let layers: [Layer] = [
    Layer(file: "chevron-left", name: "chevron.left", slot: 30, origin: NSPoint(x: 10.25, y: 4.125)),
    Layer(file: "chevron-right", name: "chevron.right", slot: 30, origin: NSPoint(x: 9.75, y: 4.125)),
    Layer(file: "wifi-all", name: "wifi", slot: 22, size: 15.2, origin: NSPoint(x: 1, y: 3)),
    Layer(file: "wifi-1", name: "wifi", slot: 22, size: 15.2, variable: 0.34, origin: NSPoint(x: 1, y: 3)),
    Layer(file: "wifi-2", name: "wifi", slot: 22, size: 15.2, variable: 0.67, origin: NSPoint(x: 1, y: 3)),
    Layer(file: "control-centre", name: "switch.2", slot: 26, size: 14, origin: NSPoint(x: 4.25, y: 3.25)),
    Layer(file: "universal-control", name: "dots.and.line.vertical.and.cursorarrow.rectangle", slot: 19, size: 14,
          weight: .semibold, origin: NSPoint(x: -0.25, y: 0.375)),
    Layer(file: "time-machine", name: "exclamationmark.arrow.trianglehead.counterclockwise.rotate.90", slot: 22,
          weight: .regular, origin: NSPoint(x: 2.875, y: 4.5)),
    Layer(file: "twingate", name: "IconConnected", asset: "/Applications/Twingate.app", origin: NSPoint(x: 4, y: 3.5)),
    Layer(file: "amphetamine", name: "pills"),
    Layer(file: "granola", name: "note.text"),
    Layer(file: "wispr", name: "waveform"),
    Layer(file: "onedrive", name: "cloud"),
    Layer(file: "drive", name: "triangle"),
    Layer(file: "sentinel", name: "shield.lefthalf.filled"),
    Layer(file: "ollama", name: "cpu"),
]

for layer in layers {
    let image: NSImage
    if let asset = layer.asset {
        guard let found = Bundle(path: asset)?.image(forResource: layer.name) else { print("missing \(layer.name)"); continue }
        image = found
    } else {
        let base = layer.variable.map { NSImage(systemSymbolName: layer.name, variableValue: $0, accessibilityDescription: nil) }
            ?? NSImage(systemSymbolName: layer.name, accessibilityDescription: nil)
        guard let base else { print("missing \(layer.name)"); continue }
        image = base.withSymbolConfiguration(.init(pointSize: layer.size, weight: layer.weight))!
    }
    let slot = NSSize(width: layer.slot, height: 22)
    let origin = layer.origin ?? NSPoint(x: ((slot.width - image.size.width) / 2 * 2).rounded() / 2,
                                         y: ((slot.height - image.size.height) / 2 * 2).rounded() / 2)
    let w = Int(slot.width * scale), h = Int(slot.height * scale)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = slot
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor.white.setFill()
    NSRect(origin: .zero, size: slot).fill()
    // AppKit's origin is bottom-left; the slot origin is top-left.
    image.draw(in: NSRect(x: origin.x, y: slot.height - origin.y - image.size.height, width: image.size.width, height: image.size.height))
    NSGraphicsContext.restoreGraphicsState()

    var grey = [CGFloat](repeating: 1, count: w * h)
    for y in 0..<h {
        for x in 0..<w {
            let c = rep.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
            grey[y * w + x] = (c.redComponent + c.greenComponent + c.blueComponent) / 3
        }
    }
    // Some app icons are partly transparent; stretch their darkest ink to black so the trace keeps
    // the shape, and the page restores the opacity.
    let darkest = min(grey.min()!, 0.999)
    var pgm = Data("P5 \(w) \(h) 255\n".utf8)
    for v in grey { pgm.append(UInt8(max(0, min(255, (1 - (1 - v) / (1 - darkest)) * 255)))) }
    if darkest > 0.05 { print("\(layer.file): ink peaks at \(String(format: "%.2f", 1 - darkest)) opacity") }
    try pgm.write(to: out.appendingPathComponent("\(layer.file).pgm"))
    print(layer.file, slot.width)
}
