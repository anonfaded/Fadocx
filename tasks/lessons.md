# Lessons

- When migrating hardcoded UI strings to localization, preserve the exact original English copy first. Do not normalize, shorten, or rewrite phrasing unless the user explicitly asks for copy changes.
- Do not change existing UI behavior while localizing. Preserve the same options, sort modes, labels, and punctuation; only move strings into `AppLocalizations`.
- When adding Urdu translations for previously hardcoded English copy, translate the same meaning and structure directly. Do not shorten the message or replace it with new marketing wording.
- When a file already imports `dart:ui` as `ui`, use `ui.TextDirection` in RTL helpers. Do not assume the unprefixed enum is available or equivalent in every file.
- When rebuilding UI copy or subtitles, verify the localization key exists before wiring it in. Do not invent a new `AppLocalizations` key unless you also add it everywhere it is required.
- When a user asks to keep a connected card layout, preserve the grouping structure and only restyle the rows. Do not split one connected group into separate card systems unless the user explicitly asks for that.
- When a tab body conditionally hides its main list, make sure the root widget still expands to the full viewport. Otherwise swipe and edge gestures can disappear in the empty area even though the UI looks correct.
- For shell-level swipe navigation, set the detector to `HitTestBehavior.opaque` and make the child full-size. A visible page can still miss swipes if the gesture tree only covers painted content.
- When a special drawer card is meant to match adjacent rows, check both the outer wrapper and internal padding. Extra list padding plus card padding can make one item look visually detached even when the decoration matches.
- When promoting a banner into a section, give it a localized title and tune the light-mode alpha separately from dark mode. A card that looks fine in dark mode can be too bright once it sits near a light drawer surface.
- When showing version comparisons, do not flatten them into a single subtitle string. Use colored spans so the current value and target value stay visually distinct.
- When a section already has an outer shell, do not add another decorated container around each row. Keep the rows flat and use padding/dividers for separation.
