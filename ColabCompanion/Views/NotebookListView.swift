import SwiftUI
import UIKit

/// Owns DriveService tied to the shared GoogleAuthManager.
struct NotebookListView: View {
    @EnvironmentObject private var authManager: GoogleAuthManager
    @StateObject private var driveService: DriveService

    init(authManager: GoogleAuthManager) {
        _driveService = StateObject(wrappedValue: DriveService(authManager: authManager))
    }

    var body: some View {
        NavigationStack {
            Group {
                if driveService.isLoading && driveService.notebooks.isEmpty {
                    EmptyStateView(kind: .loading)
                } else if let error = driveService.errorMessage, driveService.notebooks.isEmpty {
                    EmptyStateView(kind: .error(error)) {
                        Task { await driveService.refresh() }
                    }
                } else if driveService.notebooks.isEmpty {
                    EmptyStateView(kind: .empty) {
                        Task { await driveService.refresh() }
                    }
                } else {
                    listContent
                }
            }
            .navigationTitle("Colab Notebooks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let name = authManager.userName {
                            Text(name)
                        }
                        if let email = authManager.userEmail {
                            Text(email)
                        }
                        Divider()
                        Button("Sign Out", role: .destructive) {
                            authManager.signOut()
                        }
                    } label: {
                        Image(systemName: "person.circle")
                            .accessibilityLabel("Account")
                    }
                }
            }
            .refreshable {
                await driveService.refresh()
            }
            .overlay(alignment: .bottom) {
                if let error = driveService.errorMessage, !driveService.notebooks.isEmpty {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.red.opacity(0.9), in: Capsule())
                        .padding()
                }
            }
        }
        .task {
            await driveService.refresh()
        }
    }

    private var listContent: some View {
        List(driveService.notebooks) { notebook in
            Button {
                UIApplication.shared.open(notebook.colabURL)
            } label: {
                NotebookRow(notebook: notebook)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.insetGrouped)
    }
}

struct NotebookRow: View {
    let notebook: NotebookItem

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(notebook.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(mimeLabel)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15), in: Capsule())

                    if let modified = notebook.modifiedTime {
                        Text(Self.relativeFormatter.localizedString(for: modified, relativeTo: Date()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "safari")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityHint("Opens in Colab in Safari")
    }

    private var mimeLabel: String {
        if notebook.mimeType == Config.colabMimeType { return "Colab" }
        if notebook.name.lowercased().hasSuffix(".ipynb") { return "ipynb" }
        return "Notebook"
    }
}

#Preview {
    let auth = GoogleAuthManager()
    return NotebookListView(authManager: auth)
        .environmentObject(auth)
}
