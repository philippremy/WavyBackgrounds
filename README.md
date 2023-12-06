<p align="center">
  <img src=".github/icon.png" alt="logo" width="256" alt="Das Logo der Software Kampfrichtereinsatzpläne" />
</p>

# WavyBackgrounds
A simple program to emulate the dynamic desktop wallpapers from macOS Sonoma.

## Functionality
- Fetch the original macOS Sonoma background videos independently from the system
- Ability to apply multiple dynamic backgrounds to different spaces (i.e., the current (active) space will be picked)
- Remove dynamic backgrounds (either all at once or the one on the active space)
- Control the app without a main window by using the System Tray

## Dependencies
- Rust (Nightly-Chain)
- Node (npm)

## Building the application
Note that cross-compilation is not possible, as the linker requires some of Apple's Frameworks (Foundation, AppKit, AVFoundation) to be present at build-time.
This app will only run correctly on macOS 14.0 or later.
```bash
$ git clone https://github.com/philippremy/WavyBackgrounds.git
$ cd WavyBackgrounds && cd WavyBackgroundsClient
$ npm install
$ npm run tauri build                                      # Just build the current architecture
$ npm run tauri build -- --target universal-apple-darwin   # Build a universal binary (requires both Rust Chains to be installed!)
$ npm run tauri dev                                        # Build a live development build with Hot Reloading
```
