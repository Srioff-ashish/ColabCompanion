# Architecture — Colab Companion

## What this app is

A thin **iOS companion**: authenticate → list Colab notebooks on Drive → **hand off** to Colab in Safari.

```text
┌─────────────────┐     OAuth + Drive readonly      ┌──────────────────┐
│  ColabCompanion │ ──────────────────────────────► │  Google Drive API│
│  (SwiftUI iOS)  │ ◄────────────────────────────── │  files.list      │
└────────┬────────┘         notebook metadata       └──────────────────┘
         │
         │  UIApplication.open
         │  https://colab.research.google.com/drive/{fileId}
         ▼
┌─────────────────┐
│  Safari / Colab │  full notebook UI + runtime (user’s Google session)
└─────────────────┘
```

## Why open Safari instead of embedding Colab?

1. **Colab is a web product** — editing, GPU/TPU runtimes, outputs, and sharing live in the browser. There is no supported public “Colab native iOS SDK” for running cells.
2. **Deep link is enough** — `https://colab.research.google.com/drive/{fileId}` is the stable Drive→Colab entry point. Safari (or the default browser) already has the user’s Google cookies / session.
3. **Least privilege** — this app only needs **Drive readonly** to discover file IDs and names. It never downloads notebook JSON, never executes code, and never needs Colab-specific write scopes.
4. **Security & maintenance** — embedding a WebView that hosts Colab would duplicate auth complexity (cookie jars, third-party redirects) without a better UX than Safari.

## Companion vs Colab API vs MCP

| Layer | Role | This app? |
|-------|------|-----------|
| **Companion (this)** | Discover notebooks on Drive; open Colab URL | Yes |
| **Colab web / runtime** | Edit & execute notebooks | No — Safari |
| **Drive API** | List/search files by MIME / name | Yes (readonly) |
| **Colab REST / unofficial APIs** | Manipulate notebook content or kernels | **Not used** |
| **MCP / automation agents** | Server-side tools (e.g. open Colab in a browser automation session, sync notebooks) | Separate from this iOS UI |

An MCP or desktop agent might *drive* Colab or Drive with broader credentials for automation. This iPhone app stays a **personal launcher**: human taps a notebook → Colab opens where Google intends notebooks to run.

## Module map

| Module | Responsibility |
|--------|----------------|
| `Config` | Client ID placeholders, scopes, Colab URL helper |
| `GoogleAuthManager` | GIDSignIn, token refresh, sign-out |
| `DriveService` | Paginated `files.list` with Colab / `.ipynb` query |
| `NotebookListView` | List, pull-to-refresh, empty/error, open URL |
| `SignInView` | First-run Google sign-in |

## Data flow

1. `GIDSignIn` obtains an access token including `drive.readonly`.
2. `DriveService` calls `GET https://www.googleapis.com/drive/v3/files` with query:

   ```text
   (mimeType='application/vnd.google-colaboratory'
     or mimeType='application/x-ipynb+json'
     or name contains '.ipynb')
   and trashed=false
   ```

3. UI shows `NotebookItem` rows (id, name, modifiedTime).
4. Tap → `https://colab.research.google.com/drive/{id}` in Safari.

## Non-goals

- In-app notebook editing or cell execution  
- Uploading / creating notebooks  
- Background sync or push notifications  
- Replacing Google’s Colab mobile web experience  

If those are needed later, prefer extending **Drive** for file management and keep **execution** in Colab (Safari or `SFSafariViewController`), not a custom runtime.
