# Repository Guidelines

## Project Structure & Module Organization

This is a Godot 4.6 project. `project.godot` defines the main scene, autoloads, inputs, physics layers, viewport, and renderer. Core areas are organized by gameplay domain:

- `actors/`: player, enemies, and companion scenes/scripts (`player.tscn` + `player.gd`).
- `world/`: overworld maps, transitions, doors, dungeon scripts, and battle transition logic.
- `battleSystem/`: self-contained turn-based combat. Use `core/` for flow, `ui/` for combat UI, `data/` for `.tres` instances, `resources/` for Resource classes, and `tests/` for isolated scenes.
- `ui/dialog/`: dialogue and language input UI.
- `assets/`: sprites, fonts, UI art, and test-only assets.

## Build, Test, and Development Commands

- Open in editor: import `project.godot` with Godot 4.6, then press `F5` to run the main scene.
- Run battle test manually: open `battleSystem/tests/test_battle_scene.tscn` and press `F6`.
- CLI smoke run, when Godot is on `PATH`: `godot --path .`.
- Static project parse, when available: `godot --headless --path . --quit`.

There is no separate package manager, build script, or automated test runner.

## Coding Style & Naming Conventions

Use GDScript with tabs, typed variables/signatures where practical, and Godot lifecycle names such as `_ready()` and `_physics_process()`. Constants use `UPPER_SNAKE_CASE`; functions and variables use `snake_case`. Existing exported resource fields include camelCase names (`maxHealth`, `targetType`); preserve current APIs unless intentionally migrating references.

Keep scenes and scripts paired by feature. Prefer descriptive node groups already used by the project, such as `player`, `enemy`, `turnBasedAgents`, and `commandMenu`. Do not manually edit Godot UID/import metadata unless the change is required and verified.

## Testing Guidelines

Use scene-level manual testing. For combat changes, keep `battleSystem/tests/test_battle_scene.tscn` working. For overworld changes, run the main scene and validate movement, interaction (`interact`), battle entry/return, and console errors. If Godot is unavailable, perform static review and state that editor validation is still required.

## Commit & Pull Request Guidelines

Recent history uses Conventional Commit-style prefixes, for example `feat(battle): ...`, `feat(enemy): ...`, and `docs: ...`. Prefer `feat`, `fix`, `refactor`, `chore`, and `docs` with an optional scope.

PRs should follow `pull_request_template.md`: include a direct description, change type, what changed, how it works, affected areas, test steps, evidence when relevant, and checklist status. Add screenshots or short recordings for visible UI/gameplay changes.

## Agent-Specific Instructions

Before editing `.tscn` files, inspect the diff carefully and preserve `ext_resource`, `sub_resource`, signals, groups, and node names. Keep changes scoped to the requested gameplay flow and avoid mixing unrelated gameplay, UI, persistence, or asset work.
