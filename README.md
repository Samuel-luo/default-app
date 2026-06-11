# DefaultApp

DefaultApp is a native macOS application designed to easily manage default program associations for file extensions. It provides a clean, modern, and highly interactive user interface to view and modify which application opens specific file types globally across the system.

## Key Features

- **Liquid Glass UI**: Designed with a high-fidelity "liquid glass" visual style, featuring floating control capsules, subtle gradient background blurs, specular highlights, and 3D-like borders.
- **Global Association Management**: Query and update default applications for common and custom file extensions globally using macOS system APIs (`NSWorkspace` and Uniform Type Identifiers).
- **Intelligent App Scanner**: Scans installed applications on your Mac, parses their `Info.plist` declarations (`UTExportedTypeDeclarations` and `UTImportedTypeDeclarations`), and automatically extracts supported file extensions.
- **Custom Extensions**: Allows users to manually add and manage custom file extensions that are not pre-defined.
- **Polished Interactive Experience**:
  - **Custom Hand Cursor**: Interactive elements (list rows, buttons, segmented pickers) display a pointing hand cursor on hover, which remains stable during clicks and selections.
  - **Smart Focus Dismissal**: Clicking outside the search bar or on empty background areas automatically dismisses keyboard/search focus.
  - **Unified Title Bar**: Integrated controls and traffic lights blend seamlessly into the window chrome.
- **Single-Window Lifecycle**: Operates as a single-window utility that automatically terminates when its main window is closed.

## Technology Stack

- **SwiftUI**: Modern declarative UI framework.
- **AppKit**: For advanced system integration, including `NSWorkspace` for default app configuration, `UTType` for file type handling, and custom cursor/focus management.
- **Swift 5.9+ / Observation**: Utilizes the modern `@Observable` framework for reactive data binding.
- **Target Platform**: macOS 14.0+ (takes advantage of macOS 15.0+ native `pointerStyle` API with reliable AppKit fallbacks for older versions).

## Project Structure

```
DefaultApp/
├── DefaultApp.swift                  # Application entry point & lifecycle delegate
├── DefaultApp.entitlements           # App security configuration (Sandbox disabled)
├── Models/
│   ├── FileTypeItem.swift            # Model representing a file extension and its UTI
│   ├── FileTypeSource.swift          # Enum representing common vs custom extensions
│   └── CommonExtensions.swift        # Pre-defined list of common macOS file extensions
├── Services/
│   ├── DefaultAppService.swift       # NSWorkspace-backed service to get/set default apps
│   ├── FileTypeCatalog.swift         # Catalog manager for scanning and saving extensions
│   └── InstalledAppExtensionScanner.swift # Scanner to extract supported UTIs from installed apps
├── Views/
│   ├── ContentView.swift             # Root split-view container
│   ├── FileTypeListView.swift        # Sidebar list with floating Liquid Glass controls
│   ├── AppPickerView.swift           # Detail panel for choosing default applications
│   ├── AddExtensionSheet.swift       # Sheet to add custom file extensions
│   ├── LiquidGlassStyle.swift        # View modifiers for glass panels and hand cursors
│   ├── SidebarToggle.swift           # Helper for programmatic sidebar toggling
│   └── FileTypeListTab.swift         # Tab enum for common vs custom extensions
└── Assets.xcassets/                  # App icon and accent color assets
```

## How to Build and Run

### Requirements
- macOS 14.0 or later
- Xcode 15.0 or later

### Running in Xcode
1. Clone this repository to your local machine.
2. Open `DefaultApp.xcodeproj` in Xcode.
3. Select the `DefaultApp` scheme and a Mac run destination.
4. Press `Cmd + R` to build and run the application.

### Building a Distributable DMG
A build script is provided in the `Scripts` directory to compile the application and package it into a `.dmg` file.

#### Unsigned Local Build
To build an unsigned DMG for local testing:
```bash
./Scripts/build-dmg.sh
```
The output DMG will be generated at `build/DefaultApp.dmg`.

#### Signed and Notarized Release Build
To build a signed and notarized DMG for distribution, run the script with the `--release` flag and provide your Apple Developer credentials:
```bash
DEVELOPMENT_TEAM=YOUR_TEAM_ID \
SIGNING_IDENTITY="Developer ID Application: Your Name (YOUR_TEAM_ID)" \
NOTARY_PROFILE=your-notary-profile-name \
./Scripts/build-dmg.sh --release
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
