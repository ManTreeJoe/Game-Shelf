import Foundation
import AppKit

class SessionTracker: ObservableObject {
    static let shared = SessionTracker()
    
    @Published var activeSession: PlaySession?
    @Published var isTracking = false
    
    private let statsDB = StatsDatabase()
    private var checkTimer: Timer?
    private var trackedProcessIdentifier: Int32?
    
    private init() {}
    
    // MARK: - Session Management
    
    func startSession(for rom: ROM) {
        // End any existing session
        endCurrentSession()
        
        // Start new session
        activeSession = PlaySession(romPath: rom.path.path)
        isTracking = true
        
        print("Started tracking session for: \(rom.displayName)")
    }
    
    func startTrackingProcess(_ process: Process, for rom: ROM) {
        startSession(for: rom)
        trackedProcessIdentifier = process.processIdentifier
        
        // Monitor for process termination
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.endCurrentSession()
            }
        }
        
        // Also use a timer as backup for app-based emulators
        startCheckTimer()
    }
    
    func startTrackingApp(bundleIdentifier: String?, for rom: ROM) {
        startSession(for: rom)
        
        // For .app based emulators, we monitor if the app is still running
        startCheckTimer()
    }
    
    func endCurrentSession() {
        guard var session = activeSession else { return }
        
        session.endTime = Date()
        
        // Only record if played for more than 10 seconds (avoid accidental launches)
        if session.duration > 10 {
            statsDB.recordSession(session)
            print("Recorded session: \(session.formattedDuration)")
        } else {
            print("Session too short, not recorded")
        }
        
        activeSession = nil
        isTracking = false
        trackedProcessIdentifier = nil
        stopCheckTimer()
    }
    
    // MARK: - Timer-based Checking
    
    private func startCheckTimer() {
        stopCheckTimer()
        
        checkTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkIfStillPlaying()
        }
    }
    
    private func stopCheckTimer() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    private func checkIfStillPlaying() {
        guard isTracking else {
            stopCheckTimer()
            return
        }
        
        // Check if tracked process is still running
        if let pid = trackedProcessIdentifier {
            let running = isProcessRunning(pid: pid)
            if !running {
                endCurrentSession()
            }
        }
    }
    
    private func isProcessRunning(pid: Int32) -> Bool {
        // Check if process exists
        let result = kill(pid, 0)
        return result == 0
    }
    
    // MARK: - Access to Stats
    
    func getStats(for rom: ROM) -> GameStats {
        statsDB.getStats(forRomPath: rom.path.path)
    }
    
    var database: StatsDatabase {
        statsDB
    }
}

// MARK: - Updated Emulator Launcher with Tracking

extension EmulatorLauncher {
    func launchWithTracking(_ rom: ROM) throws {
        // Start tracking
        SessionTracker.shared.startSession(for: rom)
        
        // Launch the game
        try launch(rom)
    }
}

