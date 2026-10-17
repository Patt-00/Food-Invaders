# Food Invaders

A modular NASM game for 386-compatible real-mode DOS. This integration combines the original chef artwork, dual weapons and boosts with colored enemy formations, hostile shots, stages and the Ratatouille boss. Rendering uses a 132×120 SVGA text battlefield with an in-memory frame buffer.

## Build and run

From this directory, use NASM:

```sh
nasm -f bin main.asm -o INVADERS.COM
```

`build.bat` provides the same build on Windows. `build.ps1` also supports warning checks and tests. All COM files must stay below 60,000 bytes to leave room for the DOS stack.

Run with **DOSBox-X**, configured with `machine=svga_s3`. The enlarged display uses custom vertical timing; the enemy branch's earlier DOSBox Staging configuration does not provide this integrated display. `dosbox.conf` supplies the game configuration. Mount this directory as drive C and run `INVADERS.COM`, or use `run-dosbox.ps1 -DosBoxPath <path-to-dosbox-x>` on Windows. On Termux, use `../run-termux.sh` with Termux X11.

## Controls and behavior

| Key | Action |
| --- | --- |
| A/D or arrow keys | Move the chef |
| Space | Fire a cleaver (one damage) |
| X | Fire a rolling pin (two damage) |
| Escape | Quit |
| 1/P/Space | Start at the menu |
| R/Space | Restart after game over or victory |
| 2/Q | Quit from a menu |

Three player projectile slots share a weapon cooldown. Cleavers wait 24 ticks and rolling pins 40 ticks; both move three rows per update. `activate_player_powerup` enables an 80-tick boost: faster movement, one extra damage, shorter cooldowns, and two-cleaver bursts. Pickup spawning remains an extension point.

Ten enemies form two rows per regular stage. Cupcakes, fries and hotdogs have one HP; burgers and pizzas have two. Hotdogs and pizzas fire from the bottom eligible row. Type metadata controls each enemy's dimensions, color, HP and score. Clearing four stages leads to the 20-HP Ratatouille boss; defeating it produces victory. Contact, hostile fire and bottom breaches aggregate to at most one life loss per tick. Surviving enemies retain health and reset positions after a hit; shots clear and the chef receives one second of invulnerability. Life loss takes priority over a simultaneous stage clear.

## Architecture and interfaces

| File | Responsibility |
| --- | --- |
| `main.asm` | Initialization, keyboard input, menus and game loop |
| `variables.inc` | Shared constants, player pool and DWORD enemy/encounter state |
| `modules/player.asm` | Chef movement, lives and timed boosts |
| `modules/bullet.asm` | Both player weapons, hostile projectile pool and combat timers |
| `modules/enemy.asm` | Formations, movement, attacks, metadata and damage API |
| `modules/collision.asm` | Weapon/enemy rectangles, chef contact, hostile hits and breaches |
| `modules/encounter.asm` | Simulation ordering, aggregated life loss and progression |
| `modules/display.asm` | Clipped colored rendering, original artwork, HUD and DWORD scores |
| `modules/menu.asm` | Main menu, game over and victory |
| `modules/features.asm` | Shield and future pickup extension points |

`simulate_tick` updates the player boost, timers, projectiles, enemies and collisions once per tick, then resolves damage/progression. Call `initialize_game` to reset everything. `fire_bullet` and `fire_secondary` allocate player shots; `remove_bullet_slot` takes the slot in SI. Collision checks use half-open rectangles and captured weapon damage, preserving all general-purpose registers. They queue life loss in `loss_pending`; `resolve_game_events` applies it once. Enemy deaths emit clear/boss events rather than immediately ending the game.

Enemy APIs use DWORD arguments with real-mode WORD return addresses: callers normalize ESP, push arguments right-to-left and remove them after the call. `get_enemy_bounds(index)` returns a slot pointer in EAX and metadata in EDX. `apply_enemy_damage(index, damage)` returns a new-death flag in EAX and a one-time reward in EDX; collision adds that reward to the DWORD score. Enemy APIs preserve EBX/ESI/EDI/EBP. DS/ES address the shared COM segment. Legacy `enemy_*` names alias DWORD fields in slot zero; legacy `bullet_*` names alias byte player-projectile slot zero.

Keep gameplay free of rendering interrupts, use one shared definition for each variable, preserve documented register contracts, and rebuild after integration changes. The chef remains 12×16; weapon artwork is reduced from 12×16 to 6×8 at draw time. Enemy sprite sizes come from their metadata.

## Tests

Assemble all existing suites from this directory:

```sh
nasm -f bin -Wall -w-reloc -Werror -DSELFTEST main.asm -o TEST.COM
nasm -f bin -Wall -w-reloc -Werror tests/player-bullet.asm -o PBTEST.COM
nasm -f bin -Wall -w-reloc -Werror tests/collision.asm -o COLLTEST.COM
```

Run each COM in DOSBox-X. They print `PASS` or a specific failure and return status 0 or 1. The core suite includes a five-stage campaign and 20,000 simulation ticks. The player suite checks weapons, boosts, boundaries, artwork and frame presentation. The collision suite checks rectangle edges, damage, priorities, inactive-state guards, registers and stack balance.

For headless CPU-level checks, install the optional Python `unicorn` package and run:

```sh
python3 tests/run-headless.py TEST.COM PBTEST.COM COLLTEST.COM
```

This runs the assembled x86 code with stubbed BIOS/DOS services and verifies frame-buffer/VGA memory. It does **not** validate actual DOSBox-X video timing or a manual playthrough. See `MERGE-VALIDATION.md` for validation of this integrated version. `TEST-REPORT.md`, `tests/normal-result.txt`, and `tests/dynamic-result.txt` describe the earlier enemy-branch baseline.
