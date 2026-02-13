# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Noctalia is a beautiful, minimal desktop shell for Wayland built on **Quickshell** (Qt/QML framework). It provides native support for Niri, Hyprland, Sway, MangoWC, and labwc compositors with a modular, plugin-based architecture.

**Resources:**
- Documentation: https://docs.noctalia.dev
- Development Guidelines: https://docs.noctalia.dev/development/guideline
- Discord: https://discord.noctalia.dev
- Plugins: https://noctalia.dev/plugins/

## Development Commands

### Environment Setup

```bash
# Enter Nix development environment (recommended)
nix develop

# Development environment includes:
# - quickshell (runtime)
# - nixfmt, statix, deadnix (Nix formatting/linting)
# - shfmt, shellcheck (Shell formatting/linting)
# - jsonfmt (JSON formatting)
# - lefthook (Git hooks)
# - Qt6 tools (qmlfmt, qmllint, qmlls)
```

### Running Noctalia

```bash
# Run from source (after entering nix develop)
quickshell

# The shell.qml file is automatically discovered as the entry point
```

### Formatting & Linting

```bash
# Format QML files
./Scripts/dev/qmlfmt.sh

# Compile shaders (GLSL to .qsb binary format)
./Scripts/dev/shaders-compile.sh

# Format Nix files
nixfmt flake.nix nix/

# Lint Nix files
statix check
deadnix
```

### Testing

```bash
# Send test notifications
./Scripts/dev/notifications-test.sh

# Test notification replacement
./Scripts/dev/notifications-test-replace.sh
```

### Translations

```bash
# Push translations to source
./Scripts/dev/i18n-push.sh

# Pull translations from source
./Scripts/dev/i18n-pull.sh
```

### Building

```bash
# Build with Nix
nix build

# The result will be in ./result/
```

## Architecture Overview

### Entry Point

`shell.qml` is the application entry point. It:
1. Initializes the plugin system via `PluginRegistry.init()`
2. Loads Settings, ShellState, and I18n translations
3. Initializes all services in sequence
4. Loads main UI components (Bar, Dock, Panels, Notifications, etc.)
5. Shows setup wizards if needed

### Core Directory Structure

