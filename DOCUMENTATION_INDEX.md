# 📚 Documentation Index

Complete guide for Don't Starve Together Dedicated Server setup on macOS.

---

## 🚀 Start Here

### **New User? Pick Your Path:**

1. **I want the easiest setup** → Read `QUICKSTART.md` (5 min read)
2. **I'm not sure Docker or native** → Read `SETUP_COMPARISON.md` (10 min read)
3. **I want complete details** → Read `README.md` (20 min read)

---

## 📄 All Documentation Files

### **Decision & Planning**

| File | Purpose | Read Time |
|------|---------|-----------|
| **SETUP_COMPARISON.md** | Docker vs native macOS side-by-side comparison | 10 min |
| **README.md** | Complete overview, quick start, all paths | 20 min |

### **Setup Guides**

| File | Purpose | Read Time |
|------|---------|-----------|
| **QUICKSTART.md** | 5-minute setup guide for both paths | 5 min |
| **DOCKER_GUIDE.md** | Complete Docker setup, mods, config, ops | 15 min |
| **native-macos/README.md** | Complete native macOS setup & operations | 15 min |

### **Configuration Reference**

| File | Purpose | Read Time |
|------|---------|-----------|
| **CONFIG_GUIDE.md** | All configuration variables explained | 10 min |
| **TROUBLESHOOTING.md** | Common issues and solutions | 15 min |

---

## 🎯 Quick Navigation by Task

### **I want to use Docker:**
1. Verify: `docker --version && docker-compose --version`
2. Read: `DOCKER_GUIDE.md`
3. Follow: Quick Start section in DOCKER_GUIDE.md
4. If stuck: Check TROUBLESHOOTING.md

### **I want native macOS:**
1. Read: `native-macos/QUICKSTART.md`
2. Run: `bash native-macos/setup_dst_server.sh`
3. Check: `bash native-macos/scripts/logs.sh --follow`
4. If stuck: Check TROUBLESHOOTING.md

### **I need to configure mods:**
- Docker: See "How Mods & Config Load in Docker" in DOCKER_GUIDE.md
- macOS: See "Mods & Config" in CONFIG_GUIDE.md or native-macos/README.md

### **I need to manage servers:**
- Docker: See "Daily Operations" in DOCKER_GUIDE.md
- macOS: See "Helper Scripts" section in native-macos/README.md

### **Something is broken:**
- Read: TROUBLESHOOTING.md (organized by symptom)
- If not listed: Check logs with:
  - Docker: `docker-compose logs -f`
  - macOS: `bash native-macos/scripts/logs.sh --follow`

---

## 📋 File Descriptions

### **SETUP_COMPARISON.md** (334 lines)
**Quick decision matrix for Docker vs native macOS**
- Decision table comparing both approaches
- Setup flow diagrams for each path
- Mods & config loading flow (Docker vs native)
- Side-by-side common tasks
- When to use each path
- Resource usage comparison

### **README.md** (4.4 KB)
**Primary entry point with complete overview**
- What it does (master + caves shards, mods, management)
- Requirements (Klei account, token)
- Quick start (30 seconds)
- Full installation for both paths
- Helper scripts reference
- Directory structure
- Troubleshooting quick links

### **QUICKSTART.md** (1.1 KB)
**Fastest path to running server**
- 5-minute setup for both Docker and native
- Minimal steps, no explanations
- Links to detailed guides
- Good bookmark for quick reference

### **DOCKER_GUIDE.md** (454 lines, 9.6 KB)
**Complete Docker setup & operations guide**
- Which Docker version (20.10+, Docker Compose 2.0+)
- Quick start (5 steps)
- **How mods & config work in Docker** ← Key resource
- Configuration flow diagram
- Three ways to install mods
- Port configuration
- Daily operations (status, logs, restart, backup)
- Container architecture
- Troubleshooting
- Performance tips
- Docker Compose reference
- vs Native macOS comparison table

### **native-macos/README.md** (in directory)
**Complete native macOS setup & operations**
- What's included (setup phases, helper scripts)
- Quick start
- Full setup instructions
- Helper scripts (start, stop, status, logs, backup, etc.)
- Configuration management
- Mods & world generation
- Daily operations
- Performance tuning
- Troubleshooting

