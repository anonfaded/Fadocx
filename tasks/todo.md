# i18n Internationalization: English & Urdu

## Goal
Replace ALL hardcoded English strings across the app with AppLocalizations keys, with complete Urdu translations.

## Current State
- 86 existing .arb keys (settings + error messages)
- ~300+ hardcoded strings across 12+ files
- i18n pipeline properly configured (flutter_localizations, intl, generate:true, localeProvider)

## Phase 1: Add all missing .arb keys
- [x] Audit all hardcoded strings across all .dart files
- [x] Add ~200+ new keys to app_en.arb
- [x] Add ~200+ new Urdu translations to app_ur.arb
- [x] Regenerate l10n (flutter gen-l10n)

## Phase 2: Replace hardcoded strings in .dart files
- [x] 2a: floating_dock_scaffold.dart, bottom_nav_dock.dart, link_tile.dart, drawer_update_banner.dart, constants.dart
- [x] 2b: update_available_sheet.dart, file_action_bottom_sheet.dart
- [x] 2c: home_drawer.dart, trash_screen.dart
- [x] 2d: browse_screen.dart, documents_screen.dart
- [x] 2e: home_screen.dart (largest - ~60 strings)
- [x] 2f: settings_screen.dart (~50 strings)
- [x] 2g: viewer_screen.dart (largest - ~60 strings)
- [x] 2h: scanner_screen.dart, whats_new_screen.dart

## Phase 3: Verify
- [x] Run flutter gen-l10n
- [x] Run flutter analyze
- [ ] Verify app runs in both English and Urdu

## Review
- Added missing placeholder metadata blocks to both `lib/l10n/app_en.arb` and `lib/l10n/app_ur.arb` for all localized messages using ICU placeholders/plurals.
- Regenerated Flutter localizations successfully with `flutter gen-l10n`.
- Fixed a surfaced analyzer type mismatch in `lib/features/settings/presentation/screens/settings_screen.dart` by converting the async error object to `String` before passing it to the localized error message.
- Verification result: `flutter analyze` reports `No issues found!`.

## Naming Convention for .arb keys
- Common/shared: camelCase (e.g., `cancel`, `delete`, `copy`)
- Screen-specific: screenPrefix + camelCase (e.g., `homeWelcomeTitle`, `settingsStorageTitle`)
- Plurals: ICU plural syntax (e.g., `{count, plural, =1{1 file} other{{count} files}}`)
