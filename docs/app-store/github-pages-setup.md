# HoopLife GitHub Pages Setup

HoopLife's public App Store URLs are served from the repository `docs/` folder.

## Public URLs

After GitHub Pages is enabled, use these URLs in App Store Connect:

- Support URL: `https://acewang377.github.io/HoopLife-App/support/`
- Privacy Policy URL: `https://acewang377.github.io/HoopLife-App/privacy/`
- Terms of Use URL: `https://acewang377.github.io/HoopLife-App/terms/`
- Landing page: `https://acewang377.github.io/HoopLife-App/`
- Support email: `admin@acezerotrading.com`

## Enable GitHub Pages

1. Open `https://github.com/AceWang377/HoopLife-App/settings/pages`.
2. Under **Build and deployment**, set **Source** to **Deploy from a branch**.
3. Set **Branch** to `main`.
4. Set folder to `/docs`.
5. Click **Save**.
6. Wait for GitHub Pages to finish building. The site normally becomes available within a few minutes.

## App Store Connect Fields

Use the same public URLs:

- **Support URL**: `https://acewang377.github.io/HoopLife-App/support/`
- **Privacy Policy URL**: `https://acewang377.github.io/HoopLife-App/privacy/`

For App Privacy answers, keep the release aligned with the current app behavior:

- No account required.
- No third-party advertising.
- No cross-app tracking.
- Location is used only when the user taps the locate button, to center the map while the app is open.
- Saved courts stay on device.
- Network requests fetch court records from the hosted court database.

Update this page before release if HoopLife adds accounts, submissions, analytics, payments, or photo uploads.
