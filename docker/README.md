# DST Dedicated Server — Docker Setup

Complete Docker setup for running Don't Starve Together Dedicated Server with containerization.

## Quick Start

```bash
# 1. Configure environment
cp env/.env.example .env
vi .env

# 2. Build and run
docker-compose up -d

# 3. Check logs
docker-compose logs -f

# 4. Control server
docker-compose stop
docker-compose start
docker-compose restart
```

## Directory Structure

```
docker/
├── docker-compose.yml       # Docker Compose configuration
├── Dockerfile              # Container image definition
├── entrypoint.sh           # Container entrypoint script
├── templates/              # Configuration templates
│   └── ...
└── setup/                  # Setup utilities
```

## Docker Compose Services

- **dst-master**: Master server (SSA)
- **dst-caves**: Caves server (non-master)
- **volumes**: Persistent server data

## Configuration

Edit `docker-compose.yml` and `.env` for:
- Server ports
- Player limits
- Game mode (endless, survival, wilderness)
- Admin users
- Mods list

## Volume Mounts

Data persistence across container restarts:
```yaml
volumes:
  - ./data:/dst/data           # Server data
  - ./logs:/dst/logs           # Server logs
  - ./backups:/dst/backups     # World backups
```

## Networking

- **Master**: UDP port 10999
- **Caves**: UDP port 10998
- Internal Docker network for inter-server communication

## Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f dst-master
docker-compose logs -f dst-caves
```

## Backup

```bash
# Backup volume
docker run --rm -v data:/data -v $(pwd)/backups:/backup \
  alpine tar -czf /backup/dst_backup_$(date +%s).tar.gz -C / data
```

## Troubleshooting

- **Port conflict**: Change ports in `docker-compose.yml`
- **Permission denied**: Check volume permissions
- **Out of memory**: Increase Docker memory allocation
- **Mod download fails**: Check internet connectivity

See `../TROUBLESHOOTING.md` for complete guide.

## Advantages over Native Setup

- **Portability**: Same setup works on Linux, macOS, Windows
- **Isolation**: Separate from system dependencies
- **Easy updates**: Rebuild image with latest DST version
- **Multiple instances**: Run multiple servers on same host
- **Rollback**: Simple version management

## Disadvantages

- Slightly higher resource overhead
- Requires Docker installation and knowledge
- Network overhead for inter-container communication

## Production Considerations

- Use **network volumes** for multi-server setups
- Enable **resource limits** in docker-compose.yml
- Implement **automatic backups** with cron/systemd
- Monitor **disk space** for long-running servers
- Set up **health checks** in Dockerfile

## Support

See `../TROUBLESHOOTING.md` and `../CONFIG_GUIDE.md` for detailed help.
