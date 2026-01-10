# Fox TD Agent Context

This document summarizes the current project state and code layout so a new agent can quickly understand the whole codebase and how the game fits together.

## Local coding rule
- Use `=` for variable declarations; do not use `:=`.
- For highlight overlays, always clip to the buildable grid bounds and avoid drawing outside the grid.

## Project intent
- Game: tower defense with pull/critter mechanics.
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
- Menus: `Menus/Menu.tscn` with tabbed sections for stats, challenges, difficulty, pulls, win screen, etc.
- Menu tabs: `Menus/UpgradeMenu/upgrade_menu.tscn` handles per-tower upgrades; a separate `Stats` tab (StatsMenu UI) shows persistent upgrades grouped by Economy/Combat.

## Autoload singletons (global systems)
Defined in `project.godot`:
- `Dev`: `dev.gd` (dev toggles).
- `ItemDB`: `item_db.gd` (placeholder data layer).
- `WaveSpawner`: `wave_spawner.gd` (enemy waves, path generation, power scaling).
- `InventoryManager`: `inventory_manager.gd` (tower definitions, drag/drop inventory, costs).
- `GridController`: `grid_controller.gd` (grid placement, wall placement, drag towers).
- `StatsManager`: `stats_manager.gd` (health, production, upgrades, money).
- `Utilities`: `utilities.gd` (utility helpers, floating text).
- `AStarManager`: `a_star_manager.gd` (pathfinding and blocked tiles).
- `WaveShower`: `wave_shower.gd` (upcoming wave preview UI).
- `TowerManager`: `tower_manager.gd` (pull inventory and squad lists).
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
- Pull buttons: multiple pull buttons unlock over time; each has better odds.
- Legacy pulls: earlier buttons remain usable after newer ones unlock.
- Duplicates: allowed.
- Pity: every 20 rolls; guarantees the highest rarity available for that button.
- Pity reset: resets early if the top rarity is pulled before 20.
- Tutorial: 6 waves long with 2 starter towers in inventory.
- Post-tutorial: prompt player to return to camp and teach critter pulls, moving towers to squad, and any available tabs.
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
- Element colors:
  - Towers roll 1-2 colors on pull (10% for 2 colors, 1% for 3 colors); stored on tower colors.
  - Matching wave color deals 2x damage (handled in Battlefield/Game/bullet.gd).
  - Small colored dots show tower colors (camp/inventory and placed towers); placed tower dots render from a ColorDots child in Battlefield/Game/tower.gd so they sit above the sprite while the border/background stay behind it.
  - Camp merges keep the target tower's colors and store both originals for unmerge restore.
- Costs:
  - Placement cost scales by rank and rarity.
  - Upgrade cost scales by rank and current upgrades.
- Power evaluation:
  - `get_total_field_dps` and `get_player_power_score` influence wave scaling.

### Grid placement and pathing
- `grid_controller.gd` manages a fixed 22x15 grid of 8px cells.
- Buildable tiles come from scene nodes in group `grid_buildable`.
- Walls can be placed if they do not block the path (checked via `AStarManager`).
- Wall placement cost increases by +1 per wall placed (after base cost and discounts).
- Towers are draggable and can be repositioned.
- Path generation now uses multiple pattern pools (zigzag/wander/detour), supports branching paths that rejoin the main route, and varies path width (up to 5 tiles).
- Path tiles can be 8x8 or 16x16 depending on level, with the entrance always 16x16 to avoid spawn pinching.
- Level 1 uses a deterministic simple zigzag path with at least 5 turns (no branching/width widening).

### Waves and enemies
- `wave_spawner.gd`:
  - Generates a new path each map (`generate_path`).
  - Calculates wave power using player power score and difficulty multipliers.
  - Spawns types: normal, swarm, fast, boss.
  - Tracks waves, rewards, and hint text for early onboarding.
  - Each wave is assigned a red/green/blue color and passed to enemies.
- `Battlefield/Enemies/enemy_base.gd`:
  - Uses A* for pathing.
  - Deals damage on reaching the end.
  - Rewards money/meat on death.
  - Enemies are tinted to their wave color.
- Phasing enemies (phase, stalker) become untargetable when within 1.5 tiles of a tower; phased enemies leave the `enemies` group so bullets will retarget.
  - Phased enemies leave the `enemies` group so bullets will retarget.

