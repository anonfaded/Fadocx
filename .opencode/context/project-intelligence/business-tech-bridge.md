<!-- Context: project-intelligence/bridge | Priority: critical | Version: 2.0 | Updated: 2026-05-16 -->

# Business ↔ Tech Bridge — Fadocx

**Purpose**: How Fadocx's privacy-first business requirements drive every technical decision.
**Last Updated**: 2026-05-16

## Core Mapping

| Business Need | Technical Solution | Why This Mapping | Business Value |
|---------------|-------------------|------------------|----------------|
| 100% offline viewing | Flutter + pdfrx + embedded LibreOfficeKit | No server dependency; all rendering on-device | Users trust app with sensitive documents |
| No tracking/telemetry | No analytics SDK, no internet permission for core features | Eliminates data collection surface | Privacy promise kept, auditable |
| Private file storage | App-specific storage (`Android/data/`) | Files hidden from file manager, inaccessible to other apps | Users control their documents |
| On-device OCR | Tesseract + OpenCV preprocessing | No cloud API calls for text extraction | Works offline, no data leaves device |
| Multi-format support | Format routing + native platform channels (Apache POI) | One app replaces 5+ single-format apps | User convenience, app stickiness |
| Cross-platform future | Flutter framework | Single codebase for Android → iOS → Desktop | Faster expansion, consistent UX |
| Community translations | flutter_localizations + .arb files | 11 languages without external services | Global reach, community contribution |
| Fast startup | Lazy Hive box loading, reflection-based native init | Heavy libs (POI, PDFBox) loaded on-demand | Good first impression, user retention |

## Feature Mappings

### Feature: Document Viewer (30+ formats)

**Business Context**:
- User need: Open any document type without installing multiple apps
- Business goal: Become the go-to offline document viewer
- Priority: Core feature — defines the product

**Technical Implementation**:
- Solution: Format routing switch → 4 viewer widgets (PDF, LOKit, Text, Media)
- Architecture: `DocumentParsingRepositoryImpl` orchestrates native + Dart parsers
- Trade-offs: Embedded LibreOfficeKit adds ~200MB to APK but enables desktop-class rendering

**Connection**: Without native LibreOfficeKit, DOCX/PPT rendering would be poor quality — users would abandon the app. The APK size trade-off is worth it for rendering fidelity.

### Feature: Private Storage + Library

**Business Context**:
- User need: Keep documents hidden from other apps and file managers
- Business goal: Differentiate from cloud-sync competitors
- Priority: Core privacy feature

**Technical Implementation**:
- Solution: Files copied to `Android/data/com.fadseclab.fadocx/files/`
- Architecture: `StorageService` manages import/cache/export/delete lifecycle
- Trade-offs: Files not visible in file manager = users must use app to access them

**Connection**: Private storage is the technical enforcement of the privacy promise. Users trade convenience (file manager access) for security (app isolation).

### Feature: Reading Time Tracking

**Business Context**:
- User need: Understand engagement with documents
- Business goal: Provide unique value beyond basic viewing
- Priority: Differentiator feature

**Technical Implementation**:
- Solution: Session timer starts on viewer open, ends on pop, accumulates per-file
- Architecture: `RecentFilesMutator.startViewingSession()` / `endViewingSession()`
- Trade-offs: Approximate (doesn't track active vs idle time)

**Connection**: Reading stats dashboard on home screen creates user engagement and demonstrates app intelligence without any cloud dependency.

### Feature: Rich Thumbnails

**Business Context**:
- User need: Preview document content before opening
- Business goal: Professional, polished UX
- Priority: Quality-of-life feature

**Technical Implementation**:
- Solution: Extract real document pages/images → render → cache as PNG in Hive
- Architecture: `ThumbnailGenerationService` + `HiveThumbnail` model
- Trade-offs: Thumbnail generation is CPU-intensive; done asynchronously

**Connection**: Real content previews (not generic icons) signal quality and help users identify documents quickly — reinforcing the "premium free app" positioning.

## Trade-off Decisions

| Situation | Business Priority | Technical Priority | Decision Made | Rationale |
|-----------|-------------------|-------------------|---------------|-----------|
| APK size vs format support | Support all formats | Keep APK small | Embed LibreOfficeKit (~346MB) | Users accept size for 30+ format support |
| Dart fallback vs native-only | Reliability | Performance | Native preferred + Dart fallback (DOCX) | Graceful degradation when native unavailable |
| Hive vs SQLite | Fast, simple | Relational queries | Hive (NoSQL, codegen) | Simpler, faster for key-value document metadata |
| pdfrx vs custom PDF | Quick shipping | Full control | pdfrx library | Mature PDF engine, saves months of work |

## Common Misalignments

| Misalignment | Warning Signs | Resolution Approach |
|--------------|---------------|---------------------|
| Adding cloud features | Requests for sync, cloud backup | Remind: offline-first is core identity; FadDrive is the planned E2E solution |
| Telemetry requests | "We need crash reporting" | Use log files + user-submitted bug reports instead |
| Format bloat | "Add format X" | Evaluate: is there user demand? Can existing parsers handle it? |

## Stakeholder Communication

**For Business Stakeholders**:
- Every technical choice serves the privacy-first mission
- APK size is a feature investment (embedded rendering engine = no cloud dependency)
- Open-source builds trust — users can verify no tracking exists

**For Technical Stakeholders**:
- Offline constraint means no cloud APIs, no remote config, no crash reporting
- arm64-only is a hard constraint (LibreOffice native code)
- Hive codegen requires `build_runner` after model changes

## Onboarding Checklist

- [x] Understand how privacy requirement drives every architecture decision
- [x] See how each feature maps to business value (viewer → convenience, storage → privacy)
- [x] Know the key trade-offs (APK size vs format support, native vs Dart fallback)
- [x] Understand why cloud features are deferred (FadDrive is the planned solution)

## Related Files

- `business-domain.md` — Privacy-first mission and target users
- `technical-domain.md` — Flutter, Riverpod, Hive, LibreOfficeKit implementation
- `decisions-log.md` — Why specific technologies were chosen
- `living-notes.md` — Current open questions about future features
