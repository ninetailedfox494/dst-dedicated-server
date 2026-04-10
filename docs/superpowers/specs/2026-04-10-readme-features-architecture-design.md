# README Features & Architecture Expansion Design

## Goal

Add richer **Features** and **Architecture** sections to README while keeping the current quick-run command flow intact.

## Scope

In scope:
- Add a detailed, project-accurate Features section
- Add a detailed Architecture section with structure and runtime flow
- Preserve existing runbook command sections and behavior

Out of scope:
- Any runtime code or Docker behavior changes
- New services, ports, or scripts

## Chosen Approach

Use a **hybrid format**:
1. Feature table with practical details
2. Architecture tree for file/service orientation
3. Component/data flow for operational clarity

Why:
- New users quickly understand capabilities
- Intermediate users understand where to change config/mods
- Keeps README actionable, not just marketing text

## Features Section Design

Include a table with these capabilities:
- Dual-shard server (`Master` + `Caves`)
- Docker Compose deployment on one VPS
- Environment-based cluster config
- On-demand mod refresh workflow
- Persistent storage for cluster/mod data
- Health checks and service restart policy
- Security baseline for secrets handling

Each row will be concrete and mapped to real files/commands in this repo.

## Architecture Section Design

Add three subsections:

1. **Project Structure (tree)**
- Show key files only: `docker-compose.yml`, `Dockerfile`, `docker/entrypoint.sh`, `scripts/`, `env/`, `data/`.

2. **Runtime Services**
- `dst-master`: main shard
- `dst-caves`: caves shard
- `mod-updater`: one-shot utility service

3. **Flow**
- First run: env -> compose -> entrypoint -> shard processes
- Mod update: `scripts/update_mods.sh` -> `mod-updater` -> config rewrite -> shard restart

## Placement

Insert the new **Features** and **Architecture** sections:
- After `Requirements`
- Before `Quick Run (First Time)`

This keeps command-first onboarding while adding context up front.

## Acceptance Criteria

- README includes a new detailed Features section
- README includes a new detailed Architecture section
- Existing command runbook sections remain intact and usable
- Existing README smoke checks still pass