- **Commons/** - Singleton utilities (Settings, Style, Color, I18n, Logger, Migrations)
- **Services/** - System-level services across categories (Compositor, Hardware, Media, Networking, Theming, UI)
- **Modules/** - Major UI components (Bar, Dock, Panels, LockScreen, Notification, OSD, Toast, Background, DesktopWidgets)
- **Widgets/** - Reusable QML components (N-prefixed: NButton, NSlider, NPopupContextMenu, etc.)
- **Assets/** - Resources (colors, fonts, translations, settings-default.json, templates)
- **Shaders/** - GLSL shaders compiled to .qsb format

### Configuration & State

**Settings** (`Commons/Settings.qml`):
- User configuration stored in `~/.config/noctalia/settings.json`
- Current version: 47 (check `Commons/Migrations/MigrationRegistry.qml` for latest)
- Default settings in `Assets/settings-default.json`
- Debounced saves (500ms) to prevent excessive IO

**ShellState** (`Commons/ShellState.qml`):
- Runtime ephemeral state in `~/.cache/noctalia/shell-state.json`
- Not meant for user editing
- Stores: display scales, notification state, changelog state, color scheme cache

**Migrations** (`Commons/Migrations/`):
- `MigrationRegistry.qml` maps version numbers to migration components
- Each migration has a `migrate(data)` function that transforms settings

### Services Architecture

Services are Singletons providing system-level functionality. Key categories:

**Compositor Services**: Wayland integration (Niri, Hyprland, Sway, Labwc, Mango)
- Provide workspace/output management, workspace switching, monitor info

**UI Services**: Noctalia-specific UI management
- `BarService` - Bar visibility & widget management
- `PanelService` - Panel lifecycle, positioning, rendering
- `PluginService` - Plugin loading & hot-reload
- `WallpaperService` - Wallpaper management
- `ToastService`, `TooltipService` - UI feedback

**System Services**: OS integration
- `NotificationService` - D-Bus notifications (freedesktop.org spec)
- `AudioService` - PulseAudio/PipeWire integration
- `BatteryService`, `BrightnessService` - Hardware control
- `NetworkService`, `VPNService`, `BluetoothService` - Connectivity

**Theming Services**: Visual customization
- `ColorSchemeService` - Color scheme management & download
- `AppThemeService` - GTK theme integration
- `TemplateProcessor` - Template rendering for config generation

### Plugin System

**Location**: `~/.config/noctalia/plugins/`

**Plugin Discovery**:
- `PluginRegistry` scans disk for plugin directories
- Loads `manifest.json` from each plugin
- State stored in `~/.config/noctalia/plugins.json` (v2 format)

**Plugin Identification**:
- Official plugins: plain ID (e.g., "catwalk")
- Custom source plugins: hash-prefixed ID (e.g., "a1b2c3:my-plugin")
- Main source: https://github.com/noctalia-dev/noctalia-plugins

**Plugin Capabilities**:
- Bar widgets with drag-drop support
- Settings panel integration
- Custom buttons with IPC commands
- Access to all shell services
- Translation support
- Desktop widget support

**Plugin Lifecycle**:
1. PluginRegistry discovers and loads manifests
2. PluginService instantiates Main.qml for enabled plugins
3. Plugin API object provides access to services
4. Hot-reload in debug mode watches for file changes

### Module Architecture

Modules are self-contained UI components:

**MainScreen** (`Modules/MainScreen/`): Core orchestrator for per-screen UI
- Manages Bar, Panels, Backgrounds, Exclusion Zones
- Uses `AllScreens.qml` with `Variants` to create per-screen instances

**Bar** (`Modules/Bar/`): Main taskbar
- Multi-screen support
- Horizontal/vertical layout
- Density options: mini, compact, default, comfortable
- Widget sections: left, center, right
- Display modes: always_visible, auto_hide, exclusive

**Panels** (`Modules/Panels/`): Popup panels managed by `PanelService`
- Each panel is a subdirectory with its own QML components
- Rendered via `SmartPanel.qml` which handles positioning and animations

**Dock** (`Modules/Dock/`): Application launcher
- Pinned apps with active window indicators
- Auto-hide/exclusive display modes
- Per-screen configuration

**Other Modules**: Notification, OSD, LockScreen, Toast, Tooltip, Background, DesktopWidgets

### Multi-Screen Support

All major components support multi-screen via `Variants`:

```qml
Variants {
    model: Quickshell.screens
    delegate: MainScreen {
        screen: modelData
    }
}
```

This creates per-screen instances of Bar, Dock, Notifications, Backgrounds, etc.

### Data Flow Patterns

**Initialization Sequence**:
```
shell.qml
  → Settings.load()
  → ShellState.load()
  → I18n.load()
  → PluginRegistry.init()
  → Load main UI components
  → Initialize services
  → PluginService.init()
  → Show wizards
```

**Settings Change Flow**:
```
Settings.data.bar.position = "bottom"
  → FileView detects change
  → saveTimer debounces 500ms
  → JSON written to disk
  → Observers react (MainScreen, Bar, etc.)
```

**Notification Flow**:
```
D-Bus → NotificationService.handleNotification()
  → Add to activeList
  → Notification.qml renders
  → Animation
  → Remove from activeList
  → Save to history
```

### Design System

**Color** (`Commons/Color.qml`):
- Material Design 3 naming with 'm' prefix (mPrimary, mOnPrimary, etc.)
- Key colors: Primary, Secondary, Tertiary, Error, Surface
- Animated transitions between schemes (750ms)

**Style** (`Commons/Style.qml`):
- Font sizes: XXS (8px) to XXXL (24px)
- Font weights: Regular, Medium, SemiBold, Bold
- Radius: XXXS to L (configurable via radiusRatio)
- Margins: XXS to XL
- Animations: Faster to Slowest
- Bar heights: Density-based (mini/compact/default/comfortable)
- DPI scaling support

### Localization

**I18n** (`Commons/I18n.qml`):
- 19 languages supported
- Translations in `Assets/translations/`
- Format: JSON with nested keys
- Auto-detects system language
- Plugin translation support

## Important Development Concepts

### Working with Settings

Settings are version-controlled and migrated:
1. Current version is 47 (check `Commons/Settings.qml`)
2. When adding new settings, increment version
3. Create new migration file in `Commons/Migrations/`
4. Register in `MigrationRegistry.qml`
5. Update `Assets/settings-default.json`

### Creating Bar Widgets

Bar widgets must be registered in `BarWidgetRegistry`:
1. Create widget QML in `Modules/Bar/Widgets/`
2. Define widget metadata (name, category, icon)
3. Widget receives `modelData` with shell screen context
4. Use Settings to persist widget-specific config

### Creating Panels

Panels are managed by `PanelService`:
1. Create panel QML in `Modules/Panels/`
2. Panel can be popup (from bar button) or window (Settings)
3. Use `PanelService.togglePanel()` to show/hide
4. Panel positioning handled automatically

### Working with Services

Services are Singletons:
1. Import service: `import "qrc:/Services/Category/ServiceName.qml"`
2. Access directly: `ServiceName.property` or `ServiceName.method()`
3. Connect to signals: `ServiceName.onSignalName: { ... }`
4. Services initialize in `shell.qml` startup sequence

### Performance Considerations

- Use `Loader` for expensive components
- Defer loading with `asynchronous: true`
- Settings saves are debounced (500ms)
- Animations can be disabled in performance mode
- Multi-screen creates per-screen instances

### Compositor Support

Each compositor has its own service:
- `NiriService` - Niri compositor
- `HyprlandService` - Hyprland compositor
- `SwayService` - Sway compositor
- `LabwcService` - Labwc compositor
- `MangoService` - MangoWC compositor

All inherit from `CompositorService` base interface providing:
- `workspaces` - List of workspace objects
- `switchToWorkspace(id)` - Switch workspace
- `monitors` - Monitor information
- Workspace/window events

### IPC System

`IPCService` handles external commands:
- `bar toggle` - Toggle bar visibility
- `settings toggle` - Toggle settings panel
- Custom button commands via `CustomButtonIPCService`

Used for shell control from external scripts/keybindings.

## Nix Integration

### Package Structure

- `nix/package.nix` - Build definition
- `nix/home-module.nix` - Home Manager integration
- `nix/nixos-module.nix` - NixOS integration
- `nix/shell.nix` - Development environment

### Home Manager Configuration

Supports declarative configuration:
- Settings (via `programs.noctalia-shell.settings`)
- Colors (via `programs.noctalia-shell.colors`)
- Plugins (via `programs.noctalia-shell.plugins`)
- User templates (via `programs.noctalia-shell.userTemplates`)

## Common Tasks

### Adding a New Widget

1. Create QML file in `Modules/Bar/Widgets/MyWidget.qml`
2. Register in `BarWidgetRegistry.qml`
3. Add default settings to `Assets/settings-default.json`
4. Test with hot-reload in development

### Adding a New Service

1. Create service in appropriate `Services/` subdirectory
2. Use `pragma Singleton` directive
3. Initialize in `shell.qml` startup sequence
4. Document in service file header

### Debugging

- Use `Logger.debug()`, `Logger.info()`, `Logger.warn()`, `Logger.error()`
- Check `~/.config/noctalia/settings.json` for configuration
- Check `~/.cache/noctalia/shell-state.json` for runtime state
- Quickshell output goes to stdout/stderr

### Template System

Templates are used for generating compositor configs:
- Location: `Assets/templates/`
- Format: Jinja2-like syntax
- Processor: `TemplateProcessor` service
- Used for: Hyprland, Sway configs with Noctalia-aware colors/settings

## Key Dependencies

- **Quickshell** - Qt/QML framework for Wayland shells (https://quickshell.outfoxxed.me/)
- **Qt6** - Base framework; see `nix/package.nix` for full dependency list
