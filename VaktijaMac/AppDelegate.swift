import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private var statusItemController: StatusItemController?
    private var hotKeyController: HotKeyController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItemController = StatusItemController(appState: appState)
        self.statusItemController = statusItemController

        hotKeyController = HotKeyController {
            statusItemController.togglePopover()
        }
        hotKeyController?.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyController?.unregister()
    }
}
