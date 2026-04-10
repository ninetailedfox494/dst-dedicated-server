# Init Env Script Design

## Goal

Make first-time setup easier so users only run one command to create `env/.env` and set `DST_CLUSTER_TOKEN`.

## Scope

In scope:
- Add `scripts/init_env.sh`
- Update README quick-start steps to use the new script
- Keep `.env.example` public-template guidance

Out of scope:
- Runtime server behavior changes
- Token validation against external APIs

## Chosen Approach

Use an interactive script:
1. Create `env/.env` from `env/.env.example` when missing
2. Ask user to input `DST_CLUSTER_TOKEN`
3. Replace token value in `env/.env`
4. Fail on empty token
5. Print next run command

## Script Behavior

- Default files:
  - source: `env/.env.example`
  - target: `env/.env`
- If target exists, keep it and update only `DST_CLUSTER_TOKEN`
- Prompt via terminal input (`read -r`)
- Update token safely in-place
- Output success message and next step: `docker compose up -d --build`

## README Changes

- Replace manual `cp` + `vi` flow with:
  - `bash scripts/init_env.sh`
  - `docker compose up -d --build`
- Keep bilingual reminders:
  - `.env.example` is public template
  - real token belongs in private `env/.env`

## Acceptance Criteria

- Running `bash scripts/init_env.sh` creates/updates `env/.env` with user token
- Empty token input fails with clear message
- README reflects simplified setup flow
