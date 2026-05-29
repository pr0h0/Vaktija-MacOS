import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let appState: AppState
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var cancellables: Set<AnyCancellable> = []

    init(appState: AppState) {
        self.appState = appState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusItem()
        configurePopover()
        observeAppState()
        updateStatusItem()
    }

    func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 670)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView()
                .environmentObject(appState)
        )
    }

    private func observeAppState() {
        appState.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        switch appState.menuBarDisplayMode {
        case .iconOnly:
            button.image = NSImage(systemSymbolName: "moon.stars", accessibilityDescription: "Vaktija")
            button.title = ""
        case .fullCountdown:
            button.image = nil
            button.title = appState.fullMenuBarTitle
        case .compactCountdown:
            button.image = nil
            button.title = appState.compactMenuBarTitle
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else {
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        updateStatusItem()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func statusItemClicked() {
        togglePopover()
    }
}
