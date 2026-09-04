# T3 Code Queue

Personal macOS release channel for T3 Code with the message-queue pull request enabled.

- The Mac mini builds from `pingdotgg/t3code` PR #2829 while it is open.
- After the PR merges, builds automatically follow upstream `main`.
- Updates download in the background and install when T3 Code Queue quits.
- The queue app has a separate bundle ID, updater cache, Electron profile, and URL scheme.
- It uses the existing `~/.t3` backend state so threads never split into divergent copies.
- Run T3 Code Queue as the only active T3 desktop app on each Mac.
- It deliberately retains T3's macOS Safe Storage namespace so the inherited encrypted connection catalog remains readable without exposing or duplicating Keychain secrets.
- The one-time migration archives the former `.t3-queue` snapshot instead of merging or overwriting either database.

Release artifacts are generated locally on the Mac mini. No credentials are stored in this repository.
