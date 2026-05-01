---
source: Context7 API + official Flutter docs
library: Flutter
package: flutter
topic: app localizations usage patterns
fetched: 2026-05-01T00:00:00Z
official_docs: https://docs.flutter.dev/ui/internationalization
---

# Flutter `AppLocalizations` usage patterns for replacing hardcoded strings

## gen_l10n setup and generated access

Flutter's `gen_l10n` flow uses ARB files and generates an `AppLocalizations` class.

Required setup from the official docs:

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

return const MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);
```

Docs note: `AppLocalizations.of(context)!` is only available after the app has started and localization delegates are initialized.

## Getter vs method convention

- Simple ARB strings generate **getters**.
- ARB strings with placeholders generate **methods** with positional parameters.

Examples from Flutter docs:

```json
{
  "helloWorld": "Hello World!",
  "hello": "Hello {userName}"
}
```

Usage:

```dart
Text(AppLocalizations.of(context)!.helloWorld);
Text(AppLocalizations.of(context)!.hello('John'));
```

## Preferred widget-file replacement pattern

Inside `build`, capture localizations once and replace literals with generated getters/methods:

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l10n.profileTitle),
      TextButton(
        onPressed: onSave,
        child: Text(l10n.save),
      ),
    ],
  );
}
```

This preserves behavior while only changing the string source.

## Dialog pattern

Flutter's `showDialog` docs state the dialog `builder` does **not share a context** with the place where `showDialog` is called. Use the builder context for localization lookup.

```dart
showDialog<void>(
  context: context,
  builder: (dialogContext) {
    final l10n = AppLocalizations.of(dialogContext)!;

    return AlertDialog(
      title: Text(l10n.deleteTitle),
      content: Text(l10n.deleteMessage(fileName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: onConfirm,
          child: Text(l10n.delete),
        ),
      ],
    );
  },
);
```

Preservation guidance:

- Keep the same callbacks, route behavior, and navigator usage.
- Replace only displayed text.
- If interpolating values, move them into ARB placeholders rather than string concatenation.

## SnackBar pattern

`ScaffoldMessengerState.showSnackBar` should be called from callbacks, not during build. Localize the content and action labels before creating the `SnackBar`.

```dart
onPressed: () {
  final l10n = AppLocalizations.of(context)!;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.itemSaved),
      action: SnackBarAction(
        label: l10n.undo,
        onPressed: undoSave,
      ),
    ),
  );
}
```

## Modal bottom sheet pattern

Flutter's `showModalBottomSheet` uses a builder callback; localize inside that builder or pass already-localized strings in.

```dart
showModalBottomSheet<void>(
  context: context,
  builder: (sheetContext) {
    final l10n = AppLocalizations.of(sheetContext)!;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(l10n.rename),
            onTap: onRename,
          ),
          ListTile(
            title: Text(l10n.delete),
            onTap: onDelete,
          ),
        ],
      ),
    );
  },
);
```

Preservation guidance:

- Keep `isScrollControlled`, `useSafeArea`, drag, dismissal, and return-value behavior unchanged.
- Only swap visible labels.

## Interpolated text: use placeholders, not concatenation

Instead of:

```dart
Text('Delete $fileName?');
SnackBar(content: Text('Saved $count items'));
```

Use ARB placeholders and generated methods:

```json
{
  "deleteFilePrompt": "Delete {fileName}?",
  "@deleteFilePrompt": {
    "description": "Delete confirmation prompt",
    "placeholders": {
      "fileName": {
        "type": "String",
        "example": "report.pdf"
      }
    }
  },
  "savedItemCount": "Saved {count} items",
  "@savedItemCount": {
    "description": "Shown after saving items",
    "placeholders": {
      "count": {
        "type": "int",
        "example": "3"
      }
    }
  }
}
```

```dart
Text(l10n.deleteFilePrompt(fileName));
SnackBar(content: Text(l10n.savedItemCount(count)));
```

## Title generation pattern

Flutter docs recommend localizing app titles with `onGenerateTitle`:

```dart
MaterialApp(
  onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
)
```

## Safe migration checklist for hardcoded widget strings

1. Add ARB keys for every user-facing literal.
2. Use a getter for static text.
3. Use a method with placeholders for dynamic text.
4. Read `AppLocalizations.of(context)!` from the correct context.
5. Do not change callbacks, control flow, route pops, or visual structure.
6. For dialogs/bottom sheets, keep builder-specific context behavior intact.

## Sources used

- Flutter internationalization guide: `AppLocalizations`, `gen_l10n`, placeholders, plurals, selects.
- Flutter Material API docs: `showDialog`, `ScaffoldMessengerState.showSnackBar`, `showModalBottomSheet`.
