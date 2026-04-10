# Modoverrides Template Sync Design

## Goal

Update `docker/templates/modoverrides.lua.tmpl` to match the current mod IDs in `env/mods.txt`.

## Scope

In scope:
- Replace template entries with exactly the selected 11 workshop IDs.
- Remove old IDs that are no longer in `env/mods.txt`.
- Keep output format unchanged (`enabled = true`, empty `configuration_options`).

Out of scope:
- Changing update scripts
- Changing compose/runtime behavior
- Dynamic generation logic

## Chosen Approach

Use a fixed/manual update of `modoverrides.lua.tmpl` using the selected IDs.

## Target Mod IDs

1. `2798599672`
2. `374550642`
3. `1207269058`
4. `2477889104`
5. `378160973`
6. `351325790`
7. `362175979`
8. `597417408`
9. `569043634`
10. `2189004162`
11. `1852257480`

## Validation

- Confirm all 11 IDs exist in `docker/templates/modoverrides.lua.tmpl`.
- Confirm removed IDs are not present:
  - `2078243581`
  - `376333686`
  - `1608191708`
  - `345692228`
  - `347079953`
  - `1412085556`
