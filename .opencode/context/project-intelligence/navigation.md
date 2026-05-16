<!-- Context: project-intelligence/nav | Priority: high | Version: 2.0 | Updated: 2026-05-16 -->

# Project Intelligence — Fadocx

> Start here for quick project understanding. All files populated with actual Fadocx context.

## Structure

```
.opencode/context/project-intelligence/
├── navigation.md              # This file - quick overview
├── business-domain.md         # Privacy-first document viewer mission (v2.0)
├── technical-domain.md        # Flutter, Riverpod, Hive, LOKit stack (v2.0)
├── business-tech-bridge.md    # Privacy needs → technical implementations (v2.0)
├── decisions-log.md           # 7 major decisions + 3 deprecated (v2.0)
└── living-notes.md            # 5 tech debt items, 4 open questions (v2.0)
```

## Quick Routes

| What You Need | File | Description |
|---------------|------|-------------|
| Understand the "why" | `business-domain.md` | Privacy-first mission, target users, roadmap |
| Understand the "how" | `technical-domain.md` | Flutter stack, Riverpod, Hive, format routing |
| See the connection | `business-tech-bridge.md` | Offline requirement → architecture decisions |
| Know the context | `decisions-log.md` | Why pdfrx, LOKit, Hive, arm64-only, no telemetry |
| Current state | `living-notes.md` | Tech debt, open questions, known issues, gotchas |
| All of the above | Read all files in order | Full project intelligence |

## Usage

**New Team Member / Agent**:
1. Start with `navigation.md` (this file)
2. Read all files in order for complete understanding
3. Follow onboarding checklist in each file

**Quick Reference**:
- Business focus → `business-domain.md`
- Technical focus → `technical-domain.md`
- Decision context → `decisions-log.md`
- Current issues → `living-notes.md`

## Integration

This folder is referenced from:
- `.opencode/context/core/standards/project-intelligence.md` (standards and patterns)
- `.opencode/context/core/system/context-guide.md` (context loading)

See `.opencode/context/core/context-system.md` for the broader context architecture.

## Maintenance

Keep this folder current:
- Update when business direction changes
- Document decisions as they're made
- Review `living-notes.md` regularly
- Archive resolved items from decisions-log.md

**Management Guide**: See `.opencode/context/core/standards/project-intelligence-management.md` for complete lifecycle management including:
- How to update, add, and remove files
- How to create new subfolders
- Version tracking and frontmatter standards
- Quality checklists and anti-patterns
- Governance and ownership

See `.opencode/context/core/standards/project-intelligence.md` for the standard itself.
