#!/usr/bin/env bash
# Initialize Docker environment for DST Dedicated Server
# This script sets up the necessary directory structure and templates

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

echo "🐳 Initializing Docker DST Server Environment"
echo "================================================"

# Create directories
echo "📁 Creating directories..."
mkdir -p env
mkdir -p data/{cluster,master,caves,mods}
mkdir -p backups
mkdir -p logs

# Check if .env exists
if [[ -f "env/.env" ]]; then
  echo "⚠️  env/.env already exists (skipping creation)"
else
  echo "📝 Creating env/.env..."
  cat > env/.env << 'EOF'
# ========== REQUIRED ==========
# Get token from https://accounts.klei.com/
DST_CLUSTER_TOKEN=pds-YOUR_TOKEN_HERE

# ========== SERVER IDENTITY ==========
# Internal name (used for save directory)
DST_CLUSTER_NAME=MyDSTServer

# Name shown in game browser
DST_CLUSTER_DISPLAY_NAME=My DST Server

# Description shown in game browser
DST_CLUSTER_DESCRIPTION=A Don't Starve Together Server

# Password to join (leave empty for public server)
DST_CLUSTER_PASSWORD=

# ========== GAMEPLAY SETTINGS ==========
# Game mode: endless, survival, or wilderness
DST_GAME_MODE=endless

# Maximum number of players
DST_MAX_PLAYERS=6

# World size: small, medium, or large
DST_WORLD_SIZE=small

# Server tick rate (default: 15)
DST_TICK_RATE=15

# ========== OPTIONAL FEATURES ==========
# Pause server when no players
DST_PAUSE_WHEN_EMPTY=true

# Enable PvP (player vs player)
DST_PVP=false

# Enable vote to skip
DST_VOTE_ENABLED=true
EOF
  echo "   ✅ Created env/.env (edit with your settings)"
fi

# Create mods.txt if it doesn't exist
if [[ -f "env/mods.txt" ]]; then
  echo "⚠️  env/mods.txt already exists (skipping creation)"
else
  echo "📝 Creating env/mods.txt..."
  cat > env/mods.txt << 'EOF'
# Popular DST Mods (one mod ID per line)
# Get mod IDs from: https://steamcommunity.com/app/346110/workshop/

# Display & Quality of Life
2798599672    # Display Attack Range
374550642     # Increased Stack Size
1207269058    # Simple Health Bar

# Gameplay Enhancements
2477889104    # Global Positions
378160973     # Geometric Placement
351325790     # Mineable Trees & Rocks

# Crafting & Tools
362175979     # Emerald Tools
597417408     # All Biomes
569043634     # Faster Crafting

# Quality of Life (continued)
2189004162    # Stone Walls
1852257480    # Breezie Sleeper
EOF
  echo "   ✅ Created env/mods.txt (add your mod IDs)"
fi

# Create admin/whitelist/blocklist files
for file in admins.txt whitelist.txt blocklist.txt; do
  if [[ ! -f "env/$file" ]]; then
    echo "📝 Creating env/$file..."
    touch "env/$file"
    echo "   ✅ Created env/$file"
  fi
done

echo ""
echo "✅ Docker environment initialized!"
echo ""
echo "Next steps:"
echo "1️⃣  Edit env/.env:"
echo "    nano env/.env"
echo ""
echo "2️⃣  Add your cluster token (from https://accounts.klei.com/)"
echo "    DST_CLUSTER_TOKEN=pds-XXXXX..."
echo ""
echo "3️⃣  Optional: Edit env/mods.txt to add mods"
echo ""
echo "4️⃣  Start Docker:"
echo "    docker-compose up -d"
echo ""
echo "5️⃣  Check logs:"
echo "    docker-compose logs -f"
echo ""
echo "📖 For detailed instructions, see: ../DOCKER_RUN_GUIDE.md"
