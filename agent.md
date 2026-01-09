# Fox TD Agent Context

This document summarizes the current project state and code layout so a new agent can quickly understand the whole codebase and how the game fits together.

## Project intent
- Game: tower defense with gacha mechanics.
- Goal: fast, fun, and addictive from the start.
- Engine: Godot 4.5 (Forward Plus), low-res pixel art vibe.
- Resolution: 240x135 with integer scaling.

## Entry point and scenes
- Main scene: `Main_Scene.tscn` with `main_scene.gd` (empty script currently).
- Core scene nodes:
  - `GameArea` (Control) holds the game, GUI, path manager, and background.
  - `PathManager` (Path2D) ties into path generation.
  - `GUI` instance from `Battlefield/GUI/GUI.tscn`.
  - `Timeline` instance from `Battlefield/timeline/timeline.tscn`.
- Menus: `Menus/Menu.tscn` with tabbed sections for stats, challenges, difficulty, gacha, win screen, etc.

## Autoload singletons (global systems)
Defined in `project.godot`:
- `Dev`: `dev.gd` (placeholder).
- `ItemDB`: `item_db.gd` (placeholder data layer).
- `WaveSpawner`: `wave_spawner.gd` (enemy waves, path generation, power scaling).
- `InventoryManager`: `inventory_manager.gd` (tower definitions, drag/drop inventory, costs).
- `GridController`: `grid_controller.gd` (grid placement, wall placement, drag towers).
- `StatsManager`: `stats_manager.gd` (health, production, upgrades, money).
- `Utilities`: `utilities.gd` (utility helpers, floating text).
- `AStarManager`: `a_star_manager.gd` (pathfinding and blocked tiles).
- `WaveShower`: `wave_shower.gd` (upcoming wave preview UI).
- `TowerManager`: `tower_manager.gd` (gacha inventory and squad lists).
- `TooltipManager`: `tooltip_manager.gd` (hover tooltips).
- `UpgradeManager`: `upgrade_manager.gd` (upgrade UI and pausing).
- `SaveManager`: `save_manager.gd` (encrypted saves, autosave, web storage).
- `TimelineManager`: `timeline_manager.gd` (wave-by-wave snapshots and rewind).
- `DifficultyManager`: `difficulty_manager.gd` (difficulty multipliers).

## Gameplay loop (current behavior)
1. Player starts with starter towers in inventory (`InventoryManager.give_starter_towers`).
2. Drag towers from inventory onto the grid.
3. Start waves; enemies spawn along a generated path (`WaveSpawner`).
4. Kill enemies to gain money and meat (health resource).
5. Spend meat to place towers, walls, and upgrades.
6. Use timeline saves to replay waves or reset the map.

## Design direction (new requirements)
- Gacha buttons: multiple pull buttons unlock over time; each has better odds.
- Legacy pulls: earlier buttons remain usable after newer ones unlock.
- Duplicates: allowed.
- Pity: every 20 rolls; guarantees the highest rarity available for that button.
- Pity reset: resets early if the top rarity is pulled before 20.
- Tutorial: 6 waves long with 2 starter towers in inventory.
- Post-tutorial: prompt player to return to camp and teach gacha pulls, moving towers to squad, and any available tabs.
- Difficulty scaling: grows with player power and how much power is actually placed each round.

## Core systems
### Difficulty traits
- Centralized in `difficulty_manager.gd`.
- Enemy spawn scaling uses trait-driven multipliers for speed/health.
- Combat hooks: dodge, armor (damage reduction), regeneration, revive-on-death, and splitting on death.
- Economy hooks: meat drain on kills, production jam on passive meat, and food shortage on starting meat.

### Towers and inventory
- Tower definitions live in `inventory_manager.gd` under `items`.
  - Towers have `prefab`, `bullet`, `rarity`, `paths`, and per-rank stats.
  - Examples: Fox, Bunny Hole, Elephant, Hawk, Duck, Snail, Mouse, Porcupine.
- Inventory drag/drop is custom drawn and uses GridController for placement.
- Costs:
  - Placement cost scales by rank and rarity.
  - Upgrade cost scales by rank and current upgrades.
- Power evaluation:
  - `get_total_field_dps` and `get_player_power_score` influence wave scaling.

### Grid placement and pathing
- `grid_controller.gd` manages a fixed 22x15 grid of 8px cells.
- Buildable tiles come from scene nodes in group `grid_buildable`.
- Walls can be placed if they do not block the path (checked via `AStarManager`).
- Towers are draggable and can be repositioned.

### Waves and enemies
- `wave_spawner.gd`:
  - Generates a new path each map (`generate_path`).
  - Calculates wave power using player power score and difficulty multipliers.
  - Spawns types: normal, swarm, fast, boss.
  - Tracks waves, rewards, and hint text for early onboarding.
- `Battlefield/Enemies/enemy_base.gd`:
  - Uses A* for pathing.
  - Deals damage on reaching the end.
  - Rewards money/meat on death.

### Upgrades
- `upgrade_manager.gd` pauses the world and spawns upgrade UI.
- Individual towers store path upgrades (3 upgrade paths per tower).

### Stats and economy
- `StatsManager` uses "meat" as health and placement currency.
- Production and kill multipliers increase over time and via persistent upgrades.
- Money is used for gacha and meta progression (currently stored and saved).

### Gacha and inventory meta
- `tower_manager.gd` tracks backpack and squad slots, and pull cost scaling.
- `gacha.gd` is mostly stubbed/commented; gacha UI exists under `Menus/Gacha/`.
- Current gacha menu is used as a game-over screen and disables the game area.

### UI and menus
- `Battlefield/GUI/` includes health bar, wave controls, drag preview, and buttons.
- Battlefield GUI includes a top-left difficulty popup with a trait list, +/- controls, and a money gain readout; when always expanded, the toggle button is hidden.
- `Menus/` includes difficulty, stats, challenges, gacha, win/lose, and load dialog.
- `menu_tab_selector.gd` customizes tab styles and resets the map on menu open.
- Difficulty menu uses the difficulty popup for trait adjustments and only shows the money gain label on the tab.

### Saving and timeline
- `SaveManager`:
  - Encrypted save data, autosave, and localStorage support on web builds.
  - Saves money, level, backpack, squad, pull cost, and persistent upgrades.
- `TimelineManager`:
  - Saves wave snapshots (`wave_save*`) for rewinds.
  - Restores inventory, towers, walls, and persistent bullets.

## Assets and presentation
- Fonts: Noto Sans, Open Sans, Noto Color Emoji.
- Shader: `Vignette.gdshader`.
- `color_tinter.gd` and `Vignette` used for background polish.

## Files to start with
- `project.godot` for autoloads and config.
- `Main_Scene.tscn` for node layout.
- `inventory_manager.gd` for towers and costs.
- `grid_controller.gd` for placement and walls.
- `wave_spawner.gd` for waves and path generation.
- `stats_manager.gd` for economy and health.
- `save_manager.gd` and `timeline_manager.gd` for persistence.

## Open design questions (to clarify next)
- Gacha design: number of pull buttons, odds per button, unlock conditions, and pull currency.
- Meta progression: how money, upgrades, and unlocks persist between runs.
- Camp flow: which tabs unlock and in what order after tutorial.
- Difficulty formula: weight for placed power vs total owned power, and smoothing window.
- Content roadmap: number of towers, enemies, biomes, and difficulty tiers.
- Monetization scope (if any): cosmetic only or power progression.
