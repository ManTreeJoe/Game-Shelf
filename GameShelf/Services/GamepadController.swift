import Foundation
import GameController
import SwiftUI

/// Handles gamepad input for navigating the game library
@MainActor
class GamepadController: ObservableObject {
    @Published var isControllerConnected = false
    @Published var controllerName: String = ""
    
    private var viewModel: LibraryViewModel?
    private var columnCount: Int = 5
    
    // Debouncing for D-pad navigation
    private var lastNavigationTime: Date = .distantPast
    private let navigationDebounce: TimeInterval = 0.15
    
    init() {
        setupControllerObservers()
        connectToExistingControllers()
    }
    
    func attach(to viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    func updateColumnCount(_ count: Int) {
        self.columnCount = count
    }
    
    // MARK: - Controller Setup
    
    private func setupControllerObservers() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let controller = notification.object as? GCController {
                Task { @MainActor in
                    self?.controllerConnected(controller)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.controllerDisconnected()
            }
        }
    }
    
    private func connectToExistingControllers() {
        if let controller = GCController.controllers().first {
            controllerConnected(controller)
        }
    }
    
    private func controllerConnected(_ controller: GCController) {
        isControllerConnected = true
        controllerName = controller.vendorName ?? "Game Controller"
        
        setupInputHandlers(for: controller)
        
        print("🎮 Controller connected: \(controllerName)")
    }
    
    private func controllerDisconnected() {
        isControllerConnected = false
        controllerName = ""
        print("🎮 Controller disconnected")
    }
    
    // MARK: - Input Handlers
    
    private func setupInputHandlers(for controller: GCController) {
        // Extended gamepad (Xbox, PlayStation, etc.)
        if let extendedGamepad = controller.extendedGamepad {
            setupExtendedGamepad(extendedGamepad)
        }
        // Micro gamepad (Siri Remote, etc.)
        else if let microGamepad = controller.microGamepad {
            setupMicroGamepad(microGamepad)
        }
    }
    
    private func setupExtendedGamepad(_ gamepad: GCExtendedGamepad) {
        // D-Pad navigation
        gamepad.dpad.valueChangedHandler = { [weak self] _, xValue, yValue in
            Task { @MainActor in
                self?.handleDPad(x: xValue, y: yValue)
            }
        }
        
        // Left thumbstick navigation
        gamepad.leftThumbstick.valueChangedHandler = { [weak self] _, xValue, yValue in
            Task { @MainActor in
                self?.handleThumbstick(x: xValue, y: yValue)
            }
        }
        
        // A button - Launch game
        gamepad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                Task { @MainActor in
                    self?.handleLaunch()
                }
            }
        }
        
        // B button - Back/Close detail view
        gamepad.buttonB.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                Task { @MainActor in
                    self?.handleBack()
                }
            }
        }
        
        // X button - Open game details
        gamepad.buttonX.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                Task { @MainActor in
                    self?.handleDetails()
                }
            }
        }
        
        // Y button - Toggle favorite
        gamepad.buttonY.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                Task { @MainActor in
                    self?.handleFavorite()
                }
            }
        }
        
        // Left bumper - Previous platform filter
        gamepad.leftShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                Task { @MainActor in
                    self?.handlePreviousPlatform()
                }
            }
        }
        
        // Right bumper - Next platform filter
        gamepad.rightShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                Task { @MainActor in
                    self?.handleNextPlatform()
                }
            }
        }
        
        // Left trigger - Random game
        gamepad.leftTrigger.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                Task { @MainActor in
                    self?.handleRandomGame()
                }
            }
        }
        
        // Menu button - Open settings
        gamepad.buttonMenu.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                Task { @MainActor in
                    self?.handleSettings()
                }
            }
        }
    }
    
    private func setupMicroGamepad(_ gamepad: GCMicroGamepad) {
        gamepad.dpad.valueChangedHandler = { [weak self] _, xValue, yValue in
            Task { @MainActor in
                self?.handleDPad(x: xValue, y: yValue)
            }
        }
        
        gamepad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                Task { @MainActor in
                    self?.handleLaunch()
                }
            }
        }
        
        gamepad.buttonX.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                Task { @MainActor in
                    self?.handleBack()
                }
            }
        }
    }
    
    // MARK: - Navigation Handlers
    
    private func handleDPad(x: Float, y: Float) {
        guard canNavigate() else { return }
        
        if x > 0.5 {
            viewModel?.selectNext()
            markNavigated()
        } else if x < -0.5 {
            viewModel?.selectPrevious()
            markNavigated()
        }
        
        if y > 0.5 {
            viewModel?.selectPreviousRow(columns: columnCount)
            markNavigated()
        } else if y < -0.5 {
            viewModel?.selectNextRow(columns: columnCount)
            markNavigated()
        }
    }
    
    private func handleThumbstick(x: Float, y: Float) {
        // Apply a deadzone
        guard abs(x) > 0.4 || abs(y) > 0.4 else { return }
        guard canNavigate() else { return }
        
        if x > 0.4 {
            viewModel?.selectNext()
            markNavigated()
        } else if x < -0.4 {
            viewModel?.selectPrevious()
            markNavigated()
        }
        
        if y > 0.4 {
            viewModel?.selectPreviousRow(columns: columnCount)
            markNavigated()
        } else if y < -0.4 {
            viewModel?.selectNextRow(columns: columnCount)
            markNavigated()
        }
    }
    
    private func canNavigate() -> Bool {
        Date().timeIntervalSince(lastNavigationTime) > navigationDebounce
    }
    
    private func markNavigated() {
        lastNavigationTime = Date()
    }
    
    // MARK: - Action Handlers
    
    private func handleLaunch() {
        viewModel?.launchSelected()
    }
    
    private func handleBack() {
        // Close any open detail view
        viewModel?.selectedROM = nil
        viewModel?.showingSettings = false
        viewModel?.showingQuickLaunch = false
    }
    
    private func handleDetails() {
        viewModel?.openSelectedDetails()
    }
    
    private func handleFavorite() {
        guard let rom = viewModel?.currentlySelectedRom else { return }
        viewModel?.toggleFavorite(rom)
    }
    
    private func handlePreviousPlatform() {
        guard let viewModel = viewModel else { return }
        let platforms = viewModel.platforms
        guard !platforms.isEmpty else { return }
        
        if let current = viewModel.selectedPlatform,
           let index = platforms.firstIndex(of: current) {
            if index > 0 {
                viewModel.selectedPlatform = platforms[index - 1]
            } else {
                viewModel.selectedPlatform = nil // Go to "All"
            }
        } else {
            // Currently on "All", go to last platform
            viewModel.selectedPlatform = platforms.last
        }
    }
    
    private func handleNextPlatform() {
        guard let viewModel = viewModel else { return }
        let platforms = viewModel.platforms
        guard !platforms.isEmpty else { return }
        
        if let current = viewModel.selectedPlatform,
           let index = platforms.firstIndex(of: current) {
            if index < platforms.count - 1 {
                viewModel.selectedPlatform = platforms[index + 1]
            } else {
                viewModel.selectedPlatform = nil // Go to "All"
            }
        } else {
            // Currently on "All", go to first platform
            viewModel.selectedPlatform = platforms.first
        }
    }
    
    private func handleRandomGame() {
        viewModel?.selectRandomGame()
    }
    
    private func handleSettings() {
        viewModel?.showingSettings = true
    }
}

