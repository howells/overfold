import CoreGraphics
import Foundation

// Usage: click <x> <y> [option|right]  — click at a global point, then put the pointer back.
let args = CommandLine.arguments
let point = CGPoint(x: Double(args[1])!, y: Double(args[2])!)
let mode = args.count > 3 ? args[3] : ""
let original = CGEvent(source: nil)!.location
let (down, up, button): (CGEventType, CGEventType, CGMouseButton) =
    mode == "right" ? (.rightMouseDown, .rightMouseUp, .right) : (.leftMouseDown, .leftMouseUp, .left)

CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)!.post(tap: .cghidEventTap)
usleep(120_000)
for type in [down, up] {
    let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: button)!
    if mode == "option" { event.flags = .maskAlternate }
    event.post(tap: .cghidEventTap)
    usleep(80_000)
}
CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: original, mouseButton: .left)!.post(tap: .cghidEventTap)
