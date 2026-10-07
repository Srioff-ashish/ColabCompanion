import Foundation

@MainActor
final class DriveService: ObservableObject {
    @Published private(set) var notebooks: [NotebookItem] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let authManager: GoogleAuthManager
    private let session: URLSession

    init(authManager: GoogleAuthManager, session: URLSession = .shared) {
        self.authManager = authManager
        self.session = session
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let token = try await authManager.freshAccessToken()
            let items = try await fetchAllNotebooks(accessToken: token)
            notebooks = items.sorted {
                ($0.modifiedTime ?? .distantPast) > ($1.modifiedTime ?? .distantPast)
            }
        } catch {
            errorMessage = error.localizedDescription
            // Keep previous notebooks visible on refresh failure
        }
    }

    private func fetchAllNotebooks(accessToken: String) async throws -> [NotebookItem] {
        var all: [NotebookItem] = []
        var pageToken: String?

        // Query: Colab MIME OR .ipynb name, not in trash
        let q = """
        (mimeType='\(Config.colabMimeType)' or mimeType='\(Config.ipynbMimeType)' or name contains '.ipynb') and trashed=false
        """

        repeat {
            var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
            var items: [URLQueryItem] = [
                URLQueryItem(name: "q", value: q),
                URLQueryItem(name: "fields", value: "nextPageToken,files(id,name,mimeType,modifiedTime,webViewLink)"),
                URLQueryItem(name: "pageSize", value: "100"),
                URLQueryItem(name: "orderBy", value: "modifiedTime desc"),
                URLQueryItem(name: "spaces", value: "drive")
            ]
            if let pageToken {
                items.append(URLQueryItem(name: "pageToken", value: pageToken))
            }
            components.queryItems = items

            guard let url = components.url else {
                throw DriveError.badURL
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw DriveError.invalidResponse
            }
            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw DriveError.http(http.statusCode, body)
            }

            let decoded = try JSONDecoder().decode(DriveFileListResponse.self, from: data)
            let pageItems = (decoded.files ?? []).compactMap { file -> NotebookItem? in
                // Prefer true Colab / ipynb MIME; also accept name ending in .ipynb
                let isColab = file.mimeType == Config.colabMimeType
                    || file.mimeType == Config.ipynbMimeType
                    || file.name.lowercased().hasSuffix(".ipynb")
                guard isColab else { return nil }
                return NotebookItem(
                    id: file.id,
                    name: file.name,
                    mimeType: file.mimeType,
                    modifiedTime: Self.parseDate(file.modifiedTime),
                    webViewLink: file.webViewLink
                )
            }
            all.append(contentsOf: pageItems)
            pageToken = decoded.nextPageToken
        } while pageToken != nil

        // Dedupe by id (query can overlap MIME + name)
        var seen = Set<String>()
        return all.filter { seen.insert($0.id).inserted }
    }

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: raw) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: raw)
    }
}

enum DriveError: LocalizedError {
    case badURL
    case invalidResponse
    case http(Int, String)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Could not build Drive API request."
        case .invalidResponse:
            return "Invalid response from Drive API."
        case .http(let code, let body):
            if code == 401 || code == 403 {
                return "Drive access denied (\(code)). Sign out and sign in again, ensuring Drive readonly scope is granted."
            }
            let snippet = body.prefix(200)
            return "Drive API error \(code): \(snippet)"
        }
    }
}
