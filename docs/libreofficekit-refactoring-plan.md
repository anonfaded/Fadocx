# Fadocx → LibreOfficeKit Refactoring Plan

## Goal
Replace all custom document parsers (Apache POI, Dart DOCX/RTF/ODT parsers) with LibreOfficeKit for professional-grade document viewing AND editing across all office formats.

## What Changes

### Formats Affected

| Format | Current Parser | Current Viewer | LOKit Replacement |
|---|---|---|---|
| DOC | Apache POI HWPF (Kotlin) | RichDocumentViewer | LOKit Writer (tiles) |
| DOCX | Apache POI XWPF (Kotlin) + Dart fallback | RichDocumentViewer | LOKit Writer (tiles) |
| RTF | Custom Dart _RtfParser | RichDocumentViewer | LOKit Writer (tiles) |
| ODT | Dart XML (text:p only) | RichDocumentViewer | LOKit Writer (tiles) |
| XLS | Apache POI HSSF (Kotlin) | ProfessionalSheetViewer | LOKit Calc (tiles) |
| XLSX | Apache POI XSSF (Kotlin) | ProfessionalSheetViewer | LOKit Calc (tiles) |
| ODS | Dart XML parser | ProfessionalSheetViewer | LOKit Calc (tiles) |
| CSV | Custom Dart parser | ProfessionalSheetViewer | LOKit Calc (tiles) or keep existing |
| PPT | None (placeholder) | None | LOKit Impress (tiles) |
| PPTX | None (placeholder) | None | LOKit Impress (tiles) |
| ODP | None (placeholder) | None | LOKit Impress (tiles) |
| PDF | pdfrx + Android PdfRenderer | ModernPdfViewer | **No change** — keep existing |
| TXT | Dart file I/O | TextDocumentViewer | **No change** — keep existing |

### Files to Remove After Migration

| File | Reason |
|---|---|
| `android/.../NativeDocumentParser.kt` | Replaced by LOKit |
| `android/.../PdfTextExtractor.kt` | Keep only for PDF text search (pdfrx path) |
| `lib/.../word_document_parser_service.dart` | Replaced by LOKit |
| `lib/.../document_parser_service.dart` | Replaced by LOKit |
| `lib/.../rich_document_viewer.dart` | Replaced by LOKit tile viewer |
| `lib/.../document_viewer_factory.dart` | Simplified (route office docs to LOKit viewer) |
| `lib/.../rich_document_search_drawer.dart` | Replaced by LOKit-based search |

### Dependencies to Remove

| Dependency | Reason |
|---|---|
| Apache POI (`poi`, `poi-ooxml`, `poi-scratchpad`) | Replaced by LOKit |
| xmlbeans | Only needed by POI |
| commons-io, commons-codec, commons-logging | Transitive POI deps |
| `archive` package (for DOCX/ODT ZIP parsing) | Only needed if keeping thumbnail gen without LOKit |
| `xml` package (for DOCX/ODT XML parsing) | Only needed if keeping thumbnail gen without LOKit |

### New Files to Create

| File | Purpose |
|---|---|
| `android/.../lokit/LOKitWrapper.kt` | JNI bridge: init, documentLoad, paintTile, postKeyEvent, postMouseEvent, postUnoCommand, callbacks |
| `android/.../lokit/LOKitTileProvider.kt` | Tile rendering thread pool, RGBA buffer management |
| `android/.../lokit/LOKitCallbackHandler.kt` | Handle LOK_CALLBACK_INVALIDATE_TILES, CURSOR_POSITION, TEXT_SELECTION, STATE_CHANGED |
| `android/.../lokit/LOKitBootstrap.kt` | Load .so chain, call libreofficekit_hook_2(), initialize LO environment |
| `lib/.../lokit_viewer/libre_office_document_viewer.dart` | Flutter widget: tile-based document rendering, scroll/zoom, gesture bridge |
| `lib/.../lokit_viewer/tile_cache.dart` | LRU tile cache (256x256 RGBA buffers) |
| `lib/.../lokit_viewer/cursor_overlay.dart` | Text cursor + selection rectangle overlay |
| `lib/.../lokit_viewer/formatting_toolbar.dart` | Bold/italic/underline/font/size/alignment toolbar |
| `lib/.../lokit_viewer/lokit_method_channel.dart` | Dart side of MethodChannel `com.fadseclab.fadocx/lokit` |
| `lib/.../providers/lokit_provider.dart` | Riverpod provider for LOKit state |

## Architecture

### Data Flow — Viewing

```
User opens file
    │
    ▼
ViewerScreen detects format
    │
    ├─ PDF → ModernPdfViewer (unchanged)
    ├─ TXT → TextDocumentViewer (unchanged)
    └─ Office doc → LibreOfficeDocumentViewer
                        │
                        ▼
               LOKitProvider (Riverpod)
                        │
                        ▼
               MethodChannel → LOKitWrapper.kt
                        │
                        ▼
               libreofficekit_hook_2() → Office → documentLoad()
                        │
                        ▼
               getDocumentSize() → page dimensions in TWIPs
                        │
                        ▼
               ScrollController tracks viewport
                        │
                        ▼
               For each visible 256x256 tile:
                 paintTile(buffer, w, h, x, y, tw, th) → RGBA bytes
                        │
                        ▼
               Flutter Texture widget displays tile
```

### Data Flow — Editing

