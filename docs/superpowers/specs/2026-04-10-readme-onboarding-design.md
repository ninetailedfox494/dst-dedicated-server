# README Onboarding Design (Bilingual)

## Problem

Current README is functional but not optimized for first-time users. A newcomer needs a cleaner flow with copy/paste commands and less cognitive load.

## Goal

Rewrite README to be beginner-friendly for running DST Docker server, with bilingual guidance (English + Vietnamese) and clear operational commands.

## Scope

In scope:
- Rewrite README structure and wording
- Keep all commands aligned with current repository scripts/services
- Add concise env variable reference

Out of scope:
- Runtime code changes
- Compose/service behavior changes

## Proposed Structure

1. Project summary (what it runs)
2. Prerequisites
3. Quickstart (5 steps, copy/paste-ready)
4. Daily operations
5. Mod update (player request flow)
6. Environment variables table
7. Troubleshooting
8. Security notes

## Writing Style

- English line first, Vietnamese line second
- Short instructions and direct command blocks
- Explicit expected outcomes for key steps
- No long paragraphs

## Acceptance Criteria

- New user can run server from zero by following quickstart only
- New user can perform mod update using one script command
- README keeps secrets out of committed files and points to `env/.env`

