# Fadocx Major Redesign - Implementation Plan

## Phase 1: Theme & Layout Foundation
- [ ] Create forest green Material3 theme (`#2D6A4F` primary)
- [ ] Update theme_provider.dart with custom colors
- [ ] Fix PDF viewer: remove double top dock, single floating dock at top
- [ ] Create second floating dock on right (invert/text-mode)
- [ ] Update all back buttons to use angled chevron icon (‹)
- [ ] Make docks float over content (Stack-based, not SafeArea-based)

## Phase 2: Storage & Caching System
- [ ] Create storage service: `getExternalFilesDir()` → `fadocx_docs/{category}/`
- [ ] Auto-cache on document open (PDF, DOCX, XLSX, etc.)
- [ ] Add cache size calculation to Settings
- [ ] Manual cache clear option in Settings

## Phase 3: File Permissions & Browse
- [ ] Add READ_EXTERNAL_STORAGE permission manifest
- [ ] Create file browser screen (shows device files)
- [ ] Implement permission request flow
- [ ] List files categorized by type

## Phase 4: Scanning & OCR
- [ ] Camera FAB on HomeScreen (always visible)
- [ ] Scanning screen: capture → edge detection → crop
- [ ] OCR processing: Tesseract on captured image
- [ ] OCR result screen: visual text boxes + selection/copy
- [ ] Save scanned docs to `fadocx_docs/Scans/`

## Phase 5: UI Redesign (Settings)
- [ ] Row-based card layout for settings
- [ ] Theme selector cards
- [ ] Language selector cards
- [ ] Permissions card
- [ ] Cache info card
- [ ] About card

## Phase 6: Bottom Navigation Dock
- [ ] Design floating dock: Home | Browse | Recents | Settings
- [ ] Tab-based navigation
- [ ] Add Recents feature (thumbnail list)
- [ ] Integrate scanning FAB

## Phase 7: HomeScreen Enhancement
- [ ] Add scanning card button
- [ ] Quick actions section
- [ ] Document suggestions

## Storage Structure
```
/data/user/0/com.fadseclab.fadocx/files/fadocx_docs/
├── PDFs/
│   ├── file1.pdf
│   └── file2.pdf
├── Documents/
│   ├── doc1.docx
│   └── doc2.docx
├── Spreadsheets/
│   ├── sheet1.xlsx
│   └── sheet2.xls
├── Presentations/
├── Images/
└── Scans/
    ├── scan_001.jpg
    └── scan_001_ocr.txt
```

## Key Files to Create/Modify
- `lib/config/theme/app_theme.dart` - Forest green colors
- `lib/core/services/storage_service.dart` - Cache management
- `lib/core/services/ocr_service.dart` - Tesseract integration
- `lib/features/scanner/` - New scanner feature
- `lib/features/settings/screens/settings_screen.dart` - Row layout
- `lib/features/viewer/widgets/modern_pdf_viewer.dart` - Fix docks
- `lib/features/home/screens/home_screen.dart` - Add FAB + cards
- Android manifest - Permissions

