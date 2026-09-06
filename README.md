# Divine Increase — Native App (Phase 1)

This is the start of your native Android app for the Divine Increase Business
Network. It's built with Flutter, and GitHub Actions builds the installable
`.apk` for you automatically — you never need to install Android Studio or
touch Gradle.

**What's included in this phase:** the Splash screen, Sign In / Sign Up,
a local device PIN lock, and the Home dashboard shell — matching your mockup.
The Home screen currently shows sample placeholder businesses; Phase 2 will
connect it to your real Firestore data so anything you add as admin shows up
automatically.

**Not included yet:** Google Sign-In (needs one extra one-time setup step —
see Phase 2 below), and the remaining screens (Directory, Wallet, Prayer,
Events, Chat, Testimonies, Careers, Notifications, Settings, admin panels).
We'll build those next, screen by screen.

## How the automatic build works

Notice there's no `android/` folder in this project. That's intentional —
Android's build tooling changes format every so often, so instead of hand
writing files that could go stale, the GitHub Actions workflow generates a
fresh, guaranteed-current `android/` folder on every run, then drops your
Firebase credentials into place. You just need to give it those credentials
once, as GitHub "secrets."

## One-time setup

### 1. Push this project to a GitHub repo
Create a new repository on GitHub and push everything in this folder to it
(the `.github/workflows/build-apk.yml` file must end up at that exact path).

### 2. Create/open your Firebase project
If your website already uses Firebase (it does — spiritus-sanctus-ignis.web.app
is Firebase Hosting), go to https://console.firebase.google.com and open that
same project, so the app and website eventually share the same data.

### 3. Register the Android app in Firebase
In Firebase Console → Project Settings → "Your apps" → Add app → Android.
- **Android package name must be exactly:** `com.spiritussanctusignis.divine_increase`
  (this has to match exactly, or the app won't be able to connect)
- You can skip downloading `google-services.json` — we don't need it with
  this setup.

### 4. Turn on Email/Password sign-in
In Firebase Console → Authentication → Sign-in method → enable **Email/Password**.
(Your website currently only offers Google sign-in — enabling this additionally
lets the app's Sign Up/Sign In screens work as designed. We'll add Google
Sign-In to the app in Phase 2.)

### 5. Collect 5 values from Firebase Console → Project Settings → General
Scroll to "Your apps" → your new Android app, and find:
| Value | Where to find it |
|---|---|
| API Key | Shown as part of the app's config snippet |
| App ID | Format like `1:1234567890:android:abcdef` |
| Project ID | Also shown at the top of Project Settings |
| Storage Bucket | e.g. `your-project.appspot.com` |
| Messaging Sender ID | This is your "Project number," shown near Project ID |

### 6. Add those as GitHub repo secrets
In your GitHub repo → Settings → Secrets and variables → Actions → New
repository secret. Create these 5, one value each:
- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_MESSAGING_SENDER_ID`

### 7. Run the build
Push any change to `main` (or go to the Actions tab → "Build APK" →
"Run workflow" to trigger it manually). When it finishes, open the workflow
run and download the `divine-increase-debug-apk` artifact — that's your `.apk`.

### 8. Install it on your phone
Transfer the `.apk` to an Android phone and open it. Android will ask you to
allow "install unknown apps" for whichever app you used to open the file
(e.g. Files or Chrome) — approve that once, then it installs normally.

> This is a **debug build** — perfectly fine for testing on your own phone
> right now. Before publishing to the Play Store later, we'll set up proper
> release signing (a one-time step involving a keystore file).

## What's next (tell me when you're ready for each)

- **Phase 2 — Real data:** wire the Home screen and a new Directory screen to
  your Firestore collections, so businesses you add as admin appear in the app.
- **Phase 3 — Google Sign-In:** needs your app's SHA-1 fingerprint registered
  in Firebase (I'll walk you through generating it).
- **Phase 4 — Remaining screens:** Wallet, Prayer, Events, Chat, Testimonies,
  Careers, Notifications, Settings, and admin tools.
