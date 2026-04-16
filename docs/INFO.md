# Fadocx MVP Specification (Offline Document Viewer Suite)

## 1. Product Vision

Fadocx is an offline-first, cross-platform document tool built with Flutter.

It focuses on:
- Fast document viewing
- Universal format support
- Clean UX without bloat

Supported formats in MVP:
- PDF (.pdf)
- Word (.docx)
- Excel (.xlsx)

Platforms:
- Android (priority for first release APK)
- Windows
- Linux
- macOS

No cloud dependency. Fully offline.

---

## 2. MVP Scope (STRICT)

### Included in MVP
- Open local documents
- Detect file type automatically
- Render documents:
  - PDF viewer
  - DOCX viewer (basic rendering)
  - XLSX viewer (basic table view)
- Recent files list
- Simple file picker integration

### NOT included in MVP
- Editing documents
- Annotation system
- Conversion between formats
- Scanner
- OCR / ML features
- Cloud sync
- Accounts / login

---

## 3. Core Architecture

### Layered Design

```

UI Layer (Flutter)
↓
Document Router Layer
↓
Format Engines
├── PDF Engine
├── DOCX Engine
├── XLSX Engine
↓
File System Layer

```

---

### 3.1 UI Layer (Flutter)
Responsibilities:
- Home screen
- Recent files
- File picker
- Viewer screen routing

Keep UI dumb and reactive.

---

### 3.2 Document Router (Core Logic)

Single responsibility:
- Detect file extension
- Route to correct engine

Supported types:
- .pdf → PDF Engine
- .docx → DOCX Engine
- .xlsx → XLSX Engine

---

### 3.3 Format Engines

#### PDF Engine (Most important)
Recommended package:
- syncfusion_flutter_pdfviewer

Capabilities:
- fast rendering
- zoom / scroll
- page navigation
- text selection

Alternative:
- pdfrx (lighter, open-source alternative)

---

#### DOCX Engine
Recommended package:
- docx_viewer

Behavior:
- convert DOCX → readable text structure
- render using Flutter widgets or HTML renderer

Limitations:
- no perfect layout fidelity (acceptable for MVP)

---

#### XLSX Engine
Recommended package:
- excel (Dart package)

Behavior:
- parse sheets
- render grid/table UI
- switch between sheets

Limitations:
- basic Excel features only (no full formula engine UI)

---

## 4. Storage Layer (Offline-first)

Packages:
- path_provider
- hive OR isar

Stores:
- recent files list
- cached metadata
- thumbnails (optional PDF pages)

Rule:
Do NOT modify original files unless explicitly saving a new version.

---

## 5. Recommended Flutter Packages (Cross-platform stable)

### File handling
- file_picker
- path_provider
- permission_handler

### State management (IMPORTANT)
Recommended:
- riverpod (preferred)

Why:
- scalable
- testable
- avoids boilerplate
- works well for multi-engine architecture

Alternative:
- bloc (good but heavier)
- provider (too limited for long-term scaling)

---

### Document rendering

PDF:
- syncfusion_flutter_pdfviewer (feature-rich, stable)
- pdfrx (lighter alternative)

DOCX:
- docx_viewer

XLSX:
- excel

---

### Routing
- go_router

---

### UI utilities
- flutter_hooks (optional, improves state handling readability)
- freezed (for immutable models)

---

## 6. Platform Strategy

### Android (first priority)
- optimize APK first
- test all engines here first

### Desktop (second phase)
- Windows: primary desktop target
- Linux/macOS: ensure rendering compatibility

Flutter ensures:
- single codebase
- native compilation per platform

---

## 7. Performance Strategy

- Lazy load documents
- Do NOT preload full files into memory
- Use pagination for PDF rendering
- Cache only thumbnails + metadata
- Avoid heavy computations on UI thread

---

## 8. Scaling Strategy (Post-MVP)

After user feedback:

Phase 2:
- PDF annotations
- DOCX improved rendering
- better XLSX UI grid system

Phase 3:
- document scanner
- OCR (TFLite or ML Kit)
- smart search inside documents

Phase 4:
- conversion engine
- plugin-based architecture for formats

---

## 9. Key Design Principle

> Flutter is the UI layer. Document engines are modular plugins.

Never embed logic inside UI layer.

Each format = independent engine module.

---

## 10. Build Strategy (FAST APK FIRST)

Step 1:
- implement PDF viewer only
- create file picker + router
- release internal APK

Step 2:
- add DOCX viewer

Step 3:
- add XLSX viewer

Step 4:
- stabilize + collect feedback

---

## 11. Success Definition for MVP

MVP is successful if:
- user can open any PDF, DOCX, XLSX file
- app does not crash on unsupported formats
- performance is smooth on mid-range Android devices
- no editing features required

---

## 12. Final Notes

This is NOT an Office replacement.

It is:
- fast document viewer
- offline-first utility
- base for future document ecosystem expansion
