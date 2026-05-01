---
source: Context7 API + Flutter docs
library: Flutter
package: flutter
topic: AppLocalizations in widgets and settings-screen string localization
fetched: 2026-05-01T00:00:00Z
official_docs: https://docs.flutter.dev/ui/internationalization
---

## AppLocalizations.of(context)! in widgets

- Flutter docs use the generated localization class directly in widget build methods, for example:

```dart
appBar: AppBar(
  title: Text(AppLocalizations.of(context)!.helloWorld),
);
```

- Practical patch pattern for a widget file:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return ListTile(
    title: Text(l10n.settingsTitle),
    subtitle: Text(l10n.settingsSubtitle),
  );
}
```

- Keep lookups inside `build()` or helper methods that receive `BuildContext`.
- Reuse a local `final l10n = AppLocalizations.of(context)!;` when replacing multiple strings in one widget.

## Required app setup noted by Flutter docs

- Add localization support and generate localizations:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

- `MaterialApp` should include localization delegates and supported locales.

## Best practices for replacing hardcoded settings-screen strings

1. Replace text values only; do not change callbacks, layout, conditions, icons, routing, or state logic.
2. Create stable ARB keys based on UI meaning, not current English text. Example: `settingsTitle`, `privacyPolicy`, `clearCacheDescription`.
3. Hoist `l10n` once per `build()` for concise patches.
4. Preserve existing punctuation, capitalization, and spacing to avoid behavior or snapshot changes.
5. Localize visible user-facing strings only; leave analytics keys, IDs, enum names, and storage keys untouched.
6. For repeated labels across the same screen, use the same localization getter to keep wording consistent.
7. If a helper method builds UI, pass `BuildContext` or `AppLocalizations` into it instead of hardcoding strings there.

## Practical patch checklist for a settings Dart file

- Add `AppLocalizations` import.
- In `build()`, define `final l10n = AppLocalizations.of(context)!;`.
- Replace hardcoded widget strings such as:
  - `Text('Settings')` -> `Text(l10n.settingsTitle)`
  - `Text('About')` -> `Text(l10n.about)`
  - `Text('Clear cache')` -> `Text(l10n.clearCache)`
- Add matching entries to `app_en.arb` before patching other locales.
- Keep widget structure identical so behavior remains unchanged.

## Notes from current Flutter docs

- Flutter docs show localized values accessed from the generated class via `AppLocalizations.of(context)!`.
- Flutter docs also note app-level setup with `flutter_localizations`, `supportedLocales`, and delegates.
- The generated-localizations workflow is the recommended path for app strings.
