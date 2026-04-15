# 🎮 Don't Starve Together Dedicated Server

Complete setup for running DST dedicated server on **macOS (native)** or **any platform (Docker)**.

Choose your setup:
- 📁 **[native-macos/](native-macos/)** — macOS native setup (recommended for macOS users)
- 🐳 **[docker/](docker/)** — Docker setup (works on Linux, macOS, Windows)

---

## Setup Comparison

| Feature | Native macOS | Docker |
|---------|-------------|--------|
| **Platform** | macOS 10.13+ | Linux/macOS/Windows |
| **Portability** | ❌ macOS only | ✅ Any platform |
| **Resource overhead** | Low | Slight overhead |
| **Setup time** | ~10 minutes | ~5 minutes |
| **Multiple servers** | Manual setup | Native support |
| **Rollback** | Git/manual | Image versioning |
| **Learning curve** | Low | Moderate (Docker knowledge) |

---

## Quick Start

### Option 1: macOS Native (Recommended for macOS)

```bash
cd native-macos
cp env/.env.template env/.env
# Edit env/.env with your settings
bash setup_dst_server.sh
bash scripts/start.sh
```

👉 **[Full guide](native-macos/README.md)**

### Option 2: Docker (Best for Portability)

```bash
cd docker
# Edit docker-compose.yml and .env
docker-compose up -d
docker-compose logs -f
```

👉 **[Full guide](docker/README.md)**

---

## Features

Both setups include:
- ✅ Master + Caves shards (dual-world gameplay)
- ✅ Config-driven via templates
- ✅ Auto-download Workshop mods
- ✅ Backup/restore worlds
- ✅ Status monitoring & debugging
- ✅ Helper scripts for daily operations
- ✅ Full documentation

---

## Project Structure

```
docker-dst-server/
├── native-macos/              # macOS native setup
│   ├── setup_dst_server.sh    # Main setup script
│   ├── scripts/               # Helper scripts
│   ├── env/                   # Configuration templates
│   ├── data/                  # Server data & worlds
│   ├── steamcmd/              # SteamCMD binary
│   ├── dst_server/            # DST binary
│   └── README.md              # Native macOS guide
│
├── docker/                    # Docker setup
│   ├── docker-compose.yml     # Container orchestration
│   ├── Dockerfile             # Container image
│   ├── entrypoint.sh          # Container entry point
│   ├── templates/             # Config templates
│   ├── setup/                 # Setup utilities
│   └── README.md              # Docker guide
│
├── README.md                  # This file (project overview)
├── QUICKSTART.md              # Quick reference guide
├── CONFIG_GUIDE.md            # Detailed configuration
├── TROUBLESHOOTING.md         # Issue solutions
├── docs/                      # Additional docs
└── tests/                     # Test suite
```

---

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** — 5-minute setup guide
- **[CONFIG_GUIDE.md](CONFIG_GUIDE.md)** — Detailed configuration reference
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** — Solutions to common issues
- **[native-macos/README.md](native-macos/README.md)** — macOS native setup guide
- **[docker/README.md](docker/README.md)** — Docker setup guide

---

## System Requirements

### macOS Native
- macOS 10.13+
- Intel or Apple Silicon (M1/M2 via Rosetta)
- 2GB RAM (4GB+ recommended)
- 20GB disk space
- Homebrew installed

### Docker
- Docker 20.10+
- Docker Compose 1.29+
- 2GB RAM available to Docker
- 20GB disk space

---

## Getting Started

1. **Clone this repository:**
   ```bash
   git clone <repo-url>
   cd docker-dst-server
   ```

2. **Choose your setup:**
   - **macOS users:** Follow [native-macos/README.md](native-macos/README.md)
   - **Cross-platform:** Follow [docker/README.md](docker/README.md)

3. **Get your Klei token:**
   Visit: https://accounts.klei.com/account/game/server

4. **Configure and start:**
   Follow the quick start in your chosen setup guide above.

---

## Support

- **Klei Forum**: https://forums.kleientertainment.com/
- **DST Wiki**: https://dontstarve.fandom.com
- See **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** for common issues

---

## Version History

- **v2.0** (2024-04-15): Separated Docker and native macOS setups
  - Improved project organization
  - Separate guides for each platform
  - Cleaner root directory
  
- **v1.0** (2024-04-15): Initial release
  - Setup script with 10 phases
  - 11 helper scripts
  - Full documentation

---

**Enjoy your Don't Starve Together server! 🎮**
