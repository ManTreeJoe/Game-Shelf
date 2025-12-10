# Game Shelf

A beautiful, native macOS game library and launcher built with SwiftUI. Manage your ROM collection and Steam games in one place with a stunning dark synthwave aesthetic featuring VHS-style glitch effects, neon accents, and CRT scanlines.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-green)

## Features

### Core Functionality
- **Unified Game Library**: View ROMs and Steam games together in one beautiful interface
- **Multi-Platform Support**: Built-in support for 20+ platforms including NES, SNES, N64, PlayStation, GameCube, Wii, and more
- **Steam Integration**: Automatically detects installed Steam games and launches them directly
- **One-Click Launch**: Launch any game with your configured emulator or through Steam
- **Smart Onboarding**: First-run wizard helps you select platforms and automatically downloads recommended emulators

### Automatic Emulator Setup
- **Auto-Download Emulators**: GameShelf can download and configure emulators for you:
  - **OpenEmu** - NES, SNES, Game Boy, Genesis, and 15+ classic platforms
  - **Dolphin** - GameCube and Wii
  - **PPSSPP** - PlayStation Portable
  - **PCSX2** - PlayStation 2
- **Custom Emulators**: Add any emulator manually - just point to the .app and assign file extensions

### Visual Design
- **Synthwave Aesthetic**: Dark backgrounds with neon pink, cyan, and purple accents
- **VHS Effects**: Glitch animations, RGB split, tracking lines, and screen flicker
- **CRT Scanlines**: Authentic retro monitor look with phosphor glow
- **Animated Backgrounds**: Subtle color shifts and perspective grids
- **Neon Glow Effects**: Platform-specific color glows on hover

### Collections & Organization
- **Custom Collections**: Create playlists of your favorite games
- **Favorites**: Quick access to games you love
- **Recently Played**: Track your gaming sessions
- **Smart Search**: Filter by platform, name, or collection
- **Multiple Sort Options**: By name, platform, date added, or file size
- **Grid & List Views**: Switch between view modes

### Cover Art
- **Auto-Scraping**: Fetches cover art from LibRetro Thumbnails database
- **Steam Artwork**: Automatically loads artwork for Steam games
- **Image Cache**: Fast loading with persistent disk cache
- **Manual Override**: Pick custom artwork for any game
- **Batch Fetch**: Download artwork for your entire library at once

### Save File Management
- **Save Detection**: Scans emulator save directories to find your saves
- **Save Browser**: View all save files for each game in the detail view
- **Quick Access**: Open save locations in Finder
- **Backup**: Export save files for safekeeping

### Play Statistics
- **Session Tracking**: Records play time for each game
- **Dashboard View**: Charts and stats for your gaming habits
- **Per-Game Stats**: Total time, session count, average session length
- **Historical Data**: Weekly/monthly play time tracking

### Input Support
- **Gamepad Navigation**: Navigate the entire UI with a controller
- **Keyboard Shortcuts**: Full keyboard navigation support
- **Quick Launch**: Spotlight-style search (⌘K) to find and launch games instantly

### Game Details
- **Full-Screen Detail View**: Double-click any game for expanded info
- **Rich Metadata**: File info, play stats, collections, save files
- **Quick Actions**: Play, favorite, add to collection, show in Finder
- **Platform Override**: Manually change a game's detected platform

## Getting Started

### First Launch
1. Open `GameShelf.xcodeproj` in Xcode 15+
2. Build and run (⌘R)
3. Follow the onboarding wizard:
   - Select which platforms you want to play
   - GameShelf will download and configure emulators automatically
   - Add your ROM directories
4. Your library is ready!

### Manual Setup
1. Click the **gear icon** to open Settings
2. **Add ROM Directories**: Point to your ROM folders
3. **Configure Emulators**: Add emulators for each file type
4. Browse your library and start playing!

## Adding Emulators Manually

1. Go to **Settings → Emulators**
2. Click **Add Emulator**
3. Enter a name (e.g., "OpenEmu", "Dolphin")
4. Click **Browse** to select the .app file
5. Add file extensions this emulator handles
6. Optionally restrict to specific platforms

### Recommended Emulators for macOS

