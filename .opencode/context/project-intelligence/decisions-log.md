<!-- Context: project-intelligence/decisions | Priority: critical | Version: 2.0 | Updated: 2026-05-16 -->

# Decisions Log — Fadocx

**Purpose**: Record major technical decisions with context so future contributors understand the "why."
**Last Updated**: 2026-05-16

---

## Decision: Flutter as Cross-Platform Framework

**Date**: 2024 | **Status**: Decided

**Context**: Need cross-platform viewer (Android first, iOS/Desktop planned).

**Decision**: Flutter + Dart.

**Rationale**: Single codebase, hot reload, strong CustomPaint for complex UI.

**Alternatives**: Native Android (Android-only), React Native (weak custom painting), Web PWA (no native file access).

**Impact**: ✅ Fast dev, cross-platform ready | ❌ Large APK | ⚠️ Flutter web/desktop maturity

---

## Decision: pdfrx for PDF Rendering

**Date**: 2024 | **Status**: Decided

**Context**: Need PDF rendering with text extraction, navigation, search.

**Decision**: `pdfrx` package.

**Rationale**: Mature, text extraction support (word count, reading time, spotlight search).

**Alternatives**: native_pdf_view (no text extraction), syncfusion (commercial license), custom (months of work).

**Impact**: ✅ Fast rendering, text extraction | ❌ LayoutBuilder null checks (worked around with GlobalKey) | ⚠️ WASM modules for web (removed)

---

## Decision: Embedded LibreOfficeKit for Office Documents

**Date**: 2024 | **Status**: Decided

**Context**: Need desktop-quality rendering for DOCX, PPTX, ODF.

**Decision**: Embed LibreOfficeKit via platform channels.

**Rationale**: Only open-source solution with full formatting fidelity.

**Alternatives**: Dart parser (loses formatting), cloud API (violates offline-first), text-only (poor UX).

**Impact**: ✅ Desktop-quality rendering | ❌ APK ~346MB, arm64-only | ⚠️ Complex native library maintenance

---

## Decision: Hive for Local Storage

**Date**: 2024 | **Status**: Decided

**Context**: Need fast local storage for settings, recent files, thumbnails.

**Decision**: Hive with code-generated adapters.

**Rationale**: NoSQL key-value, fast, zero native deps, type-safe codegen.

**Alternatives**: SQLite (overkill), SharedPreferences (primitives only), Isar (less mature).

**Impact**: ✅ Fast startup, type-safe | ❌ Must run `build_runner` after `@HiveField` changes | ⚠️ Silent data loss if adapter not regenerated

---

## Decision: Riverpod for State Management

**Date**: 2024 | **Status**: Decided

**Context**: Need reactive state management across features.

**Decision**: Riverpod `Notifier`/`AsyncNotifier` (not `StateNotifier`).

**Rationale**: Compile-time safety, no BuildContext, autoDispose, testable.

**Alternatives**: Provider (runtime errors), Bloc (boilerplate), GetX (anti-patterns).

**Impact**: ✅ Clean composition, autoDispose | ❌ Learning curve | ⚠️ Provider invalidation bugs

---

## Decision: arm64-v8a Architecture Only

**Date**: 2024 | **Status**: Decided

**Context**: LibreOffice native libs only compiled for arm64-v8a.

**Decision**: arm64-v8a only. Drop armeabi-v7a and x86_64.

**Rationale**: LibreOffice native code doesn't exist for other architectures.

**Alternatives**: Multi-arch (LOKit won't work), fallback parsers (poor UX).

**Impact**: ✅ Smaller APK, simpler build | ❌ Excludes 32-bit devices, Chromebooks | ⚠️ ~5% devices unsupported

---

## Decision: No Telemetry or Analytics

**Date**: 2024 | **Status**: Decided

**Context**: Need usage insights without compromising privacy.

**Decision**: Zero telemetry. No analytics, no crash reporting.

**Rationale**: Core brand promise is "zero tracking."

**Alternatives**: Firebase (Google tracking), Sentry (external server), local log files (✅ accepted).

**Impact**: ✅ Complete privacy, auditable | ❌ Harder to debug production | ⚠️ Silent failures undetected

---

## Deprecated Decisions

| Decision | Replaced By | Why |
|----------|-------------|-----|
| DOCX via `docx_to_text` | Native LOKit + Dart fallback | Lost formatting |
| Excel via `excel` Dart pkg | Apache POI native | Slow on large spreadsheets |
| pdfrx WASM modules | `dart run pdfrx:remove_wasm_modules` | Only needed for web |

## Related Files

- `technical-domain.md` — Technologies affected by these decisions
- `business-tech-bridge.md` — How decisions serve business goals
- `living-notes.md` — Current issues stemming from these decisions
