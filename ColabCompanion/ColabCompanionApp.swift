import SwiftUI
import GoogleSignIn

@main
struct ColabCompanionApp: App {
    @StateObject private var authManager = GoogleAuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    authManager.restorePreviousSignIn()
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var authManager: GoogleAuthManager

    var body: some View {
        Group {
            if authManager.isSignedIn {
                NotebookListView(authManager: authManager)
            } else {
                SignInView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authManager.isSignedIn)
    }
}
