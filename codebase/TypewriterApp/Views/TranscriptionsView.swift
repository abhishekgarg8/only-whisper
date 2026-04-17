//
//  TranscriptionsView.swift
//  Typewriter
//
//  Transcription history list with search and delete support
//

import SwiftUI

struct TranscriptionsView: View {
    @State private var transcriptions: [Transcription] = []
    @State private var searchText = ""
    @State private var showingDeleteAlert = false

    var filteredTranscriptions: [Transcription] {
        guard !searchText.isEmpty else { return transcriptions }
        return transcriptions.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                TextField("Search transcriptions...", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if !transcriptions.isEmpty {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                    .help("Delete all transcriptions")
                }
            }
            .padding()

            if filteredTranscriptions.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredTranscriptions) { transcription in
                        TranscriptionRowView(transcription: transcription)
                    }
                    .onDelete { indexSet in
                        deleteTranscriptions(at: indexSet)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear { loadTranscriptions() }
        .alert("Delete All Transcriptions", isPresented: $showingDeleteAlert) {
            Button("Delete All", role: .destructive) {
                TranscriptionStorage.shared.deleteAll()
                loadTranscriptions()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(transcriptions.count) saved transcriptions.")
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Transcriptions")
                .font(.title2)
            Text(searchText.isEmpty
                 ? "Your saved transcriptions will appear here"
                 : "No results for \"\(searchText)\"")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadTranscriptions() {
        transcriptions = TranscriptionStorage.shared.loadAll().reversed()
    }

    private func deleteTranscriptions(at indexSet: IndexSet) {
        for index in indexSet {
            let transcription = filteredTranscriptions[index]
            TranscriptionStorage.shared.delete(matching: transcription)
        }
        loadTranscriptions()
    }
}

struct TranscriptionRowView: View {
    let transcription: Transcription

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(transcription.textPreview)
                .font(.body)
                .lineLimit(2)

            HStack {
                Text(transcription.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(String(format: "%.1fs", transcription.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
