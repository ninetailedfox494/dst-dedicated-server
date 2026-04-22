# Documentation Consolidation Design

**Date:** 2026-04-22  
**Status:** Approved

## Problem

The project has 29 markdown files with significant duplication:
- Docker setup instructions appear in 4+ places
- Comparison tables duplicated in 4 files
- Configuration reference scattered across 3+ files
- Multiple "start here" entry points confuse users
- native-macos has redundant INDEX.md + README.md

## Solution

Consolidate to 5 core documentation files with clear hierarchy:

```
README.md                    # Overview + comparison + path selector
├── docker/README.md         # Complete self-contained Docker guide
├── native-macos/README.md   # Complete self-contained macOS guide  
└── TROUBLESHOOTING.md       # Unified troubleshooting (both platforms)
```

## Content Mapping

### README.md (Root)
**Sources:** Current README.md, SETUP_COMPARISON.md, DOCUMENTATION_INDEX.md
**Contains:**
- Project title and one-line description
- Comparison table (Docker vs Native)
- Prerequisites (both platforms)
- Quick path selector with links
- Project structure overview
- Support links

### docker/README.md
**Sources:** DOCKER_GUIDE.md, DOCKER_RUN_GUIDE.md, CONFIG_GUIDE.md (Docker parts), docker/README.md
**Contains:**
- Quick start (5 steps)
- Prerequisites (Docker version)
- Complete configuration reference (env variables)
- Mods installation (3 methods)
- Daily operations (start/stop/logs/backup)
- Container architecture
- Port configuration

### native-macos/README.md  
**Sources:** Current native-macos/README.md, CONFIG_GUIDE.md (macOS parts), QUICKSTART.md (macOS parts)
**Contains:**
- Quick start
- Prerequisites (macOS version, Homebrew)
- Setup phases explanation
- Complete configuration reference
- Helper scripts reference
- Mods installation
- Backup/restore
- Performance tips

### TROUBLESHOOTING.md
**Sources:** Current TROUBLESHOOTING.md, troubleshooting sections from other docs
**Contains:**
- Organized by symptom
- Platform-specific solutions clearly labeled
- Common issues for both Docker and macOS

## Files to Delete

| File | Reason |
|------|--------|
| `QUICKSTART.md` | Content merged into path READMEs |
| `DOCUMENTATION_INDEX.md` | Redundant with simplified structure |
| `DOCKER_GUIDE.md` | Merged into docker/README.md |
| `DOCKER_RUN_GUIDE.md` | Merged into docker/README.md |
| `SETUP_COMPARISON.md` | Comparison table moved to root README |
| `CONFIG_GUIDE.md` | Config embedded in each path README |
| `native-macos/INDEX.md` | Redundant with native-macos/README.md |
| `native-macos/BUG_TRACKING.md` | Historical, no longer needed |
| `native-macos/CHANGELOG.md` | Historical, no longer needed |

## Files to Keep As-Is

- `docs/superpowers/` - Internal planning docs
- `docker/setup/README.md` - Tool-specific documentation

## Design Principles

1. **Single entry point per path** - One README per directory
2. **Self-contained guides** - No jumping between files for basic setup
3. **Clear hierarchy** - Root README directs to platform-specific guides
4. **Unified troubleshooting** - One place for all problem solving
5. **No duplication** - Each piece of information lives in exactly one place

## Success Criteria

- [ ] User can complete setup by reading only 2 files (root README → platform README)
- [ ] No duplicate content between files
- [ ] All original information preserved (just reorganized)
- [ ] Clear "you are here" for any user landing on any doc
