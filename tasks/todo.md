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
- Mirrored the document thumbnail tilt in both Home recent files and Library list items by flipping the rotation sign from `Directionality`; loading skeleton now matches the final RTL/LTR tilt too.
- Analyzer verification after the tilt change: `flutter analyze` reports `No issues found!`.
- Library selection mode now exposes an explicit batch delete action next to select-all, single-file delete now confirms before trashing, and the shared file-action sheet is dismissible by outside tap again.
- Settings updates section now uses descriptive subtitles, and the replay onboarding toggle moved into About with consistent icon/background styling.
- Added `settingsAutoUpdateCheckDesc` across all supported locales and regenerated Flutter localizations successfully.
- Settings screen now uses distinct gray layers for section groups and row cards so the hierarchy reads better against the page background.
- Drawer update cards and drawer action cards now share the same neutral gray card language as Settings.
- Scan action card now animates individual binary digits instead of whole synchronized columns, and drawer main actions now share one connected container shell.
- Drawer rows now use clipped Material cards for rounded ripples, and the Patreon card is back on the gold treatment with wrapped title/subtitle text.
- Drawer Whats New stays in the connected group; Patreon keeps the same row format with gold styling and `drawerUnlockBenefits` subtitle.
- Restored the connected drawer grouping; only row styling changed, not the layout structure.
- Patreon now uses the same card shell color as Settings; only the accent colors remain gold.
- Drawer row surfaces now match the Settings card palette: one outer group shell, flat rows inside, and gold Patreon shimmer kept separate.
- Home tab now expands to full screen in tab mode even when recent files are hidden, so the swipe-to-open drawer still hits the full gesture area.
- Patreon drawer card now uses the larger title style again and its trailing chevron matches the drawer row arrow treatment more closely.
- Main shell tab swipe detector is now opaque and wrapped in a full-size box so Home tab swipes still work when the recent-files section is hidden.
- Patreon drawer card spacing now matches the other drawer rows by removing the extra outer wrapper padding and normalizing its internal padding.
- Update available banner now has a localized "Updates Available" section title and uses the same grouped card language as the rest of the drawer.
- Light-mode contrast for update cards is lowered so the banner reads clearly without washing out the drawer surface.
- Update banner subtitle now shows current version in red, separator in neutral gray, and latest version in green.
- Update banner title is plural-aware so it switches to singular when only one update card is present.
- Update banner rows were flattened so the section uses one outer shell and plain rows inside instead of nested cards.
- Whats New release date now uses 15 May 2026, and the page includes a localized supported-languages block with chips for all 11 UI locales.
- README now includes a dedicated localization section listing the supported UI languages.
- Settings theme/language bottom sheets need to move from `ListTile` layout to the same card rows used in Settings, including an AMOLED coming-soon row.
- Shared file/info/action bottom sheets need the same card palette and flatter row structure as Settings to avoid mismatched nested surfaces.
- Whats New language chips should show flags alongside the language names.
- RELEASE.md needs the localization/support-languages note and the release date should match the May 15 release target.
- Settings theme and language sheets now use the same flat card rows as the rest of Settings, and AMOLED is visible as coming soon.
- Home/Documents file info dialogs now use a card-based bottom sheet instead of AlertDialog.
- File action and link bottom sheets were moved closer to the Settings card palette.
- Shared bottom sheets now use one connected shell with dividers and row padding, matching the Settings group layout instead of spaced mini-cards.
- The settings picker helpers that were left behind after the refactor were removed once the shared shell widget landed.
- Export choosers in Home and Library now use the same connected shell pattern as Settings instead of a separate card stack.
- File-info sheets now sit on a lighter sheet surface than the inner rows, and the copy row uses action copy instead of a success-state subtitle.
- Whats New now uses a Highlights heading, with the supported-languages card moved under that section.
- File action and export sheets now use the same outer sheet contrast as the Settings bottom sheets, so the sheet shell reads separately from the row group.
- Settings link rows now use the same lighter neutral chip surface as the rest of the Settings cards instead of a darker tinted container.
- README.md and RELEASE.md now describe localization in user-facing language with flags only, without the extra RTL/scan notes in that section.
- Home drawer main group and row chips now use lower light-mode alpha so the drawer cards do not wash out on bright themes.
- Home drawer needed a lower base surface tier, not just lower alpha, to stay distinct in light mode.
- Home drawer and update banner now use the same neutral gray shell family as Settings instead of a white/light base layer.
- Scan action card binary strip was anchored too far left inside the black wedge and its motion was too subtle to read as active animation.
- Recentered the binary strip in the wedge and increased the per-cell motion/swap cadence so the scan card reads as alive again.
- Scan card binary animation now uses 2 columns again and follows the same scrolling motion model as the import card instead of a static-looking three-column layout.
- Scan card binary rain now uses discrete 0/1 toggles per cell instead of a crossfade, so the digits read as a proper rain effect.
- Scan card rain still looked synchronized because every cell shared the same global toggle step; each cell now has its own phase offset.
- Scan card flip cadence was still a bit too quick, so the binary swap speed has been reduced while keeping the downward rain motion.
- Library category root cause: scan files were bucketed by extension only, so scanned PNGs in the `Scans` folder were counted and filtered as `images`.
- Library category filter now uses the same path-aware scan detection as the counts, so scanned files land under `Scans` instead of `Images`.
- Library category classifier now keys off the managed storage folder first (`PDFs`, `Documents`, `Spreadsheets`, `Presentations`, `Images`, `Audio`, `Video`, `Code`, `Scans`) and only falls back to extension for legacy paths.
- First-release cleanup: removed the extension fallback entirely so Library categories now resolve only from the managed folder path; unknown paths fall into `other`.
- Scan category rule tightened: scans are classified strictly from the `Scans` folder path, not from the `Fadocx_scanned_` filename prefix.
- Import/browse screen now exposes the full category set again (`Images`, `Audio`, `Video`, `Code`, `Scans`) instead of only the older document chips.
- Browse screen scanning now classifies files by managed folder path first and then falls back to extension-based grouping for loose device files, so the chip counts and filters stay aligned.
- Added localized ARB labels and regenerated the localization layer so the new import chips compile in every supported language.
- Import browser should stay scoped to device document categories; `Scans` was removed because that bucket belongs to Library, not the import screen.
- Home recent-files thumbnails now render actual presentation previews for `ppt`, `pptx`, and `odp` when thumbnail bytes exist instead of forcing the placeholder card.
- Code-like extensions were still being routed into `Documents` at save time, so the Library code chip stayed undercounted until `StorageService` learned the full code extension set.
- Browse/import screen should stay extension-based; code-like extensions were landing in `Docs`, so the browse classifier now maps them to `Code` instead of following the Library folder contract.
- Browse chips are now count-sorted so the busiest categories float left instead of being locked to a fixed visual order.
- Library thumbnails now use top-anchored width-fit rendering so the preview image keeps its proportions instead of looking squeezed inside the card.
- Image thumbnails in the renderer now keep the image full-frame with the metadata dock layered on top instead of pushing the image below the banner.
- Video preview thumbnails now use the same docked header overlay treatment as image previews, instead of reserving a separate top band.
- Generic media placeholders and PDF previews now also use the docked header overlay; spreadsheet previews stay on their separate header band so the grid stays readable.

## Naming Convention for .arb keys
- Common/shared: camelCase (e.g., `cancel`, `delete`, `copy`)
- Screen-specific: screenPrefix + camelCase (e.g., `homeWelcomeTitle`, `settingsStorageTitle`)
- Plurals: ICU plural syntax (e.g., `{count, plural, =1{1 file} other{{count} files}}`)
