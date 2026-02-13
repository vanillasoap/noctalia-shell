# Feature Request: Configurable Animation Types and Easing for Noctalia Shell

## Goal

Add configurable animation **types** (slide, scale, fade, pop-in) and **easing curves** to Noctalia Shell. Currently both are hardcoded throughout the codebase. This change would centralize them in `Style.qml` and expose them through `settings.json`, giving users full control over animation behavior.

## Repository

https://github.com/noctalia-dev/noctalia-shell

---

## Overview

| Concept | What it controls | Current state | Proposed |
|---------|------------------|---------------|----------|
| **Animation Type** | What property animates (slide, scale, fade) | Hardcoded per-component | Configurable via settings |
| **Easing Curve** | Acceleration/deceleration function | Hardcoded (~100+ instances) | Configurable via settings |

**Priority:** Animation type is the higher-impact change — it fundamentally alters how things look. Easing is a refinement on top.

---

## Part 1: Animation Types

### Current Behavior

In `Modules/MainScreen/SmartPanel.qml`, animation type is determined by panel attachment mode:

| Panel Mode | Current Animation | Properties Animated |
|------------|-------------------|---------------------|
| Non-floating attached | Full slide from nearest edge | x/y position |
| Floating attached | 40px slide + fade | x/y position, opacity |
| Detached | Scale 0.9→1.0 + fade | scale, opacity |

Other components have their own hardcoded animations:
- **Notifications**: Slide + fade
- **OSD**: Scale + fade
- **Toast**: Slide from edge
- **Tray menu**: Fade

### Proposed Animation Types

```
slide       - Slide in from edge (current default for panels)
scale       - Scale up from center (0.9 → 1.0)
fade        - Opacity only (0 → 1)
popin       - Scale from small (0.5 → 1.0) + fade
slideScale  - Slide + subtle scale
slideFade   - Slide + fade (current floating behavior)
none        - Instant, no animation
```

### Implementation

#### 1a. Add to `Commons/Style.qml`

```qml
// Animation types enum-like constants
readonly property string animTypeSlide: "slide"
readonly property string animTypeScale: "scale"
readonly property string animTypeFade: "fade"
readonly property string animTypePopin: "popin"
readonly property string animTypeSlideScale: "slideScale"
readonly property string animTypeSlideFade: "slideFade"
readonly property string animTypeNone: "none"

// User-configurable animation types
readonly property string panelAnimationType: PowerProfileService.noctaliaPerformanceMode 
    ? "none" 
    : (Settings.data.general.panelAnimationType ?? "slideFade")

readonly property string notificationAnimationType: PowerProfileService.noctaliaPerformanceMode 
    ? "none" 
    : (Settings.data.general.notificationAnimationType ?? "slideFade")

readonly property string osdAnimationType: PowerProfileService.noctaliaPerformanceMode 
    ? "none" 
    : (Settings.data.general.osdAnimationType ?? "scale")

readonly property string toastAnimationType: PowerProfileService.noctaliaPerformanceMode 
    ? "none" 
    : (Settings.data.general.toastAnimationType ?? "slide")

readonly property string menuAnimationType: PowerProfileService.noctaliaPerformanceMode 
    ? "none" 
    : (Settings.data.general.menuAnimationType ?? "fade")
```

#### 1b. Add to `Assets/settings-default.json`

```json
"general": {
  "panelAnimationType": "slideFade",
  "notificationAnimationType": "slideFade",
  "osdAnimationType": "scale",
  "toastAnimationType": "slide",
  "menuAnimationType": "fade"
}
```

#### 1c. Modify `Modules/MainScreen/SmartPanel.qml`

This is the main change. Replace the hardcoded animation logic with a switch based on `Style.panelAnimationType`:

```qml
// Computed animation properties based on type
readonly property real targetOpacity: {
    switch (Style.panelAnimationType) {
        case "fade":
        case "popin":
        case "slideFade":
        case "slideScale":
            return isPanelVisible ? 1.0 : 0.0
        case "slide":
        case "scale":
            return 1.0  // No opacity animation
        case "none":
        default:
            return isPanelVisible ? 1.0 : 0.0
    }
}

readonly property real targetScale: {
    switch (Style.panelAnimationType) {
        case "scale":
            return isPanelVisible ? 1.0 : 0.9
        case "popin":
            return isPanelVisible ? 1.0 : 0.5
        case "slideScale":
            return isPanelVisible ? 1.0 : 0.95
        case "slide":
        case "fade":
        case "slideFade":
        case "none":
        default:
            return 1.0  // No scale animation
    }
}

readonly property real targetSlideOffset: {
    switch (Style.panelAnimationType) {
        case "slide":
            return isPanelVisible ? 0 : fullSlideDistance  // Full panel dimension
        case "slideFade":
        case "slideScale":
            return isPanelVisible ? 0 : 40  // Subtle slide
        case "scale":
        case "fade":
        case "popin":
        case "none":
        default:
            return 0  // No slide
    }
}
```

