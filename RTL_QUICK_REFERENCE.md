# RTL Support - Quick Reference Guide

## Overview
Fadocx has RTL infrastructure (Urdu locale) but lacks directional-aware implementations. **30% production-ready**. Most issues are in sidebar/drawer logic and navigation controls.

## File Locations with Issues

### 🔴 Critical Issues (Block RTL Production)
- **lib/features/home/presentation/screens/home_screen.dart**
  - Lines 452-469: Sidebar hardcoded `left: 0`
  - Lines 109-115: Drag clamping not RTL-aware
  
- **lib/features/viewer/presentation/screens/viewer_screen.dart**
  - Lines 667-688: Sidebar hardcoded `left: 0`
  - Lines 1154-1167: Back button wrong icon/position

### 🟠 High Priority (Navigation UX)
- **lib/features/home/presentation/widgets/home_drawer.dart**
  - Line 319: Menu chevrons always right
  - Lines 100-138: Hamburger icon not directional

- **lib/core/presentation/widgets/floating_dock_scaffold.dart**
  - Line 121-125: FAB always positioned right

### 🟡 Medium Priority (Polish)
- **lib/features/home/presentation/screens/home_screen.dart**
  - Lines 2525, 2658: TextPainter forced LTR
  - Lines 2700-2776: Sidebar painter path not mirrored

## Fix Pattern

### Detect RTL
```dart
final isRTL = Directionality.of(context) == TextDirection.rtl;
```

### Swap Left/Right Position
```dart
Positioned(
  left: isRTL ? null : 0,
  right: isRTL ? 0 : null,
  child: /* ... */,
)
```

### Swap Slide Animation Direction
```dart
SlideTransition(
  position: Tween<Offset>(
    begin: isRTL ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
    end: Offset.zero,
  ).animate(/* ... */),
)
```

### Swap Icon Direction
```dart
Icon(
  isRTL ? Icons.chevron_left : Icons.chevron_right,
  /* ... */
)
```

### Use Directionality in TextPainter
```dart
TextPainter(
  textDirection: Directionality.of(context),
)
```

## Testing Urdu Locale
1. Settings → Language → اردو (Urdu)
2. Verify drawer slides from right
3. Verify back button on right with chevron_right
4. Verify FAB on left side
5. Verify text renders right-to-left

## Priority Fixes
1. **MUST**: Sidebar positioning (Issues #1, #4)
2. **SHOULD**: Navigation controls (Issues #2, #5)
3. **NICE**: Polish widgets (Issues #6-11)

## Documentation
Full analysis: `RTL_SUPPORT_ANALYSIS.md`