### Upgrades
- `upgrade_manager.gd` pauses the world and spawns upgrade UI.
- Individual towers store path upgrades (3 upgrade paths per tower).
- Meta upgrades: `Menus/UpgradeMenu/upgrade_menu.gd` adds an "Upgrade" camp tab (tab node is `Upgrade`) for per-tower stat upgrades that directly mutate `InventoryManager.items` and refresh live towers; list refreshes on pull actions.
- Meta upgrades UI: `Menus/StatsMenu/stats_increase_button_container.gd` builds two columns (Economy/Combat) and renders each row as label + button with coin cost; all stat base costs are 100, tower move cooldown reduction is 5% per level, and Combat includes Meat on Hit.
- Upgrade menu UX: stat rows show a tooltip with a short description and current level; range is displayed in tiles (floor(radius / 8)), attack speed shows `/s`, and range/respawn time rows are hidden for guard towers.

### Stats and economy
- `StatsManager` uses "meat" as health and placement currency.
- Production and kill multipliers increase over time and via persistent upgrades; persistent upgrades have a base cost of 100 that doubles each level.
- Money is used for critter pulls and meta progression (currently stored and saved); UI uses a coin emoji (🪙) via `StatsManager.get_coin_symbol()`.
- Free critter pulls are granted per win via `WaveSpawner.level_completed`.
- Tower move cooldown, wall placement cost, tower placement cost discounts, and pull cost reduction cap at 50%.
- Dragging a placed tower onto the inventory sells it for 40% of placement cost in meat and shows a "Sell for X meat" overlay.
- Meat on Hit upgrade grants meat equal to a percentage of tower damage per hit (0.5% base, +0.5% per tier).

### Pulls and inventory meta
- `tower_manager.gd` tracks backpack and squad slots, and pull cost scaling.
- `gacha.gd` is mostly stubbed/commented; pull UI exists under `Menus/Gacha/`.
- Current pull menu is used as a game-over screen and disables the game area.
- `Menus/Gacha/start_new_game_button.gd` carries squad tower `colors`, `path`, and `merge_children` into the in-game inventory on start.

### UI and menus
- `Battlefield/GUI/` includes health bar, wave controls, drag preview, and buttons.
- Battlefield GUI includes a top-left difficulty popup with a trait list, +/- controls, and a money gain readout; when always expanded, the toggle button is hidden.
- `Menus/` includes difficulty, stats, challenges, pulls, win/lose, and load dialog.
- `menu_tab_selector.gd` customizes tab styles and resets the map on menu open.
- Difficulty menu uses the difficulty popup for trait adjustments and only shows the money gain label on the tab.
- Next wave indicator shows the current wave's enemy type, tints to the wave color, and only advances after the wave completes (`Battlefield/GUI/next_wave_preview.gd`).
- Tower bans: after each level, the top 25% of tower types by damage share across the last 2 waves are banned for the next level (only once at >=5 unlocked). Bans activate when the menu opens, block placement, show a black overlay + emoji in inventory, and add “Banned this level.” to tooltips. Banned towers also remove certain enemy types from the pool (swarm/swarmling/splitter if Elephant/Duck/Snail are banned; stalker if Hawk is banned).

### Saving and timeline
- `SaveManager`:
  - Encrypted save data, autosave, and localStorage support on web builds.
  - Saves money, level, backpack, squad, pull cost, and persistent upgrades.
- `TimelineManager`:
  - Saves wave snapshots (`wave_save*`) for rewinds.
  - Restores inventory, towers, walls, and persistent bullets.
  - Reloads also rebuilds the A* grid after wall restoration.

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
- `dev.gd` for dev toggles (unlock all towers + fill inventory).
- `stats_manager.gd` for economy and health.
- `save_manager.gd` and `timeline_manager.gd` for persistence.

## Open design questions (to clarify next)
- Pull design: number of pull buttons, odds per button, unlock conditions, and pull currency.
- Meta progression: how money, upgrades, and unlocks persist between runs.
- Camp flow: which tabs unlock and in what order after tutorial.
- Difficulty formula: weight for placed power vs total owned power, and smoothing window.
- Content roadmap: number of towers, enemies, biomes, and difficulty tiers.
- Monetization scope (if any): cosmetic only or power progression.
