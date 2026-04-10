# README Runbook Optimization Design

## Goal

Update README to keep current project scope but make onboarding faster for new users with step-by-step command execution.

## Inputs Considered

- Current repository README and command flow
- Reference repository structure from `mphung97/dst-dedicated-server` (quick-start emphasis and concise operational flow)
- User preference: copy-paste commands only, minimal teaching text

## Scope

In scope:
- Reorganize README into a quick command runbook
- Keep existing commands and scripts currently supported by this repository
- Improve section ordering and wording for first-time users

Out of scope:
- Code/runtime behavior changes
- New deployment architecture
- Nonexistent command additions

## Proposed README Structure

1. **Quick Run (First Time)**  
   Copy-paste command sequence from zero to running server.
2. **Daily Commands**  
   Start/restart/status/logs/stop/rebuild in one compact block.
3. **Update Mods**  
   Explicit flow using `env/mods.txt` and `scripts/update_mods.sh`.
4. **ENV Reference**  
   Minimal table of core variables only.
5. **Troubleshooting**  
   Short actionable fixes.
6. **Security**  
   Secret handling reminders.

## Content Rules

- Command blocks first, explanation second.
- Very short bilingual labels only where needed.
- No decorative badges, no long architecture prose.
- Every command shown must already work with current repo files.

## Success Criteria

- A new user can run first deployment by following one section only.
- A new user can update mods with one script command.
- Existing smoke tests that validate README command presence still pass.

