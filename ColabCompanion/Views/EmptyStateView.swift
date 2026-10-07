import SwiftUI

struct EmptyStateView: View {
    enum Kind {
        case empty
        case error(String)
        case loading
    }

    let kind: Kind
    var onRetry: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        } actions: {
            if let onRetry, showsRetry {
                Button("Try Again", action: onRetry)
                    .buttonStyle(.bordered)
            }
        }
    }

    private var title: String {
        switch kind {
        case .empty: return "No Notebooks"
        case .error: return "Something Went Wrong"
        case .loading: return "Loading"
        }
    }

    private var description: String {
        switch kind {
        case .empty:
            return "No Colab or .ipynb files found in your Google Drive. Create a notebook in Colab, then pull to refresh."
        case .error(let message):
            return message
        case .loading:
            return "Fetching notebooks from Drive…"
        }
    }

    private var systemImage: String {
        switch kind {
        case .empty: return "tray"
        case .error: return "exclamationmark.triangle"
        case .loading: return "arrow.triangle.2.circlepath"
        }
    }

    private var showsRetry: Bool {
        switch kind {
        case .error, .empty: return true
        case .loading: return false
        }
    }
}
