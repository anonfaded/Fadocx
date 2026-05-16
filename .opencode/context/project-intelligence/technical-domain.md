<!-- Context: project-intelligence/technical | Priority: critical | Version: 2.0 | Updated: 2026-05-16 -->

# Technical Domain — Fadocx

**Purpose**: Tech stack, architecture, and coding patterns for Fadocx — an offline-first document viewer for Android.
**Last Updated**: 2026-05-16

## Primary Stack

| Layer | Technology | Version | Rationale |
|-------|-----------|---------|-----------|
| Framework | Flutter | 3.x | Cross-platform, native performance |
| Language | Dart | ≥3.0 | Type-safe, compiled, async-first |
| State Mgmt | Riverpod | ^3.3 | Notifier/AsyncNotifier pattern |
| Routing | go_router | ^17.2 | Declarative, deep-link support |
| Storage | Hive | ^2.2 | Fast, NoSQL, codegen models |
| PDF Engine | pdfrx | ^2.2 | Native PDF rendering |
| Office Rendering | LibreOfficeKit | embedded | Desktop-class DOCX/PPT/ODF |
| Spreadsheet | Apache POI (native) | via platform channel | XLSX/XLS parsing |
| OCR | Tesseract + OpenCV | on-device | English text extraction |
| i18n | flutter_localizations | 11 langs | AR, DE, EN, ES, FR, HI, JA, PT, RU, UR, ZH |

## Architecture

**Pattern**: Clean Architecture + Feature-First + MVI
```
lib/
├── main.dart                    # App entry, Hive init, router
├── config/                      # Cross-cutting config
│   ├── routing/app_router.dart  # go_router with fade transitions
│   └── theme/app_theme.dart     # Material 3, forest green seed
├── core/                        # Shared layer
│   ├── errors/failures.dart     # Result<T> pattern (Success/Failure)
│   ├── presentation/            # Shared widgets, constants
│   ├── providers/               # Cross-feature providers
│   └── services/                # Shared services (storage, OCR, camera)
├── features/                    # Feature modules
│   ├── home/                    # Dashboard, library, trash
│   ├── viewer/                  # Document viewer (all formats)
│   ├── settings/                # App settings, locale
│   ├── scanner/                 # OCR camera capture
│   └── onboarding/              # First-launch flow
├── l10n/                        # Generated localization
└── services/                    # Platform services (file intents)
```

## Code Patterns

### State Management (Riverpod Notifier)
```dart
final documentViewerProvider =
    NotifierProvider.autoDispose<DocumentViewerNotifier, ParsedDocumentState>(
        DocumentViewerNotifier.new);

class DocumentViewerNotifier extends Notifier<ParsedDocumentState> {
  @override ParsedDocumentState build() => const ParsedDocumentState();
  Future<void> loadDocument() async {
    state = state.copyWith(isLoading: true);
    // ... parse, then state = ParsedDocumentState(document: doc);
  }
}
```

### Error Handling (Result Pattern)
```dart
abstract class Result<T> {
  R fold<R>(R Function(Failure) onFailure, R Function(T) onSuccess);
}
// Usage: result.fold((f) => showError(f.message), (data) => use(data))
```

### Repository Pattern
```dart
// Domain interface → Data implementation → Provider wiring
final documentParsingRepositoryProvider = Provider((ref) {
  return DocumentParsingRepositoryImpl(
    platformChannel: ref.watch(platformChannelServiceProvider),
    cache: ref.watch(cacheServiceProvider),
  );
});
```

### Format Routing (switch on extension)
Large switch statement routes 30+ file extensions to appropriate parsers.
See `lib/features/viewer/data/repositories/document_parsing_repository_impl.dart`.

### Caching Strategy
Cache-first with file modification validation. All parsers check cache before parsing.
See `lib/features/viewer/data/services/cache_service.dart`.

## Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Files | snake_case | `document_parsing_repository_impl.dart` |
| Classes | PascalCase | `DocumentViewerNotifier`, `ParsedDocumentEntity` |
| Providers | camelCase + `Provider` suffix | `documentViewerProvider` |
| Functions | camelCase (verb-first) | `parseXLSX`, `loadDocument` |
| Widgets | PascalCase | `ModernPdfViewer`, `HomeDrawer` |
| Hive boxes | snake_case + prefix | `fadocx_settings`, `fadocx_recent_files` |
| Routes | kebab-case paths | `/documents`, `/whats-new` |

## Code Standards

- **State Mgmt**: Riverpod `Notifier`/`AsyncNotifier` — no legacy `StateNotifier`
- **UI**: `const` constructors everywhere, avoid heavy logic in `build()`
- **Architecture**: Strict layer separation — Presentation → Domain → Data
- **Localization**: Never hardcode strings — use `AppLocalizations.of(context)!`
- **Logging**: `import 'package:logger/logger.dart'` — `final log = Logger()`
- **Hive Models**: Run `dart run build_runner build --delete-conflicting-outputs` after adding `@HiveField`
- **Startup**: Zero-dependency MainActivity, lazy-load heavy libs via reflection
- **Build**: arm64-v8a only (LibreOffice native code), use `./build.sh`

## Security Requirements

- 100% offline — no internet permission for document viewing
- No tracking, analytics, crash logs, or telemetry
- All AI/OCR runs on-device — no cloud, no uploads
- Files stored in private app storage — isolated from other apps
- Open source — fully auditable codebase

## 📂 Codebase References

**Entry**: `lib/main.dart` — Hive init, theme loading, router creation
**Router**: `lib/config/routing/app_router.dart` — go_router with fade transitions, singleton pattern
**Theme**: `lib/config/theme/app_theme.dart` — Material 3, forest green (#2D6A4F), light/dark
**Errors**: `lib/core/errors/failures.dart` — Result<T>, 7 failure types
**Viewer**: `lib/features/viewer/presentation/screens/viewer_screen.dart` — multi-format viewer (2000+ lines)
**Parsing**: `lib/features/viewer/data/repositories/document_parsing_repository_impl.dart` — format routing, caching
**Storage**: `lib/features/settings/data/datasources/hive_datasource.dart` — 4 Hive boxes
**Settings**: `lib/features/settings/presentation/providers/settings_providers.dart` — Riverpod providers
**Build**: `build.sh` — interactive menu, prod/beta flavors, arm64 only

## Related Files

- `business-domain.md` — Privacy-first document viewer mission
- `business-tech-bridge.md` — How offline requirement drives architecture
- `decisions-log.md` — Technical decisions (pdfrx, LibreOfficeKit, Hive)
- `living-notes.md` — Active issues, TODOs, upcoming features