```
User taps on document
    │
    ▼
Flutter GestureDetector → x,y coordinates
    │
    ▼
Convert pixel coords → TWIPs (1 TWIP = 1/1440 inch)
    │
    ▼
MethodChannel → postMouseEvent(type, x, y, count, buttons, modifier)
    │
    ▼
LOKit processes input → internal document state changes
    │
    ▼
LOKit fires callback: LOK_CALLBACK_INVALIDATE_TILES
    │
    ▼
CallbackHandler → MethodChannel → Flutter invalidates affected tiles
    │
    ▼
Flutter re-requests affected tiles → repaint
```

### Data Flow — Formatting Toolbar

```
User taps Bold button
    │
    ▼
MethodChannel → postUnoCommand(".uno:Bold", "")
    │
    ▼
LOKit toggles bold on selection
    │
    ▼
LOKit fires: INVALIDATE_TILES + STATE_CHANGED
    │
    ▼
Flutter re-renders affected tiles + updates toolbar state
```

### Threading Model

```
Flutter UI Thread
    │ (MethodChannel)
    ▼
Android Main Thread (Kotlin handler)
    │ (queue to)
    ▼
LOKit Thread (single dedicated thread — LOKit is NOT thread-safe)
    │
    ├── documentLoad()
    ├── paintTile()
    ├── postKeyEvent()
    ├── postMouseEvent()
    └── postUnoCommand()
    │ (callback)
    ▼
CallbackHandler → posts back to Android Main Thread
    │ (MethodChannel)
    ▼
Flutter UI Thread → setState / repaint
```

## Phased Implementation

### Phase 0 — Spike (current)
- [ ] Build LO core on Linux VM for arm64
- [ ] Produce `liblo-native-code.so`
- [ ] Measure real size per ABI
- [ ] Smoke test: load .so, open DOCX, get page count
- [ ] Document exact build steps

### Phase 1 — JNI Layer
- [ ] Create `LOKitBootstrap.kt` — load .so chain, init LO environment
- [ ] Create `LOKitWrapper.kt` — wrap all LOKit C API calls
- [ ] Create `LOKitTileProvider.kt` — tile rendering with RGBA buffer pool
- [ ] Create `LOKitCallbackHandler.kt` — forward LOK callbacks to Flutter
- [ ] Create MethodChannel `com.fadseclab.fadocx/lokit`
- [ ] Bundle `liblo-native-code.so` + deps in `jniLibs/`
- [ ] Update ProGuard rules for LOKit JNI classes
- [ ] Test: open DOCX, render first tile as bitmap, display in Flutter

### Phase 2 — Flutter Viewer (Viewing Only)
- [ ] Create `LibreOfficeDocumentViewer` widget
- [ ] Implement tile-based scrolling with viewport tracking
- [ ] Implement tile cache (LRU, ~100 tiles)
- [ ] Handle zoom (setClientZoom + re-tile)
- [ ] Handle document types: Writer (paginated), Calc (sheet grid), Impress (slides)
- [ ] Loading state (LOKit init takes 2-5s on first load)
- [ ] Error states (unsupported format, corrupt file, OOM)
- [ ] Wire into `ViewerScreen` for all office formats

### Phase 3 — Editing Support
- [ ] Touch → TWIP coordinate conversion
- [ ] `postMouseEvent` bridge (tap, long-press, drag for selection)
- [ ] Keyboard input bridge (virtual keyboard → postKeyEvent)
- [ ] Cursor overlay (LOK_CALLBACK_CURSOR_POSITION)
- [ ] Selection overlay (LOK_CALLBACK_TEXT_SELECTION)
- [ ] Formatting toolbar (Bold, Italic, Underline, Font, Size, Alignment, Color)
- [ ] Undo/Redo (.uno:Undo, .uno:Redo)
- [ ] Save (.uno:Save or saveAs)

### Phase 4 — Thumbnails & Search
- [ ] Switch thumbnail generation to LOKit (render first page tile at 400x560)
- [ ] Implement text search via LOKit getTextSelection / search commands
- [ ] Search result highlighting

### Phase 5 — Presentation Support
- [ ] Slide navigation (setPart, getParts)
- [ ] Slide thumbnails sidebar (paintPartTile)
- [ ] Presentation mode (fullscreen, swipe between slides)

### Phase 6 — Cleanup & Removal
- [ ] Remove `NativeDocumentParser.kt`
- [ ] Remove `word_document_parser_service.dart`
- [ ] Remove `document_parser_service.dart` (keep TXT/CSV helpers if needed)
- [ ] Remove `rich_document_viewer.dart` and related
- [ ] Remove Apache POI + xmlbeans + commons deps from build.gradle.kts
- [ ] Remove `archive` + `xml` Dart packages if no longer needed
- [ ] Update ProGuard rules (remove POI keep rules)
- [ ] Update AGENTS.md
- [ ] Full regression test on all formats

## Size Impact Estimate

| Component | Current (arm64) | After LOKit |
|---|---|---|
| Native libs | ~43 MB | ~43 MB (existing) |
| LOKit .so | 0 | ~120-150 MB (TBD from spike) |
| POI + deps (DEX + resources) | ~19 MB | 0 MB (removed) |
| **Total per ABI** | **~68 MB** | **~160-190 MB** |

## Risks

| Risk | Mitigation |
|---|---|
| LOKit .so too large | Build minimal config (Writer+Calc only, exclude Impress if possible) |
| First load slow (2-5s) | Show skeleton loading state, preload LOKit on app start |
| High memory on large docs | Implement viewport-only tile rendering, cap tile cache |
| LOKit not thread-safe | Enforce single LOKit thread via Handler/Looper |
| Build complexity | Document everything in this guide, automate with scripts |
| iOS has no LOKit | Keep existing parsers as iOS fallback (accept lower fidelity on iOS) |
| License compliance (MPLv2) | Make LOKit source available, keep Fadocx code separate |
