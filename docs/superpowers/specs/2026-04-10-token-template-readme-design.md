# Token Template & README Reminder Design

## Goal

Clarify that `.env.example` is public template data, and users must set a real private `DST_CLUSTER_TOKEN` before running the server.

## Scope

In scope:
- Update comments in `env/.env.example`
- Add bilingual reminder in README Quick Run and Security sections
- Explain that `DST_CLUSTER_TOKEN` is used to generate `cluster_token.txt` at startup

Out of scope:
- Runtime behavior changes
- Startup validation changes
- Docker/script logic changes

## Chosen Approach

Use minimal documentation updates in existing sections:
1. `.env.example` comments
2. Quick Run step 2 note
3. Security reminders

## Design Sections

### 1) `env/.env.example` clarification
- Add comments that this file is public and safe as template only
- Keep placeholder `DST_CLUSTER_TOKEN=REPLACE_WITH_REAL_TOKEN`
- State that real token belongs in `env/.env` and should not be committed

### 2) README Quick Run reminder
- Near token setup step, add bilingual reminder:
  - `DST_CLUSTER_TOKEN` is used to write `cluster_token.txt`
  - Users must replace placeholder before first run

### 3) README Security reminder
- Add bilingual note:
  - `.env.example` is public template only
  - `env/.env` must contain private real token
  - Rotate token if exposed

## Acceptance Criteria

- New user can clearly understand which file is public vs private
- README explicitly warns to replace placeholder token before running
- Documentation explains token-to-`cluster_token.txt` generation path
