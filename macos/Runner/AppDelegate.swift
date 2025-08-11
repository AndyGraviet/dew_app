import Cocoa
import FlutterMacOS

// StatusBarController class
class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var statusBarMenu: NSMenu
    private var flutterChannel: FlutterMethodChannel?
    
    // Timer state
    private var timeLeft: Int = 25 * 60
    private var isRunning: Bool = false
    private var timerState: String = "work"
    private var completedSessions: Int = 0
    private var templateName: String = "Focus Timer"
    
    init() {
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusBarMenu = NSMenu()
        
        // Set up the status item
        if let button = statusItem.button {
            updateDisplay()
            button.action = #selector(statusBarButtonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
        
        // Build initial menu
        buildMenu()
    }
    
    func setFlutterChannel(_ channel: FlutterMethodChannel) {
        self.flutterChannel = channel
    }
    
    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == NSEvent.EventType.rightMouseUp {
            // Right click - show menu
            statusItem.menu = statusBarMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            // Left click - toggle window visibility
            flutterChannel?.invokeMethod("toggleWindow", arguments: nil)
        }
    }
    
    func updateTimerState(time: Int, running: Bool, state: String, sessions: Int, template: String) {
        timeLeft = time
        isRunning = running
        timerState = state
        completedSessions = sessions
        templateName = template
        
        updateDisplay()
        buildMenu()
    }
    
    private func updateDisplay() {
        guard let button = statusItem.button else { return }
        
        let timeString = formatTime(seconds: timeLeft)
        var displayString = timeString
        
        // Add state indicator
        if isRunning {
            switch timerState {
            case "work":
                displayString = "🔵 \(timeString)"
            case "shortBreak", "longBreak":
                displayString = "🟢 \(timeString)"
            default:
                displayString = "⏰ \(timeString)"
            }
        } else {
            displayString = "⏸️ \(timeString)"
        }
        
        button.title = displayString
        button.toolTip = "\(templateName) - \(completedSessions) sessions completed"
    }
    
    private func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    private func buildMenu() {
        statusBarMenu.removeAllItems()
        
        // Status information
        let statusItem = NSMenuItem(title: getStatusText(), action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        statusBarMenu.addItem(statusItem)
        
        let templateItem = NSMenuItem(title: templateName, action: nil, keyEquivalent: "")
        templateItem.isEnabled = false
        statusBarMenu.addItem(templateItem)
        
        let sessionsItem = NSMenuItem(title: "Sessions completed: \(completedSessions)", action: nil, keyEquivalent: "")
        sessionsItem.isEnabled = false
        statusBarMenu.addItem(sessionsItem)
        
        statusBarMenu.addItem(NSMenuItem.separator())
        
        // Control items
        let playPauseItem = NSMenuItem(
            title: isRunning ? "⏸️ Pause Timer" : "▶️ Start Timer",
            action: #selector(togglePlayPause),
            keyEquivalent: ""
        )
        playPauseItem.target = self
        statusBarMenu.addItem(playPauseItem)
        
        let resetItem = NSMenuItem(
            title: "🔄 Reset Timer",
            action: #selector(resetTimer),
            keyEquivalent: ""
        )
        resetItem.target = self
        statusBarMenu.addItem(resetItem)
        
        statusBarMenu.addItem(NSMenuItem.separator())
        
        // Window control
        let windowItem = NSMenuItem(
            title: "Show/Hide Window",
            action: #selector(toggleWindow),
            keyEquivalent: ""
        )
        windowItem.target = self
        statusBarMenu.addItem(windowItem)
        
        statusBarMenu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit App",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        statusBarMenu.addItem(quitItem)
    }
    
    private func getStatusText() -> String {
        let stateDisplay: String
        switch timerState {
        case "work":
            stateDisplay = "Working Time"
        case "shortBreak":
            stateDisplay = "Short Break"
        case "longBreak":
            stateDisplay = "Long Break"
        default:
            stateDisplay = "Timer"
        }
        
        let timeDisplay = formatTime(seconds: timeLeft)
        return isRunning ? "\(stateDisplay) - \(timeDisplay)" : "Timer Stopped - \(timeDisplay)"
    }
    
    @objc func togglePlayPause() {
        flutterChannel?.invokeMethod("togglePlayPause", arguments: nil)
    }
    
    @objc func resetTimer() {
        flutterChannel?.invokeMethod("resetTimer", arguments: nil)
    }
    
    @objc func toggleWindow() {
        flutterChannel?.invokeMethod("toggleWindow", arguments: nil)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

@main
class AppDelegate: FlutterAppDelegate {
  var statusBarController: StatusBarController?
  var timerChannel: FlutterMethodChannel?
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    // Initialize status bar
    statusBarController = StatusBarController()
    
    // Set up Flutter method channel
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return
    }
    
    timerChannel = FlutterMethodChannel(
      name: "dev.flutter.timer/status",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    statusBarController?.setFlutterChannel(timerChannel!)
    
    // Handle method calls from Flutter
    timerChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "updateTimer":
        if let args = call.arguments as? [String: Any],
           let time = args["time"] as? Int,
           let isRunning = args["isRunning"] as? Bool,
           let state = args["state"] as? String,
           let sessions = args["sessions"] as? Int,
           let template = args["template"] as? String {
          self?.statusBarController?.updateTimerState(
            time: time,
            running: isRunning,
            state: state,
            sessions: sessions,
            template: template
          )
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid timer update arguments", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Don't terminate when window closes - keep running in menu bar
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
