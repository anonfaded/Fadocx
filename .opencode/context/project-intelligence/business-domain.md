<!-- Context: project-intelligence/business | Priority: critical | Version: 2.0 | Updated: 2026-05-16 -->

# Business Domain — Fadocx

**Purpose**: Why Fadocx exists, who it serves, and the value it delivers.
**Last Updated**: 2026-05-16

## Project Identity

```
Project Name: Fadocx
Tagline: All-in-one offline document viewer — zero trackers, zero ads, fully open-source
Problem: Document apps are cloud-dependent, track users, show ads, and compromise privacy
Solution: 100% offline document viewer with private storage, on-device OCR, no telemetry
```

## Target Users

| User Segment | Who They Are | What They Need | Pain Points |
|--------------|--------------|----------------|-------------|
| **Privacy-conscious users** | Individuals who value data privacy | View documents without cloud uploads or tracking | Every mainstream app sends data to servers |
| **Offline workers** | Users in low-connectivity areas | Full document access without internet | Cloud apps fail without connection |
| **Professionals** | Lawyers, researchers, students | View PDFs, Office docs, spreadsheets, code | Need multiple apps for different formats |
| **Open-source advocates** | Users who want auditable software | Transparent, community-driven tools | Proprietary apps hide what they do with data |

## Value Proposition

**For Users**:
- View 30+ file formats (PDF, DOCX, XLSX, PPTX, ODF, images, video, audio, code) in one app
- 100% offline — no internet permission required for document viewing
- Private storage — files hidden from file manager, inaccessible to other apps
- On-device OCR — extract text from images without cloud APIs
- Zero ads, zero tracking, zero telemetry

**For Business (FadSec Lab)**:
- Part of FadSec Lab suite (FadCrypt, FadCam) — builds brand trust
- Patreon revenue from supporters who value privacy-first software
- Open-source reputation drives community contributions

## Success Metrics

| Metric | Definition | Target | Current |
|--------|------------|--------|---------|
| Downloads | GitHub release downloads | Growing | Visible on README badge |
| Community | Discord members | Active engagement | discord.gg/kvAZvdkuuN |
| Languages | Supported locales | 11+ | ✅ 11 languages |
| Formats | Supported file types | 30+ | ✅ 30+ formats |

## Business Model

```
Revenue Model: Patreon support + community donations
Pricing: Free and open-source (GPL v3.0)
Market Position: Privacy-first alternative to cloud document viewers
Parent Project: FadSec Lab suite (fadsec-lab)
```

## Key Stakeholders

| Role | Name | Responsibility |
|------|------|----------------|
| Creator | anonfaded | Project vision, architecture, development |
| Community | FadSec Lab / Discord | Feature requests, testing, translations |
| Supporters | Patreon patrons | Financial support, feedback |

## Roadmap Context

**Current Focus**: LibreOfficeKit integration for desktop-class Office rendering, OCR expansion
**Next Milestone**: FadDrive — E2E encrypted cloud sync across devices
**Long-term Vision**: Desktop (Linux/macOS/Windows) + iOS apps, document editing, bookmarks/annotations

## Business Constraints

- **Offline-first** — No cloud dependency for core functionality; all processing on-device
- **No telemetry** — Cannot add analytics or crash reporting; must debug via user reports
- **arm64-only** — LibreOffice native code limits to 64-bit ARM Android devices
- **GPL v3.0** — All contributions must be open-source under same license
- **App size** — ~346MB release APK due to embedded LibreOffice; must justify size with value

## Onboarding Checklist

- [x] Understand the privacy-first mission and offline requirement
- [x] Identify target users: privacy-conscious, offline workers, professionals
- [x] Know the value proposition: 30+ formats, zero tracking, private storage
- [x] Understand success metrics: downloads, community, languages, formats
- [x] Know the roadmap: FadDrive, desktop apps, editing features
- [x] Understand constraints: offline-only, no telemetry, arm64-only, GPL v3

## Related Files

- `technical-domain.md` — How offline requirement drives architecture choices
- `business-tech-bridge.md` — Privacy needs → technical implementations
- `decisions-log.md` — Why pdfrx, LibreOfficeKit, Hive were chosen
