import Foundation

struct NotebookItem: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let mimeType: String
    let modifiedTime: Date?
    let webViewLink: String?

    var displayName: String {
        name.hasSuffix(".ipynb") ? String(name.dropLast(6)) : name
    }

    var colabURL: URL {
        Config.colabURL(fileId: id)
    }
}

struct DriveFileListResponse: Decodable {
    let files: [DriveFile]?
    let nextPageToken: String?
}

struct DriveFile: Decodable {
    let id: String
    let name: String
    let mimeType: String
    let modifiedTime: String?
    let webViewLink: String?
}
