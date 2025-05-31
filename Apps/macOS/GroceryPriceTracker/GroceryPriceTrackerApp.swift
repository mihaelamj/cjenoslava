import SwiftUI
import CroatianGroceryUI

@main
struct GroceryPriceTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Refresh Data") {
                    // Handle refresh from menu
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
