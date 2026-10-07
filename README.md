# Colab Companion

Minimal SwiftUI iPhone app that lists your **Google Colab** notebooks from **Google Drive** and opens them in **Safari** at:

```text
https://colab.research.google.com/drive/{fileId}
```

It is a **companion launcher**, not a Colab runtime or notebook editor. See [ARCHITECTURE.md](ARCHITECTURE.md).

## Requirements

- macOS with **Xcode 15+** (iOS 17 SDK)
- Apple Developer account (free for Simulator; paid for device if needed)
- A **Google Cloud** project with an **iOS OAuth client**

## What it does

1. **Sign in with Google** (`GoogleSignIn-iOS` via Swift Package Manager)
2. Requests **Drive readonly** scope and lists notebooks:
   - MIME `application/vnd.google-colaboratory`
   - MIME `application/x-ipynb+json`
   - Files whose name contains `.ipynb`
3. **Tap** a row → opens the Colab deep link in Safari
4. **Pull to refresh**, **empty / error** states, **sign out**

## Open in Xcode

```bash
open /workspace/ColabCompanion/ColabCompanion.xcodeproj
```

(Or copy the folder to your Mac and open `ColabCompanion.xcodeproj`.)

On first open, Xcode resolves the SPM package **GoogleSignIn-iOS** (`https://github.com/google/GoogleSignIn-iOS`, 8.x).

1. Select the **ColabCompanion** scheme
2. Choose an **iOS 17+** Simulator or a device
3. Set your **Team** under Signing & Capabilities (target → Signing)
4. Complete Google OAuth setup below, then Run (⌘R)

## Google Cloud OAuth setup (required)

Do **not** commit real client IDs to git. Replace placeholders only on your machine.

### 1. Create / select a Cloud project

1. Open [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project (or pick an existing one)
3. **APIs & Services → Library** → enable **Google Drive API**

### 2. Configure the OAuth consent screen

1. **APIs & Services → OAuth consent screen**
2. User type: **External** (or Internal for Workspace-only)
3. App name, support email, developer contact
4. **Scopes → Add or remove scopes** → add:
   - `https://www.googleapis.com/auth/drive.readonly`
5. Add **test users** (your Google account) while the app is in Testing

### 3. Create an iOS OAuth client

1. **APIs & Services → Credentials → Create credentials → OAuth client ID**
2. Application type: **iOS**
3. Name: e.g. `Colab Companion iOS`
4. **Bundle ID** must match the Xcode target:

   ```text
   com.example.ColabCompanion
   ```

   Change the bundle ID in Xcode if you prefer; then use that same value here.

5. Create → copy the **Client ID**  
   Example shape: `123456789-abcdefg.apps.googleusercontent.com`

### 4. URL scheme = reversed client ID

Take the Client ID and reverse the domain suffix:

| Client ID | URL scheme |
|-----------|------------|
| `123456789-abc.apps.googleusercontent.com` | `com.googleusercontent.apps.123456789-abc` |

### 5. Paste placeholders in the project

Edit **both** places (keep them identical):

**A. `ColabCompanion/Config/Config.swift`**

```swift
static let googleClientID = "123456789-abc.apps.googleusercontent.com"
static let googleURLScheme = "com.googleusercontent.apps.123456789-abc"
```

**B. `ColabCompanion/Info.plist`**

- `GIDClientID` → same Client ID string  
- `CFBundleURLSchemes` → the **reversed** client ID  

Without a matching URL scheme, Google Sign-In cannot return to the app after OAuth.

### Required scopes

| Scope | Purpose |
|-------|---------|
| `https://www.googleapis.com/auth/drive.readonly` | List notebook metadata (id, name, mimeType, modifiedTime) |

No Drive write, no Colab execution API. Opening a notebook uses the public Colab web URL + the user’s Safari Google session.

## Run on Simulator / device

### Simulator

1. Complete OAuth placeholders
2. Select an iPhone simulator (iOS 17+)
3. Run ⌘R
4. Sign in with a **test user** Google account that owns Colab notebooks on Drive

### Physical device

1. Signing: select your Team; use a unique Bundle ID if `com.example.ColabCompanion` is taken
2. Update the **same** Bundle ID in Google Cloud iOS client (or create a new iOS client)
3. Trust the developer certificate on the device if prompted
4. Run from Xcode

## Project layout

```text
ColabCompanion/
├── ColabCompanion.xcodeproj
├── ColabCompanion/
│   ├── ColabCompanionApp.swift      # App entry, URL callback
│   ├── Config/Config.swift          # PLACEHOLDER client ID / scheme / scopes
│   ├── Auth/GoogleAuthManager.swift # GIDSignIn
│   ├── Drive/DriveService.swift     # Drive files.list
│   ├── Drive/NotebookItem.swift
│   ├── Views/SignInView.swift
│   ├── Views/NotebookListView.swift
│   ├── Views/EmptyStateView.swift
│   ├── Info.plist                   # URL scheme + GIDClientID placeholders
│   └── Assets.xcassets
├── README.md
├── ARCHITECTURE.md
└── .gitignore
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Sign-in returns immediately / error | Check Client ID + reversed URL scheme match; Bundle ID matches Cloud Console |
| `403` / Drive access denied | Consent screen includes `drive.readonly`; re-sign-in; user is a test user |
| Empty list | Create a notebook in Colab (saves to Drive); pull to refresh |
| SPM resolve fails | File → Packages → Reset Package Caches; network access to GitHub |

## License

Sample / starter project — use and modify freely. Google Sign-In and Drive APIs are subject to Google’s terms.
