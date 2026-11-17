import AppKit
import IOKit.ps

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let defaults = UserDefaults.standard
    /// What the user asked for (the cup is filled).
    private var wanted = false { didSet { defaults.set(wanted, forKey: "wanted") } }
    /// Whether sleep is actually disabled right now (`pmset` SleepDisabled).
    private var applied = false
    /// Setting: pause (allow sleep) while on battery, resume on the power adapter.
    private var onlyOnAC: Bool {
        get { defaults.bool(forKey: "onlyOnAC") }
        set { defaults.set(newValue, forKey: "onlyOnAC") }
    }
    private var onAC = true
    private var powerSource: CFRunLoopSource?

    func applicationDidFinishLaunching(_ note: Notification) {
        onAC = Self.isOnAC()
        applied = Self.readState()
        // Restore a "wanted but paused on battery" state across relaunches.
        wanted = applied || (defaults.bool(forKey: "wanted") && onlyOnAC && !onAC)
        if let button = item.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        watchPowerSource()
        apply()
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp || NSApp.currentEvent?.modifierFlags.contains(.control) == true {
            let menu = NSMenu()
            menu.addItem(withTitle: statusText, action: nil, keyEquivalent: "")
            menu.addItem(.separator())
            let ac = menu.addItem(withTitle: "Pause on Battery", action: #selector(toggleOnlyOnAC), keyEquivalent: "")
            ac.target = self
            ac.state = onlyOnAC ? .on : .off
            menu.addItem(.separator())
            menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            item.menu = menu
            item.button?.performClick(nil)
            item.menu = nil
            return
        }
        wanted.toggle()
        apply()
    }

    @objc private func toggleOnlyOnAC() {
        onlyOnAC.toggle()
        apply()
    }

    /// Bring `pmset` in line with what the user wants, given the power source and setting.
    private func apply() {
        let target = wanted && (!onlyOnAC || onAC)
        if target != applied {
            _ = Self.setState(target)
            applied = Self.readState()
            // Password prompt cancelled or failed: reflect reality instead of the request.
            if applied != target { wanted = applied }
        }
        refresh()
    }

    private var paused: Bool { wanted && !applied }

    private var statusText: String {
        if paused { return "Paused — on battery" }
        return applied ? "Sleep disabled" : "Sleep allowed"
    }

    private func refresh() {
        item.button?.image = Self.cupImage(filled: wanted)
        item.button?.appearsDisabled = paused
        item.button?.toolTip = paused ? "Paused on battery (resumes on power adapter)"
            : applied ? "Awake (lid-close sleep disabled)" : "Normal sleep"
    }

    private func watchPowerSource() {
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        guard let src = IOPSNotificationCreateRunLoopSource({ ctx in
            guard let ctx else { return }
            let me = Unmanaged<AppDelegate>.fromOpaque(ctx).takeUnretainedValue()
            let ac = AppDelegate.isOnAC()
            guard ac != me.onAC else { return }  // ignore battery % updates
            me.onAC = ac
            me.apply()
        }, ctx)?.takeRetainedValue() else { return }
        powerSource = src
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .defaultMode)
    }

    static func isOnAC() -> Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let type = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() else { return true }
        return (type as String) == kIOPMACPowerKey
    }

    /// Coffee cup in a slight three-quarter view (no steam), drawn as a menu
    /// bar template image. Mirrors the project's 18×18 SVG, flipped vertically
    /// for AppKit's bottom-left origin.
    static func cupImage(filled: Bool) -> NSImage {
        let img = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.set()
            let ctx = NSGraphicsContext.current!.cgContext
            // Match the visual weight of the other menu bar icons.
            ctx.translateBy(x: 9, y: 9)
            ctx.scaleBy(x: 1.15, y: 1.15)
            ctx.translateBy(x: -8.8, y: -8.65)

            // Handle first: the cup wall then covers the inner part of its stroke.
            let handle = NSBezierPath(ovalIn: NSRect(x: 11.4, y: 7.0, width: 4.0, height: 4.0))
            handle.lineWidth = 1.3
            handle.stroke()

            // Tapered cup body.
            let body = NSBezierPath()
            body.move(to: NSPoint(x: 2.2, y: 12.4))
            body.line(to: NSPoint(x: 12.8, y: 12.4))
            body.line(to: NSPoint(x: 11.7, y: 5.4))
            body.curve(to: NSPoint(x: 9.3, y: 3.3),
                       controlPoint1: NSPoint(x: 11.5, y: 4.1),
                       controlPoint2: NSPoint(x: 10.55, y: 3.3))
            body.line(to: NSPoint(x: 5.7, y: 3.3))
            body.curve(to: NSPoint(x: 3.3, y: 5.4),
                       controlPoint1: NSPoint(x: 4.45, y: 3.3),
                       controlPoint2: NSPoint(x: 3.5, y: 4.1))
            body.close()
            body.fill()

            // Outer rim.
            NSBezierPath(ovalIn: NSRect(x: 2.2, y: 10.8, width: 10.6, height: 3.2)).fill()

            // Cut out the opening; the empty cup also loses its interior.
            ctx.saveGState()
            ctx.setBlendMode(.destinationOut)
            NSColor.black.set()
            NSBezierPath(ovalIn: NSRect(x: 3.4, y: 11.5, width: 8.2, height: 1.8)).fill()
            if !filled {
                let interior = NSBezierPath()
                // SVG's quadratic curve, expressed as an equivalent cubic.
                let start = NSPoint(x: 3.5, y: 11.4)
                let control = NSPoint(x: 7.5, y: 9.1)
                let end = NSPoint(x: 11.5, y: 11.4)
                interior.move(to: start)
                interior.curve(to: end,
                               controlPoint1: NSPoint(x: start.x + (control.x - start.x) * 2 / 3,
                                                      y: start.y + (control.y - start.y) * 2 / 3),
                               controlPoint2: NSPoint(x: end.x + (control.x - end.x) * 2 / 3,
                                                      y: end.y + (control.y - end.y) * 2 / 3))
                interior.line(to: NSPoint(x: 10.55, y: 5.5))
                interior.curve(to: NSPoint(x: 9.4, y: 4.5),
                               controlPoint1: NSPoint(x: 10.4, y: 4.85),
                               controlPoint2: NSPoint(x: 10.0, y: 4.5))
                interior.line(to: NSPoint(x: 5.6, y: 4.5))
                interior.curve(to: NSPoint(x: 4.45, y: 5.5),
                               controlPoint1: NSPoint(x: 5.0, y: 4.5),
                               controlPoint2: NSPoint(x: 4.6, y: 4.85))
                interior.close()
                interior.fill()
            }
            ctx.restoreGState()
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
