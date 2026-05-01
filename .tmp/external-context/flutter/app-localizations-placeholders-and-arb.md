---
source: Context7 API + official Flutter docs
library: Flutter
package: flutter
topic: app localizations placeholders and arb
fetched: 2026-05-01T00:00:00Z
official_docs: https://docs.flutter.dev/ui/internationalization
---

# Flutter ARB conventions relevant to replacing string literals

## Basic string -> getter

```json
{
  "save": "Save",
  "cancel": "Cancel"
}
```

Generated usage:

```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.save);
Text(l10n.cancel);
```

## Placeholder string -> method

```json
{
  "welcomeUser": "Welcome, {userName}",
  "@welcomeUser": {
    "description": "Greets the signed-in user",
    "placeholders": {
      "userName": {
        "type": "String",
        "example": "Bob"
      }
    }
  }
}
```

Generated usage:

```dart
Text(AppLocalizations.of(context)!.welcomeUser(userName));
```

## Plurals for count-sensitive UI

```json
{
  "selectedCount": "{count, plural, =0{No items selected} =1{1 item selected} other{{count} items selected}}",
  "@selectedCount": {
    "description": "Selection count label",
    "placeholders": {
      "count": {
        "type": "num"
      }
    }
  }
}
```

```dart
Text(AppLocalizations.of(context)!.selectedCount(count));
```

## Selects for state-specific wording

```json
{
  "connectionStateLabel": "{state, select, online{Online} offline{Offline} syncing{Syncing} other{Unknown}}",
  "@connectionStateLabel": {
    "description": "Connectivity state label",
    "placeholders": {
      "state": {
        "type": "String"
      }
    }
  }
}
```

```dart
Text(AppLocalizations.of(context)!.connectionStateLabel(state));
```

## Migration guidance

- Replace string concatenation/interpolation with ARB placeholders.
- Replace count-specific `if`/ternary text with plural messages when the text itself changes.
- Keep non-user-facing identifiers, route names, analytics event names, and debug logs out of ARB unless actually displayed.
