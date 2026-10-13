import AppKit
// Usage: fit <real.png> <symbol or asset:bundle#name> <slotW> <minSize> <maxSize> [variable] [fg luminance]: renders the symbol's vector at 8x, downsamples to 2x
// with 1/8pt offsets, and prints the best size/weight/origin against a 2x capture of the real menu bar.
let a = CommandLine.arguments
let real = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: a[1])))!
let name = a[2], slotW = Int(a[3])!, lo = Double(a[4])!, hi = Double(a[5])!
let variable = a.count > 6 ? Double(a[6]) : nil
let W = slotW * 2, H = 44, K = 4  // 8x render = 2x * K
func lum(_ c: NSColor) -> Double { let c = c.usingColorSpace(.deviceRGB)!; return (c.redComponent + c.greenComponent + c.blueComponent) / 3 }
let rb = lum(real.colorAt(x: 0, y: 0)!), rf = Double(CommandLine.arguments.count > 7 ? CommandLine.arguments[7] : "0.93")!
var target = [Double](repeating: 0, count: W * H)
for y in 0..<H { for x in 0..<W { target[y * W + x] = max(0, min(1, (lum(real.colorAt(x: x, y: y)!) - rb) / (rf - rb))) } }
var results: [(Double, String)] = []
for (wn, w) in [("regular", NSFont.Weight.regular), ("medium", .medium), ("semibold", .semibold), ("bold", .bold), ("heavy", .heavy)] {
  for size in stride(from: lo, through: hi, by: 0.1) {
    let img: NSImage
    if name.hasPrefix("asset:") {
      if wn != "regular" { continue }
      let parts = name.dropFirst(6).split(separator: "#").map(String.init)
      img = Bundle(path: parts[0])!.image(forResource: parts[1])!.copy() as! NSImage
      let n = img.size; img.size = NSSize(width: n.width * size / 16, height: n.height * size / 16)
    } else {
      let base = variable.map { NSImage(systemSymbolName: name, variableValue: $0, accessibilityDescription: nil)! } ?? NSImage(systemSymbolName: name, accessibilityDescription: nil)!
      img = base.withSymbolConfiguration(.init(pointSize: size, weight: w))!
    }
    let s = img.size
    let RW = W * K + 16, RH = H * K + 16  // room for ±1pt shifts
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: RW, pixelsHigh: RH, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: RW * 4, bitsPerPixel: 32)!
    rep.size = NSSize(width: Double(RW) / 8, height: Double(RH) / 8)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor.white.setFill(); NSRect(origin: .zero, size: rep.size).fill()
    // Centred in the slot, plus a 1pt margin on every side for shifting.
    let cx = (Double(slotW) - s.width) / 2, cy = (22 - s.height) / 2
    img.draw(in: NSRect(x: 1 + cx, y: 1 + cy, width: s.width, height: s.height))
    NSGraphicsContext.restoreGraphicsState()
    let d = rep.bitmapData!
    var ink = [Double](repeating: 0, count: RW * RH)
    for i in 0..<(RW * RH) { ink[i] = 1 - Double(d[i * 4]) / 255 }
    for sx in -8...8 { for sy in -8...8 {
      var e = 0.0
      for y in 0..<H { for x in 0..<W {
        var sum = 0.0
        for j in 0..<K { for i in 0..<K { sum += ink[(y * K + j + 8 + sy) * RW + (x * K + i + 8 - sx)] } }
        let v = sum / Double(K * K) - target[y * W + x]; e += v * v
      }}
      results.append((e, String(format: "%@ %.1f origin %.3f,%.3f frame %gx%g", wn, size, cx + Double(sx) / 8, cy + Double(sy) / 8, s.width, s.height)))
    }}
  }
}
for r in results.sorted(by: { $0.0 < $1.0 }).prefix(4) { print(String(format: "%.2f", r.0), r.1) }