| Platform | Recommended Emulator |
|----------|---------------------|
| NES/SNES/GBA/etc. | [OpenEmu](https://openemu.org/) |
| GameCube/Wii | [Dolphin](https://dolphin-emu.org/) |
| PlayStation 2 | [PCSX2](https://pcsx2.net/) |
| PSP | [PPSSPP](https://www.ppsspp.org/) |
| Nintendo DS | [DeSmuME](https://desmume.org/) |
| PlayStation | [DuckStation](https://www.duckstation.org/) |
| Nintendo Switch | [Ryujinx](https://ryujinx.org/) |

## Steam Integration

GameShelf automatically detects your Steam library:
- Scans `~/Library/Application Support/Steam/steamapps/`
- Displays Steam games alongside your ROMs
- Launches games via Steam's URL protocol
- Fetches artwork from Steam's CDN

## Supported Platforms

| Platform | Extensions |
|----------|------------|
| NES | `.nes`, `.nez` |
| SNES | `.sfc`, `.smc` |
| Game Boy | `.gb` |
| Game Boy Color | `.gbc` |
| Game Boy Advance | `.gba` |
| Nintendo 64 | `.n64`, `.z64`, `.v64` |
| GameCube | `.gcm`, `.iso` |
| Wii | `.wbfs`, `.wad`, `.nkit` |
| Nintendo DS | `.nds` |
| Nintendo 3DS | `.3ds`, `.cia` |
| Nintendo Switch | `.nsp`, `.xci` |
| PlayStation | `.bin`, `.cue`, `.chd` |
| PlayStation 2 | `.iso`, `.chd` |
| PSP | `.cso`, `.iso`, `.pbp` |
| Sega Genesis | `.md`, `.gen` |
| Sega Master System | `.sms` |
| Game Gear | `.gg` |
| Sega Saturn | `.cue`, `.chd` |
| Dreamcast | `.cdi`, `.gdi` |
| Steam | Auto-detected |

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘K | Quick Launch (search & play) |
| ⌘, | Open Settings |
| ⌘R | Refresh Library |
| ⌘F | Focus Search |
| ↑↓←→ | Navigate games |
| Enter | Launch selected game |
| Double-click | Open Game Details |

## Architecture

```
GameShelf/
├── GameShelfApp.swift          # App entry point
├── ContentView.swift           # Main window with sidebar
├── Theme.swift                 # Synthwave color system & effects
│
├── Models/
│   ├── ROM.swift               # ROM/game data model
│   ├── Platform.swift          # Platform definitions
│   ├── AppConfig.swift         # Configuration & persistence
│   ├── Collection.swift        # Custom collections
│   ├── GameMetadata.swift      # Scraped metadata
│   └── PlaySession.swift       # Play time tracking
│
├── Views/
│   ├── LibraryView.swift       # Main library grid
│   ├── GameCardView.swift      # Individual game cards
│   ├── GameDetailView.swift    # Full game details modal
│   ├── SidebarView.swift       # Collections sidebar
│   ├── SettingsView.swift      # Settings panel
│   ├── OnboardingView.swift    # First-run wizard
│   ├── StatsView.swift         # Per-game statistics
│   └── StatsDashboardView.swift # Global stats dashboard
│
├── ViewModels/
│   └── LibraryViewModel.swift  # Main state management
│
├── Services/
│   ├── ROMScanner.swift        # Async ROM scanning
│   ├── SteamScanner.swift      # Steam library detection
│   ├── EmulatorLauncher.swift  # Game launching
│   ├── EmulatorDownloadManager.swift # Auto-download emulators
│   ├── ArtworkScraper.swift    # Cover art fetching
│   ├── ImageCache.swift        # Image caching
│   ├── SaveManager.swift       # Save file management
│   ├── GamepadController.swift # Controller input
│   └── SessionTracker.swift    # Play time tracking
│
└── Effects/
    ├── Animations.swift        # Animation presets
    ├── GlitchEffect.swift      # VHS/glitch effects
    └── ScanlineOverlay.swift   # CRT effects
```

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Apple Silicon or Intel Mac

## Privacy

Game Shelf runs entirely locally. No data is sent to external servers except:
- Cover art requests to LibRetro Thumbnails (thumbnails.libretro.com)
- Steam artwork from Steam's CDN (steamcdn-a.akamaihd.net)

All your ROM paths, play statistics, and settings are stored locally in:
`~/Library/Application Support/GameShelf/`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ and neon lights**