### **CONFIG_GUIDE.md** (3.0 KB)
**All configuration variables explained**
- Server identity settings
- Gameplay settings
- Network settings
- World generation
- Performance tuning
- Each variable explained with defaults

### **TROUBLESHOOTING.md** (4.0 KB)
**Issues organized by symptom**
- Port conflicts
- Permission issues
- Config problems
- Mod issues
- Server crashes
- Network issues
- Each with solution steps

---

## 🎓 Learning Paths

### **Path 1: Just Get It Working (10 minutes)**
1. `QUICKSTART.md` (5 min)
2. Pick Docker or native and follow steps
3. Server running ✅

### **Path 2: Understand Everything (45 minutes)**
1. `SETUP_COMPARISON.md` (10 min) - Understand options
2. `README.md` (20 min) - Full overview
3. `DOCKER_GUIDE.md` or `native-macos/README.md` (15 min) - Chosen path

### **Path 3: Deep Dive (90 minutes)**
1. `README.md` (20 min) - Overview
2. `SETUP_COMPARISON.md` (10 min) - Compare approaches
3. `DOCKER_GUIDE.md` (15 min) - Docker details
4. `native-macos/README.md` (15 min) - Native details
5. `CONFIG_GUIDE.md` (10 min) - Configuration
6. `TROUBLESHOOTING.md` (10 min) - Problem solving

### **Path 4: I'm Stuck (troubleshooting)**
1. `TROUBLESHOOTING.md` - Find your symptom
2. If not listed, check logs (see appropriate guide)
3. Check `CONFIG_GUIDE.md` for variable issues

---

## 🔍 Finding Specific Information

| Need | Read |
|------|------|
| **Choose Docker or native** | SETUP_COMPARISON.md |
| **Setup in 5 minutes** | QUICKSTART.md |
| **Understand Docker setup** | DOCKER_GUIDE.md |
| **Understand native macOS** | native-macos/README.md |
| **Mods configuration** | CONFIG_GUIDE.md or DOCKER_GUIDE.md |
| **Server operations** | DOCKER_GUIDE.md or native-macos/README.md |
| **Variable reference** | CONFIG_GUIDE.md |
| **Something broken** | TROUBLESHOOTING.md |
| **Network/ports** | DOCKER_GUIDE.md "Port Configuration" |
| **Backups & restore** | native-macos/README.md or DOCKER_GUIDE.md |
| **Admin/whitelist/blocklist** | CONFIG_GUIDE.md or native-macos/README.md |

---

## 📊 File Statistics

```
Total documentation:     ~30 KB
Number of files:        6 (+ additional guides in subdirs)
Total lines:           ~1,500+

Docker-specific:       ~454 lines (9.6 KB)
Native macOS:          ~400+ lines (in subdirectory)
Configuration:         ~100 lines
Comparison:            ~334 lines
Troubleshooting:       ~150 lines
Quick start:           ~40 lines
```

---

## ✅ All Topics Covered

- ✅ Which Docker version to use
- ✅ How mods load in Docker
- ✅ How config loads in Docker
- ✅ Setting environment variables
- ✅ Mod installation (3 methods)
- ✅ Server operations (start/stop/restart/logs)
- ✅ Backup & restore
- ✅ Admin/whitelist management
- ✅ Port configuration
- ✅ Multi-shard setup (Master + Caves)
- ✅ Performance tuning
- ✅ Docker vs native comparison
- ✅ Troubleshooting by symptom
- ✅ Network diagnostics
- ✅ Log access & interpretation

---

## 🆘 Still Need Help?

Check the appropriate guide:

**Docker issues:**
- DOCKER_GUIDE.md → Troubleshooting section
- TROUBLESHOOTING.md → Find your symptom

**Native macOS issues:**
- native-macos/README.md → Troubleshooting section
- TROUBLESHOOTING.md → Find your symptom

**Configuration questions:**
- CONFIG_GUIDE.md → Variable reference table

**General confusion:**
- SETUP_COMPARISON.md → Understand options
- README.md → Complete overview

---

## 🚀 Ready to Start?

1. **New user?** → Start with `QUICKSTART.md`
2. **Unsure of path?** → Read `SETUP_COMPARISON.md` (5 min)
3. **Ready to go?** → Pick Docker or native and follow the guide
4. **Stuck?** → Check `TROUBLESHOOTING.md`

**Let's go! 🎮**
