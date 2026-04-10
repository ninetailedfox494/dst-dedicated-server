# Modoverrides Template Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sync `docker/templates/modoverrides.lua.tmpl` to exactly match the current mod IDs in `env/mods.txt`.

**Architecture:** Update one template file only, preserving the current Lua structure and option payload. Validation is done by checking all expected IDs exist and removed IDs are absent.

**Tech Stack:** Lua template, Bash/rg checks

---

### Task 1: Replace template IDs with current mod list

**Files:**
- Modify: `docker/templates/modoverrides.lua.tmpl`

- [ ] **Step 1: Write the expected content (target state)**

```lua
return {
  ["workshop-2798599672"] = { enabled = true, configuration_options = {} },
  ["workshop-374550642"] = { enabled = true, configuration_options = {} },
  ["workshop-1207269058"] = { enabled = true, configuration_options = {} },
  ["workshop-2477889104"] = { enabled = true, configuration_options = {} },
  ["workshop-378160973"] = { enabled = true, configuration_options = {} },
  ["workshop-351325790"] = { enabled = true, configuration_options = {} },
  ["workshop-362175979"] = { enabled = true, configuration_options = {} },
  ["workshop-597417408"] = { enabled = true, configuration_options = {} },
  ["workshop-569043634"] = { enabled = true, configuration_options = {} },
  ["workshop-2189004162"] = { enabled = true, configuration_options = {} },
  ["workshop-1852257480"] = { enabled = true, configuration_options = {} },
}
```

- [ ] **Step 2: Apply the file update**

Replace the full content of `docker/templates/modoverrides.lua.tmpl` with the target-state block above.

- [ ] **Step 3: Validate required IDs exist**

Run:
```bash
rg 'workshop-(2798599672|374550642|1207269058|2477889104|378160973|351325790|362175979|597417408|569043634|2189004162|1852257480)' docker/templates/modoverrides.lua.tmpl -n
```
Expected: all 11 IDs found.

- [ ] **Step 4: Validate removed IDs are absent**

Run:
```bash
rg 'workshop-(2078243581|376333686|1608191708|345692228|347079953|1412085556)' docker/templates/modoverrides.lua.tmpl -n
```
Expected: no matches.

