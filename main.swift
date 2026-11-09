import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var enabled = false

    func applicationDidFinishLaunching(_ note: Notification) {
        enabled = Self.readState()
        if let button = item.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        refresh()
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp || NSApp.currentEvent?.modifierFlags.contains(.control) == true {
            let menu = NSMenu()
            menu.addItem(withTitle: enabled ? "Sleep disabled" : "Sleep allowed", action: nil, keyEquivalent: "")
            menu.addItem(.separator())
            menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            item.menu = menu
            item.button?.performClick(nil)
            item.menu = nil
            return
        }
        if Self.setState(!enabled) { enabled = Self.readState() }
        refresh()
    }

    private func refresh() {
        item.button?.image = Self.cupImage(filled: enabled)
        item.button?.toolTip = enabled ? "Awake (lid-close sleep disabled)" : "Normal sleep"
    }

    /// Plain coffee cup (no saucer, no steam), drawn as a menu bar template image.
    static func cupImage(filled: Bool) -> NSImage {
        let img = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.set()
            let body = NSBezierPath()
            body.move(to: NSPoint(x: 1.75, y: 13.5))
            body.line(to: NSPoint(x: 13.25, y: 13.5))
            body.curve(to: NSPoint(x: 9.5, y: 3.25), controlPoint1: NSPoint(x: 13.25, y: 7.5), controlPoint2: NSPoint(x: 12.0, y: 3.25))
            body.line(to: NSPoint(x: 5.5, y: 3.25))
            body.curve(to: NSPoint(x: 1.75, y: 13.5), controlPoint1: NSPoint(x: 3.0, y: 3.25), controlPoint2: NSPoint(x: 1.75, y: 7.5))
            body.close()
            body.lineWidth = 1.5
            body.lineJoinStyle = .round
            if filled { body.fill() }
            body.stroke()
            let handle = NSBezierPath()
            handle.appendArc(withCenter: NSPoint(x: 13.4, y: 10.0), radius: 2.6, startAngle: 90, endAngle: -75, clockwise: true)
            handle.lineWidth = 1.5
            handle.lineCapStyle = .round
            handle.stroke()
            return true
        }
        img.isTemplate = true
        img.accessibilityDescription = "Coffee"
        return img
    }

    static func readState() -> Bool {
        let out = run("/usr/bin/pmset", ["-g"]).output
        return out.split(separator: "\n").contains { $0.contains("SleepDisabled") && $0.trimmingCharacters(in: .whitespaces).hasSuffix("1") }
    }

    static func setState(_ on: Bool) -> Bool {
        let v = on ? "1" : "0"
        // Passwordless path (if sudoers rule installed), otherwise admin prompt.
        if run("/usr/bin/sudo", ["-n", "/usr/bin/pmset", "-a", "disablesleep", v]).status == 0 { return true }
        let script = "do shell script \"/usr/bin/pmset -a disablesleep \(v)\" with administrator privileges"
        var err: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&err)
        return err == nil
    }

    @discardableResult
    static func run(_ path: String, _ args: [String]) -> (status: Int32, output: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = Pipe()
        do { try p.run() } catch { return (-1, "") }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (p.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
