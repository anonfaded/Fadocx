# LOKit Migration Plan — Ship-Ready Document Viewing

## Strategy

- **PDF**: Keep `ModernPdfViewer` (pdfrx) — no changes
- **XLSX/XLS/CSV/ODS**: Keep `ProfessionalSheetViewer` (Apache POI) for viewing. Add "Edit" button that opens LOKit editor
- **DOCX/DOC/ODT/RTF**: Replace with LOKit renderer (native rendering via LibreOffice)
- **PPT/PPTX/ODP**: Replace with LOKit renderer (was "Coming Soon" placeholder — now real)
- **TXT/JSON/XML**: Keep existing Flutter viewers (no LOKit needed for plain text)

---

## Phase 1: LOKit Document Viewer Widget

- [ ] 1.1 Create `LOKitDocumentViewer` widget (lib/features/viewer/presentation/widgets/lokit_document_viewer.dart)
  - Stateless widget, takes `filePath` and `format`
  - Manages LOKit lifecycle (init, load, render, dispose) via Riverpod
  - Shows loading spinner during init/render
  - Error handling with retry button

- [ ] 1.2 Create `LOKitViewerNotifier` (Riverpod AsyncNotifier)
  - Manages LOKit state: init, document loaded, current part, rendering
  - Methods: `initialize()`, `loadDocument(path)`, `renderCurrentPart()`, `nextPart()`, `prevPart()`, `setPart(n)`
  - Holds rendered page image bytes
  - Computes page dimensions from document info

- [ ] 1.3 Implement single-page rendering
  - Use `doc.setPart(n)` to select page
  - Get part dimensions via `doc.documentWidth` / `doc.documentHeight` after `setPart`
  - Render at screen-appropriate DPI (target 150 DPI for initial render, tile at higher DPI for zoom)
  - Display in `InteractiveViewer` with zoom support

- [ ] 1.4 Add page/part navigation
  - Bottom bar: "Page X of Y" with prev/next arrows
  - Swipe left/right gesture to change pages
  - Part list sidebar for presentations (slide thumbnails)

- [ ] 1.5 Add zoom with crisp rendering
  - On zoom change, re-render at higher resolution for the visible area
  - Use tile-based approach: divide visible area into 256x256 tiles
  - Render each tile at the zoomed DPI
  - Cache rendered tiles, evict when zoom changes significantly

## Phase 2: Integrate into ViewerScreen

- [ ] 2.1 Update `ViewerScreen._buildContentViewer()` dispatch logic
  - `DOCX || DOC || ODT || RTF` → `LOKitDocumentViewer` (replace RichDocumentViewer / TextDocumentViewer)
  - `PPT || PPTX || ODP` → `LOKitDocumentViewer` (replace "Coming Soon" placeholder)
  - Keep PDF → ModernPdfViewer
  - Keep XLSX/XLS/CSV/ODS → ProfessionalSheetViewer (with edit button)

- [ ] 2.2 Update `DocumentViewerFactory.createViewer()` to match
  - Remove dead code paths for PDF/Text (ViewerScreen handles them)
  - Add LOKit path for document/presentation formats

- [ ] 2.3 Remove `LOKitTestScreen` and its route
  - Route `/lokit-test` → remove from app_router.dart
  - Remove settings "Developer → Test LibreOfficeKit" button
  - Remove `lokit_test_screen.dart`

- [ ] 2.4 Update `DocumentViewerNotifier` routing
  - For DOCX/DOC/ODT/RTF/PPT/PPTX/ODP: skip text extraction, just pass filePath to LOKit viewer
  - Don't create `ParsedDocumentEntity` for LOKit formats (LOKit handles rendering natively)

## Phase 3: Spreadsheet Edit Mode

- [ ] 3.1 Add "Edit in LibreOffice" button to `ProfessionalSheetViewer` toolbar
  - Only shown for XLSX/XLS/ODS (not CSV — CSV edits via text)
  - Button opens a new `LOKitEditorScreen` or switches viewer mode

- [ ] 3.2 Create `LOKitEditorScreen` or inline editor mode
  - Full-screen LOKit rendering with editing capabilities
  - Forward keyboard input via `postKeyEvent()`
  - Forward touch events via `postMouseEvent()`
  - Handle cursor/selection overlay from LOKit callbacks

- [ ] 3.3 Add save/export functionality
  - Save button calls `office.saveDocument()` or equivalent
  - Export to PDF option
  - "Save As" to different format

## Phase 4: Performance & Polish

- [ ] 4.1 Fix fontconfig warnings
  - Extract fonts.conf to `<dataDir>/etc/fonts/fonts.conf` at setup
  - Set `FONTCONFIG_FILE` env var in LOKitWrapper.init()

- [ ] 4.2 Background document loading
  - Show loading progress indicator
  - Pre-render first page while loading rest
  - Lazy load page thumbnails for sidebar

- [ ] 4.3 Memory management
  - LOKit singleton lifecycle tied to app lifecycle
  - Destroy/recreate on low memory
  - Tile cache eviction policy (LRU, max 50 tiles)
  - Release document when navigating away

- [ ] 4.4 Startup optimization
  - Defer LOKit init until first office document is opened
  - Show splash/loading while LOKit boots (~2-3 seconds)
  - Cache LOKit init state across screen navigations

- [ ] 4.5 Error handling & UX
  - Graceful fallback if LOKit init fails (show text-only view)
  - Progress indicators for rendering
  - Toast messages for errors

## Phase 5: APK Size & Build Optimization

- [ ] 5.1 Strip unused LO components from native-code.cxx
  - Remove chart2, dbaccess, scripting, VBA if not needed
  - Rebuild liblo-native-code.so with reduced components

- [ ] 5.2 Optimize asset sizes
  - Remove unused registry XCD files (keep only essential)
  - Compress non-essential assets
  - Consider on-demand asset extraction

- [ ] 5.3 CI/CD setup
  - Host pre-built LO .so files + assets in separate repo
  - Download during Flutter build instead of git-tracking
  - Automate APK builds

---

## File Map (New/Modified)

### New Files
- `lib/features/viewer/presentation/widgets/lokit_document_viewer.dart`
- `lib/features/viewer/presentation/providers/lokit_viewer_notifier.dart`

### Modified Files
- `lib/features/viewer/presentation/screens/viewer_screen.dart` — update dispatch logic
- `lib/features/viewer/presentation/providers/document_viewer_notifier.dart` — add LOKit routing
- `lib/features/viewer/presentation/widgets/document_viewer_factory.dart` — add LOKit viewers
- `lib/features/viewer/presentation/widgets/professional_sheet_viewer.dart` — add "Edit" button
- `lib/config/routing/app_router.dart` — remove test route
- `lib/features/settings/presentation/screens/settings_screen.dart` — remove test button
- `android/app/src/main/kotlin/com/fadseclab/fadocx/LOKitWrapper.kt` — ongoing fixes

### Deleted Files
- `lib/features/viewer/presentation/screens/lokit_test_screen.dart` — after integration complete

---

## Key Decisions
- LOKit is a **raster renderer** — it produces PNG bitmaps, not vector/text content
- Spreadsheets keep native parsing (Apache POI) for viewing because the Flutter sheet viewer is faster and more interactive than raster images
- LOKit is only used for formats where Flutter can't render natively (DOCX, PPT, etc.)
- PDF stays with pdfrx — it's purpose-built for PDF and more efficient
- LOKit init happens on first office document open, not at app startup
