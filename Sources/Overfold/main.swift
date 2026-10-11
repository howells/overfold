import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overfold: Overfold?

    func applicationDidFinishLaunching(_ notification: Notification) {
        overfold = Overfold()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
