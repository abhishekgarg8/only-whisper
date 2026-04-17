//
//  AboutView.swift
//  Typewriter
//
//  About and app information
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon
                Image(systemName: "mic.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(radius: 5)

                // App Name & Version
                VStack(spacing: 8) {
                    Text("Typewriter")
                        .font(.system(size: 32, weight: .bold))

                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Description
                Text("Voice-to-text transcription for macOS\nSave time by speaking instead of typing")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Divider()
                    .padding(.vertical)

                // Features
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "keyboard", title: "Global Hotkey", description: "Invoke from anywhere with a keyboard shortcut")
                    FeatureRow(icon: "waveform", title: "Real-time Feedback", description: "Visual overlay shows recording status")
                    FeatureRow(icon: "doc.text", title: "Smart Transcription", description: "Powered by OpenAI Whisper AI")
                    FeatureRow(icon: "arrow.down.doc", title: "Auto-paste", description: "Transcribed text appears at your cursor")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                Divider()
                    .padding(.vertical)

                // Links
                VStack(spacing: 12) {
                    Text("Resources")
                        .font(.headline)

                    HStack(spacing: 20) {
                        LinkButton(title: "GitHub", icon: "arrow.up.right.square", url: "https://github.com")
                        LinkButton(title: "Docs", icon: "book", url: "https://github.com")
                        LinkButton(title: "Support", icon: "questionmark.circle", url: "https://github.com")
                    }
                }

                Spacer()

                // Footer
                VStack(spacing: 4) {
                    Text("Powered by OpenAI Whisper")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Made with ❤️ for productivity")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LinkButton: View {
    let title: String
    let icon: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(width: 80, height: 60)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
