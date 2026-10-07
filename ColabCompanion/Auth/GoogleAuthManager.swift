import Foundation
import UIKit
import SwiftUI
import GoogleSignIn

@MainActor
final class GoogleAuthManager: ObservableObject {
    @Published private(set) var isSignedIn = false
    @Published private(set) var userEmail: String?
    @Published private(set) var userName: String?
    @Published var lastError: String?

    private(set) var accessToken: String?

    init() {
        // Prefer explicit Config; Info.plist GIDClientID is the fallback the SDK also reads.
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Config.googleClientID)
    }

    func restorePreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.isSignedIn = false
                    // First launch / no saved session is normal
                    if (error as NSError).code == GIDSignInError.hasNoAuthInKeychain.rawValue {
                        return
                    }
                    self.lastError = error.localizedDescription
                    return
                }
                self.apply(user: user)
            }
        }
    }

    func signIn() {
        lastError = nil
        guard let presenter = Self.topViewController() else {
            lastError = "Unable to find a view controller to present sign-in."
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Config.googleClientID)

        GIDSignIn.sharedInstance.signIn(
            withPresenting: presenter,
            hint: nil,
            additionalScopes: Config.driveScopes
        ) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    let ns = error as NSError
                    if ns.code == GIDSignInError.canceled.rawValue {
                        return
                    }
                    self.lastError = error.localizedDescription
                    self.isSignedIn = false
                    return
                }
                self.apply(user: result?.user)
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        userEmail = nil
        userName = nil
        accessToken = nil
        lastError = nil
    }

    /// Refresh token if needed before Drive API calls.
    func freshAccessToken() async throws -> String {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw AuthError.notSignedIn
        }
        let refreshed = try await user.refreshTokensIfNeeded()
        let token = refreshed.accessToken.tokenString
        guard !token.isEmpty else {
            throw AuthError.missingToken
        }
        accessToken = token
        return token
    }

    private func apply(user: GIDGoogleUser?) {
        guard let user else {
            isSignedIn = false
            return
        }
        userEmail = user.profile?.email
        userName = user.profile?.name
        accessToken = user.accessToken.tokenString
        isSignedIn = true
        lastError = nil
    }

    private static func topViewController(
        base: UIViewController? = nil
    ) -> UIViewController? {
        let base = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

enum AuthError: LocalizedError {
    case notSignedIn
    case missingToken

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Not signed in."
        case .missingToken: return "Missing access token."
        }
    }
}
