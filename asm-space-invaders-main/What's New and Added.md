# What's New and Added

This document describes the changes made after fetching the original `Patt-00/asm-space-invaders` project. It covers the Food Invaders version in `food-invaders-with-impEnemies` and replaces the previous `UPDATED-FILES.md`.

## What changed from the original

The original was a small Space Invaders prototype: one stationary enemy, one upward-moving player bullet, basic coordinate collision, and a round that ended after the enemy was hit. The new version adds a Food Invaders enemy system and the supporting code needed to display, attack, damage and progress through multiple enemies.

It still runs as a DOS `.COM` program inside DOSBox. The program retains `BITS 16` execution, while using 386+ 32-bit registers and DWORD calculations for enemy state, movement, collision, health, timers and hostile projectiles. It is not a protected-mode `BITS 32` program or a native Windows application.

## New gameplay and enemy mechanics

### Five regular food enemy types

| Enemy | Starting HP | Points | Behavior |
| --- | ---: | ---: | --- |
| Cupcake Eater Monster | 1 | 10 | Moves with the formation |
| French Fries Monster | 1 | 10 | Moves with the formation |
| Burger Eater Monster | 2 | 20 | Moves with the formation and survives one normal hit |
| Hotdog Madness Monster | 1 | 20 | Moves with the formation and shoots downward |
| Pizza Goblin Monster | 2 | 30 | Moves with the formation, shoots downward and survives one normal hit |

These exact health values, scores and shooter assignments are implementation choices adopted from the plan. The project document supports different enemy attributes and attacks but does not specify every value or individual ability.

### Formation movement and screen limits

- Regular stages contain two rows of five enemies rather than one stationary enemy.
- Living enemies move horizontally as a formation. At a side boundary, the formation reverses direction and descends once.
- Each enemy's actual width and height determine its legal movement and collision area.
- Dead enemies stop moving, shooting and colliding, and no longer affect formation boundaries.
- An attempted descent beyond the bottom generates a breach event without storing an off-screen position.
- Gameplay uses a fixed 80x25 text display. Resizing the DOSBox window does not change logical positions or hitboxes.

### Enemy bullet attacks

- Hotdog and Pizza enemies can fire downward projectiles. Ratatouille uses the same projectile system with its own firing interval.
- Eligible shooters are selected in round-robin order. Upper-row shooters are blocked while a living enemy remains below them in the same formation column.
- Bullets spawn below the firing sprite and move downward one logical row at a time.
- A pool of 16 hostile projectiles limits memory use. If the pool is full, a scheduled shot is skipped.
- Hostile bullets disappear when they hit the player or leave the play area.
- Player firing retains one active projectile and gains a minimum cooldown.

### Ratatouille boss encounter

- Ratatouille appears alone on stage five with 20 HP and a 500-point reward.
- The boss patrols horizontally near the top, reverses at side boundaries and does not descend like the regular formation.
- The boss has separate movement and firing timing.
- Multiple hits are required to defeat it. Defeating Ratatouille completes this five-stage version and displays victory.

### Collision, damage and progression

- Collision checks now inspect each active enemy separately rather than a single global enemy rectangle.
- Enemy damage reduces HP; a nonfatal hit leaves the enemy alive.
- Each enemy death awards points once. A hit no longer immediately ends the round.
- Projectile checks occur before and after one-cell movement to avoid skipping targets.
- Enemy contact, hostile bullets and a bottom breach can cause life loss, with at most one life lost per simulation tick.
- After surviving a hit, remaining enemies return to their spawn positions with their remaining HP retained, projectiles clear, and the player receives temporary invulnerability.
- Clearing each regular formation advances the stage. Restart resets the enemy arrays, bullets, timers, lives, score and stage.

### Food Invaders presentation

- Food Invaders title, controls and enemy instructions replace the Space Invaders menu presentation.
- Compact colored ASCII food enemies, a chef and a distinct rat boss fit the 80x25 display.
- Buffered VGA rendering draws every active enemy and both projectile types.
- The HUD displays score, lives, stage and boss HP during the boss encounter.
- Score formatting supports DWORD values rather than only 0-99.
- Existing art-symbol mismatches and the original colored-row rendering problem were addressed in the active rendering path.

