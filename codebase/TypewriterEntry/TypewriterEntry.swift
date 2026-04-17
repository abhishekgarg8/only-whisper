//
//  TypewriterEntry.swift
//  Typewriter executable entry point
//
//  This file contains only the @main App struct.
//  All app logic lives in the TypewriterApp library target so it can be unit-tested.
//

import SwiftUI
import TypewriterApp

@main
struct TypewriterEntry: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(coordinator)
                .frame(minWidth: 400, idealWidth: 500, maxWidth: 600,
                       minHeight: 500, idealHeight: 600, maxHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Typewriter") {}
            }
        }
    }
}
