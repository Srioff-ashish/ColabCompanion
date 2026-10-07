import Foundation

/// OAuth / Google Sign-In configuration.
///
/// Replace PLACEHOLDER values with your own Google Cloud Console iOS OAuth client.
/// See README.md for setup steps. Never commit real client secrets.
enum Config {
    /// iOS OAuth 2.0 Client ID from Google Cloud Console
    /// Format: `123456789-abcdefg.apps.googleusercontent.com`
    static let googleClientID = "YOUR_IOS_CLIENT_ID.apps.googleusercontent.com"

    /// URL scheme = reversed client ID (Info.plist CFBundleURLSchemes)
    /// Example: client `123456789-abc.apps.googleusercontent.com`
    ///       → scheme `com.googleusercontent.apps.123456789-abc`
    static let googleURLScheme = "com.googleusercontent.apps.YOUR_IOS_CLIENT_ID"

    /// Drive scopes: list notebooks (readonly). No write access.
    static let driveScopes = [
        "https://www.googleapis.com/auth/drive.readonly"
    ]

    /// Colab notebook MIME type on Google Drive
    static let colabMimeType = "application/vnd.google-colaboratory"

    /// Also match classic Jupyter notebooks that open in Colab
    static let ipynbMimeType = "application/x-ipynb+json"

    /// Deep-link template: open notebook in Colab (Safari / ASWebAuthenticationSession not required)
    static func colabURL(fileId: String) -> URL {
        URL(string: "https://colab.research.google.com/drive/\(fileId)")!
    }
}
