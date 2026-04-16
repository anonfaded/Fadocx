# AI Agent Guidelines for Fadocx

## Design System: Premium macOS/iOS + Material3

### Core Principles
- **Dock-style UI**: Floating, rounded containers with minimal bezels
- **Material3 Foundation**: Use Material3 color system and typography
- **Compact Spacing**: 8px, 12px, 16px, 24px grid (never large padding)
- **iOS Rows**: Settings-like list items with leading icon, title, subtitle, trailing chevron
- **Premium Aesthetics**: Generous use of dividers, subtle shadows, rounded corners (16px)
- **Dark Mode First**: Design for dark theme with proper contrast ratios

### Layout Rules
- **Top AppBar**: Compact dock (56dp) with title + 3 action buttons max
- **Bottom Navigation**: Floating dock with navigation controls (48dp height, 16px padding)
- **Sidebar/Drawer**: Modal overlay or slide-from-left, NOT replacing main content
- **Content Area**: Full-bleed to edges (respects SafeArea), centered when needed
- **Margins**: 16px horizontal, 12px vertical between sections

### Components

#### Dock Button
```dart
Container(
  decoration: BoxDecoration(
    color: Color.lerp(primary, surface, 0.2), // Semi-transparent primary
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: primary.withValues(alpha: 0.3), width: 1),
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Icon(icon),
      ),
    ),
  ),
)
```

#### iOS-Style Row (ListTile Alternative)
```dart
Container(
  decoration: BoxDecoration(
    color: surface.withValues(alpha: 0.5),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: outline.withValues(alpha: 0.1), width: 1),
  ),
  child: ListTile(
    leading: Icon(icon, color: primary),
    title: Text(title, style: titleMedium),
    subtitle: Text(subtitle, style: bodySmall),
    trailing: Icon(Icons.chevron_right, color: outline),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    onTap: onTap,
  ),
)
```

#### Floating Dock (Bottom Controls)
```dart
Container(
  decoration: BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)],
  ),
  child: Row(children: [...buttons...])
)
```

### Typography (Material3)
- Headlines: displayLarge, displayMedium, headlineSmall
- Body: bodyLarge, bodyMedium, bodySmall
- Labels: labelLarge, labelMedium, labelSmall
- Always use `Theme.of(context).textTheme.*`

### Colors (Material3 ColorScheme)
- Primary: Brand color (blue)
- Surface: Background containers
- Outline: Borders, dividers
- OnPrimary: Text on colored backgrounds
- Use `.withValues(alpha: 0.X)` for transparency (NOT deprecated `withOpacity`)

### Spacing Constants
```dart
const double kSmallPadding = 8;
const double kMediumPadding = 12;
const double kLargePadding = 16;
const double kXLargePadding = 24;
const double kBorderRadius = 12;
const double kLargeBorderRadius = 24;
```

### SafeArea Usage
- Always wrap top/bottom with SafeArea in docks
- Content area: minimal SafeArea (let it go edge-to-edge)
- Status bar area: keep 8px padding after SafeArea

### Animation & Transitions
- Duration: 200ms for UI toggles
- Curve: `Curves.easeInOutCubic`
- Never use Curves.linear for visual transitions

### Accessibility
- All interactive elements ≥48dp tap target
- Sufficient color contrast (≥7:1 for text)
- Semantic labels for screen readers

### What NOT to Do
- ❌ Large AppBars (>64dp)
- ❌ Excessive padding/margins
- ❌ More than 3-4 action buttons in header
- ❌ withOpacity() — use withValues(alpha: X)
- ❌ Hard-coded colors — use Theme.of(context).colorScheme
- ❌ Full-screen modals for simple dialogs
- ❌ Nested Scaffolds in modal overlays

### PDF Viewer Specifics
- Top dock: Back + Title + (Menu, Invert, TextMode) [compact, no page numbers]
- Bottom dock: Navigation controls + page indicator (floating)
- Sidebar: Modal overlay, tabbed (Pages/Search/TOC), iOS-style rows
- Search: Matches as iOS-style rows with page numbers
- Single tap on PDF: Toggle controls (not sidebar)
- Sidebar tap: Navigate + close sidebar automatically