#### 1d. Modify other animated components

Apply similar pattern to:

| File | Animation Setting |
|------|-------------------|
| `Modules/Notification/Notification.qml` | `Style.notificationAnimationType` |
| `Modules/OSD/OSD.qml` | `Style.osdAnimationType` |
| `Modules/Toast/Toast.qml` | `Style.toastAnimationType` |
| `Modules/Bar/Extras/TrayMenu.qml` | `Style.menuAnimationType` |
| `Widgets/NPopupContextMenu.qml` | `Style.menuAnimationType` |
| `Modules/Panels/Launcher/Launcher.qml` | `Style.panelAnimationType` |

---

## Part 2: Easing Curves

### Current State

Easing types are hardcoded inline in each component file (~100+ instances):

| Easing Type | Used In |
|-------------|---------|
| `Easing.InOutQuad` | OSD, grid/list views, bar pills, lock screen header |
| `Easing.OutCubic` | Lock screen, notifications, bar pills |
| `Easing.OutQuad` | Tray menu |
| `Easing.Linear` | Notification progress bars |

### Implementation

#### 2a. Add to `Commons/Style.qml`

```qml
// Animation easing curves
readonly property int easingTypeDefault: PowerProfileService.noctaliaPerformanceMode 
    ? Easing.Linear 
    : (Settings.data.general.easingType ?? Easing.OutCubic)

readonly property int easingTypeFast: PowerProfileService.noctaliaPerformanceMode 
    ? Easing.Linear 
    : (Settings.data.general.easingTypeFast ?? Easing.OutQuad)

readonly property int easingTypeSlow: PowerProfileService.noctaliaPerformanceMode 
    ? Easing.Linear 
    : (Settings.data.general.easingTypeSlow ?? Easing.InOutQuad)
```

#### 2b. Add to `Assets/settings-default.json`

```json
"general": {
  "easingType": "OutCubic",
  "easingTypeFast": "OutQuad",
  "easingTypeSlow": "InOutQuad"
}
```

#### 2c. Add easing string→enum mapping in `Commons/Settings.qml`

```qml
function easingFromString(name) {
    const map = {
        "Linear": Easing.Linear,
        "InQuad": Easing.InQuad,
        "OutQuad": Easing.OutQuad,
        "InOutQuad": Easing.InOutQuad,
        "InCubic": Easing.InCubic,
        "OutCubic": Easing.OutCubic,
        "InOutCubic": Easing.InOutCubic,
        "InQuart": Easing.InQuart,
        "OutQuart": Easing.OutQuart,
        "InOutQuart": Easing.InOutQuart,
        "InQuint": Easing.InQuint,
        "OutQuint": Easing.OutQuint,
        "InOutQuint": Easing.InOutQuint,
        "InExpo": Easing.InExpo,
        "OutExpo": Easing.OutExpo,
        "InOutExpo": Easing.InOutExpo,
        "InBack": Easing.InBack,
        "OutBack": Easing.OutBack,
        "InOutBack": Easing.InOutBack,
        "InElastic": Easing.InElastic,
        "OutElastic": Easing.OutElastic,
        "InOutElastic": Easing.InOutElastic,
        "InBounce": Easing.InBounce,
        "OutBounce": Easing.OutBounce,
        "InOutBounce": Easing.InOutBounce
    }
    return map[name] ?? Easing.OutCubic
}
```

#### 2d. Bulk replace hardcoded easing

Find all instances:

```bash
grep -rn "easing.type:" /path/to/noctalia-shell/ --include="*.qml"
```

**Replacement pattern:**

```qml
// Before
easing.type: Easing.InOutQuad

// After
easing.type: Style.easingTypeDefault
```

**Which Style property to use:**

| Property | Use Case |
|----------|----------|
| `Style.easingTypeFast` | Quick micro-interactions (hover states, small UI feedback) |
| `Style.easingTypeDefault` | Most panel/popup animations |
| `Style.easingTypeSlow` | Larger, more dramatic transitions |

**Files to modify (run grep to find all):**

```
Modules/DesktopWidgets/Widgets/DesktopMediaPlayer.qml
Modules/Notification/Notification.qml
Modules/LockScreen/LockScreenPanel.qml
Modules/LockScreen/LockScreen.qml
Modules/LockScreen/LockScreenHeader.qml
Modules/OSD/OSD.qml
Modules/Bar/Extras/TrayMenu.qml
Modules/Bar/Extras/BarPillVertical.qml
Modules/Bar/Extras/BarPillHorizontal.qml
Modules/Bar/Extras/WorkspacePill.qml
Modules/MainScreen/SmartPanel.qml
Modules/Toast/Toast.qml
Widgets/NGridView.qml
Widgets/NListView.qml
Widgets/NCollapsible.qml
Widgets/NPopupContextMenu.qml
Widgets/NBattery.qml
Widgets/NCircleStat.qml
Widgets/NDateTimeTokens.qml
```

