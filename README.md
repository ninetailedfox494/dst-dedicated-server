# 🎮 Don't Starve Together Dedicated Server

Run a DST dedicated server on **macOS (native)** or **any platform (Docker)**.

## Which Setup?

| Question | Docker | macOS Native |
|----------|--------|--------------|
| Want cross-platform? | ✅ Yes | ❌ macOS only |
| Have Docker installed? | ✅ Use it | — |
| Want smallest footprint? | ~15% overhead | ✅ Zero overhead |
| Setup time | ~5 min | ~10 min |
| Multiple servers? | ✅ Easy | Manual |

**Not sure?** Start with Docker if you have it installed; otherwise use macOS native.

## Quick Start

### Docker (Recommended for Portability)

```bash
cd docker
cp env/.env.template env/.env
# Edit env/.env with your cluster token
docker-compose up -d
```

👉 **[Complete Docker Guide](docker/README.md)**

### macOS Native (Recommended for macOS)

```bash
cd native-macos
cp env/.env.template env/.env
# Edit env/.env with your cluster token
bash setup_dst_server.sh
bash scripts/start.sh
```

👉 **[Complete macOS Guide](native-macos/README.md)**

## Prerequisites

- **Klei cluster token** from https://accounts.klei.com/account/game/server
- **Docker** (for Docker setup): 20.10+, Docker Compose 2.0+
- **macOS** (for native setup): 10.13+, Homebrew

## Features

Both setups include:
- ✅ Master + Caves shards (dual-world gameplay)
- ✅ Config-driven via environment files
- ✅ Auto-download Steam Workshop mods
- ✅ Backup/restore worlds
- ✅ Status monitoring & logs
- ✅ Helper scripts

## Project Structure

```
docker-dst-server/
├── docker/                 # Docker setup
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── README.md           # Docker guide
├── native-macos/           # macOS native setup
│   ├── setup_dst_server.sh
│   ├── scripts/
│   └── README.md           # macOS guide
├── README.md               # This file
└── TROUBLESHOOTING.md      # Problem solving
```

## Troubleshooting

See **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** for solutions to common issues.

## Support

- **Klei Forum**: https://forums.kleientertainment.com/
- **DST Wiki**: https://dontstarve.fandom.com

---

**Enjoy your Don't Starve Together server! 🎮**
