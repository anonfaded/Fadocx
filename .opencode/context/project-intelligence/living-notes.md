<!-- Context: project-intelligence/notes | Priority: high | Version: 2.0 | Updated: 2026-05-16 -->

# Living Notes — Fadocx

**Purpose**: Current state, technical debt, open questions, and active development notes.
**Last Updated**: 2026-05-16

## Technical Debt

| Item | Impact | Priority | Status |
|------|--------|----------|--------|
| `viewer_screen.dart` 2000+ lines | Hard to maintain, merge conflicts | High | Acknowledged |
| `dynamic` casts for child widget state | Runtime errors if child API changes | Medium | Acknowledged |
| Duplicate format routing logic | Notifier + repository both have switch statements | Medium | Acknowledged |
| Repeated cache-first pattern | 12 parser methods duplicate cache-check logic | Low | Acknowledged |
| `settings_providers.dart` 423 lines | Too many providers in one file | Low | Acknowledged |

### Technical Debt Details

**`viewer_screen.dart` 2000+ lines**  
*Priority*: High  
*Impact*: Slow builds, hard to navigate, merge conflict risk  
*Root Cause*: All viewer logic (PDF, LOKit, Text, Media, sidebar, animations, fullscreen) in one file  
*Proposed Solution*: Extract `_buildFloatingTopBar`, `_buildFloatingBottomPanel`, `_buildSidebarDrawer` into separate widget files  
*Effort*: Medium  
*Status*: Acknowledged

**`dynamic` casts for child widget state**  
*Priority*: Medium  
*Impact*: Runtime crashes if child widget API changes without parent update  
*Root Cause*: Parent accesses child via `key.currentState as dynamic` to call methods like `toggleSidebar()`, `goToNextPage()`  
*Proposed Solution*: Define typed interfaces (e.g., `NavigableViewerMixin`) that child widgets implement  
*Effort*: Medium  
*Status*: Acknowledged

**Duplicate format routing logic**  
*Priority*: Medium  
*Impact*: Adding a new format requires updating 2 switch statements  
*Root Cause*: `DocumentViewerNotifier` and `DocumentParsingRepositoryImpl` both route by extension  
*Proposed Solution*: Single `FormatRouter` registry with format→parser mapping  
*Effort*: Small  
*Status*: Acknowledged

## Open Questions

| Question | Stakeholders | Status | Next Action |
|----------|--------------|--------|-------------|
| iOS support timeline | anonfaded | Open | Plan Flutter iOS compatibility for pdfrx/LOKit |
| FadDrive E2E encryption design | anonfaded | Open | Research encryption protocols for sync |
| More OCR languages | Community | Open | Evaluate Tesseract language packs + storage impact |
| Document editing scope | anonfaded | Open | Define MVP: text formatting vs full WYSIWYG |

## Known Issues

| Issue | Severity | Workaround | Status |
|-------|----------|------------|--------|
| pdfrx LayoutBuilder null check error | Medium | Use `GlobalKey<State<ModernPdfViewer>>` + `RepaintBoundary` | Known, worked around |
| Hive fields silently dropped if adapter not regenerated | High | Always run `build_runner` after `@HiveField` changes | Known, documented in AGENTS.md |
| Large APK size (~346MB) | Low | Accept as trade-off for embedded LibreOfficeKit | Known, by design |
| Session time not saved if dispose called before mutator | Medium | Use saved `_savedMutator` reference (already implemented) | Fixed |

## Insights & Lessons Learned

### What Works Well
- **Riverpod autoDispose** — Viewer state resets cleanly on each document open, no memory leaks
- **Cache-first parsing** — Dramatically improves repeat-open performance for large documents
- **Private app storage** — Users appreciate files being hidden from file manager
- **Format factory pattern** — `DocumentViewerFactory` cleanly delegates to specialized viewers

### What Could Be Better
- **Viewer screen size** — 2000+ lines is unsustainable; needs decomposition
- **Build time** — ~346MB APK takes long to build and install
- **Error messages** — Some parsing failures show raw exception text instead of user-friendly messages

### Lessons Learned
- **Hive adapter regeneration is critical** — Missing `build_runner` run causes silent data loss (fields exist in model but not in adapter)
- **GlobalKey persists state across rebuilds** — Essential for pdfrx viewer to survive parent `setState()` calls
- **`TweenAnimationBuilder` resets on parent rebuild** — Must use `StatefulWidget` + `AnimationController` + `didUpdateWidget` for prop-driven animations
- **Native platform channels must run on background threads** — POI/PDFBox parsing blocks UI if not threaded

## Patterns & Conventions

### Code Patterns Worth Preserving
- **Result<T> pattern** — Type-safe error handling without `Either` dependency (`lib/core/errors/failures.dart`)
- **Lazy Hive box loading** — Settings box opened at startup, recent files/thumbnails opened on first access
- **Reflection-based native init** — `MainActivity.kt` has zero heavy imports; parsers loaded via reflection
- **Post-frame callback deferral** — Data loading deferred until first frame rendered (`WidgetsBinding.instance.addPostFrameCallback`)

### Gotchas for Maintainers
- **pdfrx WASM modules** — Run `dart run pdfrx:remove_wasm_modules` before building for Android
- **Flavor-specific icons** — Beta/prod icons need separate `flutter_launcher_icons` config files
- **Git LFS required** — Native libraries stored via LFS; `git lfs pull --all` after clone
- **Build flavors** — `prod` = `com.fadseclab.fadocx`, `beta` = `com.fadseclab.fadocx.beta` — can install both simultaneously

## Active Projects

| Project | Goal | Owner | Timeline |
|---------|------|-------|----------|
| LibreOfficeKit migration | Improve Office document rendering quality | anonfaded | In progress |
| FadDrive | E2E encrypted cloud sync | anonfaded | Planned |
| Document editing | Full formatting support | anonfaded | Planned |
| More OCR languages | Multi-language text extraction | anonfaded | Planned |
| Desktop + iOS | Cross-platform expansion | anonfaded | Long-term |

## Archive (Resolved Items)

### Resolved: Session time not saving on dispose
- **Resolved**: 2025
- **Resolution**: Use saved `_savedMutator` and `_sessionFilePath` references in `dispose()` instead of `ref.read()`
- **Learnings**: Riverpod `ref` is unsafe in `dispose()` — save references before widget destruction

### Resolved: PDF viewer state lost on theme toggle
- **Resolved**: 2025
- **Resolution**: Use `GlobalKey<State<ModernPdfViewer>>` (not `ValueKey`) to persist state across rebuilds
- **Learnings**: `GlobalKey` maintains state when widget type is same; `ValueKey` does not

## Onboarding Checklist

- [x] Review technical debt — viewer_screen.dart decomposition is highest priority
- [x] Know open questions — iOS support and FadDrive are biggest unknowns
- [x] Understand known issues — pdfrx null check and Hive adapter regeneration are key gotchas
- [x] Be aware of patterns — Result<T>, lazy Hive, reflection-based init, post-frame deferral
- [x] Know active projects — LibreOfficeKit migration is current focus

## Related Files

- `decisions-log.md` — Why technologies were chosen (context for current debt)
- `business-domain.md` — Business priorities driving active projects
- `technical-domain.md` — Technical implementation details
