# Security

This repository is public. **Do not commit API keys.**

`outrunn/Resources/Info.plist` uses placeholders:

- `PASTE_SMARTSPECTRA_API_KEY`
- `PASTE_GEMINI_API_KEY`
- `PASTE_GEMINI_PROJECT_NUMBER`
- `PASTE_IOS_CLIENT_ID` (Google Sign-In)

Copy `Secrets.xcconfig.example` to `Secrets.xcconfig` for local notes if you want, and paste the same values into `Info.plist` on your machine. `Secrets.xcconfig` is gitignored.

If this repo ever contained live keys (it did before they were stripped), **rotate those keys** in Presage, Google Cloud / Gemini, and Google Sign-In. Treat anything that was on `main` as compromised.