## Existing files updated

| File | What was updated |
| --- | --- |
| `modules/enemy.asm` | Enemy records, type attributes, formation/boss movement, shooting decisions, health and encounter events using 32-bit calculations |
| `modules/collision.asm` | Per-enemy hitboxes, health/damage calls, hostile bullet hits, contact/breach damage requests and scoring |
| `modules/bullet.asm` | Hostile projectile pool, spawning, movement/removal, player firing cooldown and combat timers |
| `variables.inc` | Central enemy/projectile layouts, bounds, counters, timers and shared type metadata; player/bullet coordinates remain byte-sized |
| `main.asm` | DOS/386 startup, stack-pointer normalization, shared simulation call, new-state reset and victory handling |
| `modules/display.asm` | Buffered VGA renderer for the full enemy collection, chef, boss, bullets, clipping and expanded HUD/score display |
| `modules/menu.asm` | Food Invaders menu, controls, instructions, results and victory screen |
| `assets/enemy_art.inc` | Compact food enemy/boss art and type metadata |
| `assets/player_art.inc` | Compact chef artwork |
| `assets/title_art.inc` | Food Invaders title |
| `README.md` | Current runtime, build/run instructions, mechanics and calling/data interfaces |

The existing filename is `enemy.asm`, singular. Its original public names `initialize_enemies`, `update_enemies` and `move_enemies` remain no-argument entry points.

## Files added

| File | Purpose |
| --- | --- |
| `modules/encounter.asm` | Shared simulation tick, life-loss resolution, stage transitions and victory |
| `build.ps1` | Host-side NASM build, COM size checks and optional DOSBox tests |
| `run-dosbox.ps1` | Host-side DOSBox launcher |
| `dosbox.conf` | Local emulator/game launch configuration |
| `RUNTEST.BAT` | DOS-side test execution and status reporting |
| `tests/core.asm` | Regression, stress, BIOS input and VGA rendering tests |
| `tests/normal-result.txt` | Recorded normal-core test result |
| `tests/dynamic-result.txt` | Recorded dynamic-core test result |
| `tests/binary-hashes.json` | Hashes recorded for the tested binaries |
| `TEST-REPORT.md` | Detailed verification results, scope and limitations |
| `.gitignore` | Generated-file exclusions |
| `What's New and Added.md` | This version's feature and file change summary |

`INVADERS.COM` is the rebuilt game binary. `TEST.COM` is the added compiled regression harness. Both are included in this folder.

## Original files retained unchanged

- `modules/player.asm`
- `modules/features.asm`
- `build.bat`
- `assets/variables.inc`
- `assets/bullet_art.inc`
- `assets/gameover_art.inc`

The player module's movement and life-loss interfaces remain in use. The feature module is still its original placeholder.

## Testing and scope

The implementation passed **40,280 assertions on each of DOSBox Staging 0.82.2's normal and dynamic CPU cores**, configured for a 386. Checks include a complete five-stage campaign, 20,000 simulation ticks per run, enemy/projectile bounds, health, scoring, boss defeat, BIOS keyboard input and rendered VGA-memory contents. A manual visual playthrough was not completed. See `TEST-REPORT.md` for the full evidence and limitations.

The document's separate secondary-weapon, power-up, sound, save-data and difficulty-menu features are not implemented by this enemy-focused update. Compact artwork replaces the oversized document illustrations. Movement and firing intervals use nominal 50ms simulation ticks, so actual wall-clock timing also depends on rendering and emulator speed.

## Running this Desktop copy

Inside DOSBox:

```dos
mount c "C:\Users\lnsan\Desktop\food-invaders-with-impEnemies"
c:
INVADERS.COM
```

Do not execute the COM file directly as a Windows application. NASM and DOSBox are external tools and are not bundled in this folder. When using the PowerShell scripts from this Desktop location, supply explicit `-NasmPath` and `-DosBoxPath` arguments if the tools are not found; the original workspace-relative fallback does not apply here.
