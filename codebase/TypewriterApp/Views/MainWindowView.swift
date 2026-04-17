//
//  MainWindowView.swift
//  Typewriter
//
//  Main application window with 3 tabs
//

import SwiftUI

public struct MainWindowView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var selectedTab = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(0)

            TranscriptionsView()
                .tabItem { Label("Transcriptions", systemImage: "doc.text") }
                .tag(1)

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(2)
        }
        .padding()
    }
}
