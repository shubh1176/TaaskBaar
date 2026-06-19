import SwiftUI
import AppKit
import Carbon
import Combine

@main
struct StudyBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var quickCapturePanel: QuickCapturePanel!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setupQuickCapture()
        registerHotkey()
        observeTimer()
    }

    private func observeTimer() {
        TimerService.shared.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarFromTimer()
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarFromTimer() {
        let ts = TimerService.shared
        switch ts.state {
        case .idle:
            let stats = ts.getDailyStats()
            if stats.focusSeconds > 0 {
                updateMenuBarTitle("\(stats.focusSeconds.formattedHours)h")
            } else {
                updateMenuBarTitle("Ready")
            }
        case .running:
            updateMenuBarTitle("\(ts.displayString)")
        case .paused:
            updateMenuBarTitle("⏸ \(ts.displayString)")
        case .break_:
            updateMenuBarTitle("☕ \(ts.displayString)")
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self
        updateMenuBarTitle("Ready")
    }

    func updateMenuBarTitle(_ title: String) {
        if let button = statusItem.button {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                .foregroundColor: NSColor.labelColor
            ]
            button.attributedTitle = NSAttributedString(string: " \(title)", attributes: attrs)
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "StudyBar")
            button.imagePosition = .imageLeading
        }
    }

    private func setupPopover() {
        let contentView = PopoverContentView()
            .environmentObject(TimerService.shared)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 520)
        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.behavior = .transient
        popover.animates = true
    }

    private func setupQuickCapture() {
        quickCapturePanel = QuickCapturePanel()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(button)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Global Hotkey

    private func registerHotkey() {
        HotkeyService.shared.registerHotkey { [weak self] in
            self?.showQuickCapture()
        }
    }

    func showQuickCapture() {
        quickCapturePanel.show { [weak self] text in
            guard !text.isEmpty else { return }
            let task = StudyTask(text: text)
            StorageService.shared.addTask(task)
            Haptics.success()
            self?.updateMenuBarTitle("✅ Saved")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self?.updateMenuBarFromTimer()
            }
        }
    }

    func closePopover() {
        popover.performClose(statusItem.button)
    }
}

// MARK: - Hotkey Service
class HotkeyService {
    static let shared = HotkeyService()

    private var hotkeyRef: EventHotKeyRef?
    private var callback: (() -> Void)?

    private let hotkeySignature: UInt32 = {
        let sig = "STDB".utf8.map { UInt8($0) }
        return (UInt32(sig[0]) << 24) | (UInt32(sig[1]) << 16) | (UInt32(sig[2]) << 8) | UInt32(sig[3])
    }()

    func registerHotkey(callback: @escaping () -> Void) {
        self.callback = callback

        let hotKeyID = EventHotKeyID(signature: hotkeySignature, id: 1)

        // cmd+shift+space = cmd(56) + shift(56) + space(49)
        let modifiers: UInt32 = UInt32(cmdKey) | UInt32(shiftKey)
        let keyCode: UInt32 = 49 // space

        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, eventRef, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let unmanaged = Unmanaged<HotkeyService>.fromOpaque(userData)
                unmanaged.takeUnretainedValue().callback?()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
    }

    deinit {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
        }
    }
}

// MARK: - Quick Capture Panel
class QuickCapturePanel: NSPanel {
    private var textField: NSTextField!
    private var completion: ((String) -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 60),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        setupViews()
    }

    private func setupViews() {
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.masksToBounds = true
        contentView = visualEffect

        textField = NSTextField()
        textField.placeholderString = "Capture a task, idea, or note..."
        textField.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.textColor = .labelColor
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.target = self
        textField.action = #selector(submit)

        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)
        icon.contentTintColor = .systemOrange
        icon.translatesAutoresizingMaskIntoConstraints = false

        visualEffect.addSubview(icon)
        visualEffect.addSubview(textField)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: visualEffect.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),

            textField.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: visualEffect.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc private func submit() {
        let text = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        completion?(text)
        close()
    }

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    func show(completion: @escaping (String) -> Void) {
        self.completion = completion
        textField.stringValue = ""

        if let screen = NSScreen.main {
            let x = (screen.frame.width - 420) / 2
            let y = screen.frame.height * 0.4
            setFrameOrigin(NSPoint(x: x, y: y))
        }

        makeKeyAndOrderFront(nil)
        textField.becomeFirstResponder()

        // Fade in
        alphaValue = 0
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.allowsImplicitAnimation = true
            self.alphaValue = 1
        }
    }

    override func close() {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.allowsImplicitAnimation = true
            self.alphaValue = 0
        } completionHandler: {
            super.close()
        }
    }
}
