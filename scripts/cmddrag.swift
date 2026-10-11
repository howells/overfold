import CoreGraphics
import Foundation

// Usage: cmddrag <fromX> <toX> [y]  — ⌘-drag a menu bar icon horizontally, then put the pointer back.
let args = CommandLine.arguments
let fromX = Double(args[1])!, toX = Double(args[2])!
let y = args.count > 3 ? Double(args[3])! : 15
let original = CGEvent(source: nil)!.location

func post(_ type: CGEventType, _ x: Double, command: Bool) {
    let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .left)!
    if command { event.flags = .maskCommand }
    event.post(tap: .cghidEventTap)
}

post(.mouseMoved, fromX, command: false)
usleep(150_000)
post(.leftMouseDown, fromX, command: true)
usleep(300_000)
let steps = 30
for i in 1...steps {
    post(.leftMouseDragged, fromX + (toX - fromX) * Double(i) / Double(steps), command: true)
    usleep(20_000)
}
usleep(300_000)
post(.leftMouseUp, toX, command: true)
usleep(200_000)
CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: original, mouseButton: .left)!.post(tap: .cghidEventTap)