---

## Part 3: Settings UI

### Add to `Modules/Panels/Settings/Tabs/GeneralTab.qml`

Create a new "Animations" section with:

**Animation Type dropdowns:**
- Panel Animation: slide, scale, fade, popin, slideFade, slideScale, none
- Notification Animation: (same options)
- OSD Animation: (same options)
- Toast Animation: (same options)
- Menu Animation: (same options)

**Easing dropdowns:**
- Default Easing: Linear, OutQuad, OutCubic, OutQuint, OutBack, OutElastic, OutBounce, etc.
- Fast Easing: (same options)
- Slow Easing: (same options)

**Existing controls to keep:**
- Animation Speed (already exists)
- Disable Animations toggle (already exists)

### UI Mockup

```
┌─ Animations ─────────────────────────────────────┐
│                                                  │
│  Animation Speed        [━━━━━━━●━━━] 1.0x       │
│  Disable Animations     [ ]                      │
│                                                  │
│  ── Animation Types ──                           │
│  Panels                 [▼ Slide + Fade    ]     │
│  Notifications          [▼ Slide + Fade    ]     │
│  OSD                    [▼ Scale           ]     │
│  Toasts                 [▼ Slide           ]     │
│  Menus                  [▼ Fade            ]     │
│                                                  │
│  ── Easing Curves ──                             │
│  Default                [▼ OutCubic        ]     │
│  Fast (micro-interactions) [▼ OutQuad      ]     │
│  Slow (large transitions)  [▼ InOutQuad    ]     │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## Part 4: Additional Files to Update

### Translations

In `Assets/Translations/en.json`:

```json
{
  "settings.general.animations": "Animations",
  "settings.general.animationTypes": "Animation Types",
  "settings.general.easingCurves": "Easing Curves",
  "settings.general.panelAnimationType": "Panels",
  "settings.general.notificationAnimationType": "Notifications",
  "settings.general.osdAnimationType": "OSD",
  "settings.general.toastAnimationType": "Toasts",
  "settings.general.menuAnimationType": "Menus",
  "settings.general.easingType": "Default",
  "settings.general.easingTypeFast": "Fast (micro-interactions)",
  "settings.general.easingTypeSlow": "Slow (large transitions)",
  "settings.general.animType.slide": "Slide",
  "settings.general.animType.scale": "Scale",
  "settings.general.animType.fade": "Fade",
  "settings.general.animType.popin": "Pop-in",
  "settings.general.animType.slideFade": "Slide + Fade",
  "settings.general.animType.slideScale": "Slide + Scale",
  "settings.general.animType.none": "None (instant)"
}
```

### Search Index

In `Assets/settings-search-index.json`, add entries for all new settings.

### Settings Migration

In `Commons/Migrations/`, add a new migration file (e.g., `Migration49.qml`) following the existing pattern. With proper defaults this may be optional.

---

## Testing Checklist

After implementation, verify:

### Animation Types
- [ ] Panels open/close with each type (slide, scale, fade, popin, slideFade, slideScale, none)
- [ ] Notifications appear/dismiss with each type
- [ ] OSD shows/hides with each type
- [ ] Toasts animate with each type
- [ ] Menus (tray, context) animate with each type
- [ ] "none" type gives instant transitions
- [ ] Performance mode forces "none" / Linear

### Easing Curves
- [ ] Changing default easing affects panel animations
- [ ] Fast easing affects hover states and micro-interactions
- [ ] Slow easing affects large transitions
- [ ] OutBack gives subtle overshoot
- [ ] OutElastic gives springy bounce
- [ ] OutBounce gives bounce effect

### Edge Cases
- [ ] Settings persist after restart
- [ ] Settings UI updates live (or on panel reopen)
- [ ] Rapid open/close doesn't break animations
- [ ] Works with different bar positions (top, bottom, left, right)
- [ ] Works with floating vs attached panels

---

## Summary

This feature adds two levels of animation customization:

1. **Animation Types** (higher impact)
   - 5 new settings for different UI elements
   - Main work in SmartPanel.qml + individual component files
   - ~6 files need significant logic changes

2. **Easing Curves** (refinement)
   - 3 new settings (default, fast, slow)
   - Bulk find-replace across ~100+ easing.type instances
   - Straightforward but tedious

The end result gives users full control over how Noctalia animates — from snappy instant transitions to bouncy elastic effects.

---

## References

- QML Easing types: https://doc.qt.io/qt-6/qml-qtquick-propertyanimation.html#easing-prop
- QML Animations: https://doc.qt.io/qt-6/qtquick-statesanimations-animations.html
- Noctalia Style.qml: `Commons/Style.qml`
- Noctalia SmartPanel: `Modules/MainScreen/SmartPanel.qml`