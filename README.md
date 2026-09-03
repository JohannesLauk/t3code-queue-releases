# T3 Code Queue

Personal macOS release channel for T3 Code with the message-queue pull request enabled.

- The Mac mini builds from `pingdotgg/t3code` PR #2829 while it is open.
- After the PR merges, builds automatically follow upstream `main`.
- Updates download in the background and install when T3 Code Queue quits.
- The queue app has a separate bundle ID, updater cache, Electron profile, URL scheme, and `~/.t3-queue` backend state.
- Initial setup copies the official app's existing state once. Later writes remain isolated, so both apps can run without corrupting each other.

Release artifacts are generated locally on the Mac mini. No credentials are stored in this repository.
