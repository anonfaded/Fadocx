# LOKit Migration Plan — Ship-Ready Document Viewing

## Strategy

- **PDF**: Keep `ModernPdfViewer` (pdfrx) — no changes
- **XLSX/XLS/CSV/ODS**: Keep `ProfessionalSheetViewer` (Apache POI) for viewing. Edit button added (coming soon dialog)
- **DOCX/DOC/ODT/RTF**: LOKit renderer with page-by-page rendering via `getPartPageRectangles()`
- **PPT/PPTX/ODP**: LOKit renderer with per-slide rendering
- **TXT/JSON/XML**: Keep existing Flutter viewers (no LOKit needed for plain text)

---

## Phase 1: LOKit Document Viewer Widget — DONE

- [x] 1.1 Create `LOKitDocumentViewer` widget
- [x] 1.2 Create `LOKitViewerNotifier` (Riverpod Notifier)
- [x] 1.3 Implement single-page rendering with InteractiveViewer zoom
- [x] 1.4 Add page/part navigation (bottom bar prev/next/first/last)
- [x] 1.5 Add zoom with 2x high-quality rendering + page preloading

## Phase 2: Integrate into ViewerScreen — DONE

- [x] 2.1 Update `ViewerScreen._buildContentViewer()` dispatch logic
  - DOCX/DOC/ODT/RTF → LOKitDocumentViewer (page-by-page via getPartPageRectangles)
  - PPT/PPTX/ODP → LOKitDocumentViewer (per-slide)
  - PDF → ModernPdfViewer (unchanged)
  - XLSX/XLS/CSV/ODS → ProfessionalSheetViewer (unchanged)
  - TXT → TextDocumentViewer (unchanged)
- [x] 2.2 Update `DocumentViewerFactory.createViewer()` — removed dead PPT/DOCX paths
- [x] 2.3 Remove `LOKitTestScreen` and its route
- [x] 2.4 Update `DocumentViewerNotifier` routing — LOKit formats skip text extraction
- [x] 2.5 Copy text extraction via `saveAs` to temp .txt file
- [x] 2.6 Copy dialog with current page vs all pages option
- [x] 2.7 Reset zoom button in appbar (reactive via onZoomChanged callback)
- [x] 2.8 Better loading messages ("Warming up the Fadocx engine...")
- [x] 2.9 Thumbnail previews for PPT/PPTX/ODP with slide count metadata

## Phase 3: Spreadsheet Edit Mode — DONE (UI only)

- [x] 3.1 Add "Edit" button to `ProfessionalSheetViewer` toolbar
- [x] 3.2 Dialog explaining engine integration, noting editing is coming soon
- [ ] 3.3 Actual editing via LOKit (future release)

## Phase 4: Performance & Polish — DONE

- [x] 4.1 Page preloading (adjacent ±2 pages cached, LRU eviction)
- [x] 4.2 Memory management — auto-dispose on screen leave, preload limits
- [x] 4.3 Text document pagination via `getPartPageRectangles()` for page-by-page
- [x] 4.4 Deferred LOKit init until first office document opened
- [x] 4.5 Graceful error handling with retry button

## Phase 5: APK Size & Build Optimization — FUTURE

- [ ] 5.1 Strip unused LO components from native-code.cxx
- [ ] 5.2 Optimize asset sizes (remove unused registry XCD files)
- [ ] 5.3 CI/CD setup (pre-built LO .so files in separate repo)

---

## File Map (New/Modified)

### New Files
- `lib/features/viewer/presentation/widgets/lokit_document_viewer.dart`
- `lib/features/viewer/presentation/providers/lokit_viewer_notifier.dart`

### Modified Files
- `lib/features/viewer/presentation/screens/viewer_screen.dart` — LOKit routing, zoom reset, copy dialog
- `lib/features/viewer/presentation/providers/document_viewer_notifier.dart` — LOKit routing
- `lib/features/viewer/presentation/widgets/document_viewer_factory.dart` — removed dead code
- `lib/features/viewer/presentation/widgets/professional_sheet_viewer.dart` — edit button
- `lib/core/services/thumbnail_generation_service.dart` — PPT thumbnails with metadata
- `lib/features/home/presentation/screens/documents_screen.dart` — removed Coming Soon for PPT
- `lib/config/routing/app_router.dart` — removed test route
- `lib/features/settings/presentation/screens/settings_screen.dart` — removed dev section
- `lib/features/viewer/data/services/lokit_service.dart` — extractText, renderTextPage, getPageCount
- `android/app/src/main/kotlin/com/fadseclab/fadocx/LOKitWrapper.kt` — text pagination, saveAs extraction
- `android/app/src/main/kotlin/com/fadseclab/fadocx/MainActivity.kt` — new MethodChannel handlers
- `android/app/proguard-rules.pro` — expanded POI keep rules

### Deleted Files
- `lib/features/viewer/presentation/screens/lokit_test_screen.dart`

---

## Key Decisions
- LOKit is a **raster renderer** — it produces PNG bitmaps
- Spreadsheets keep Apache POI for viewing (faster, interactive)
- Text documents use `getPartPageRectangles()` for page-by-page rendering
- Text extraction uses `saveAs(path, "text", "")` instead of `.uno:SelectAll` (more reliable in headless mode)
- PDF stays with pdfrx — purpose-built and more efficient
- LOKit init deferred until first office document open
- Thumbnails for PPT use lightweight metadata cards (slide count) instead of heavy LOKit rendering
