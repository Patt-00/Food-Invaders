# Food Invaders

A 16-bit NASM game for 386-compatible real-mode DOS. `main.asm` renders the original colored ASCII designs from the project document in a 180 by 120 SVGA text field. DOSBox-X launches the game full-screen with a 3:2 aspect ratio. The field has about 86% more character cells than the 132 by 88 version, and keeps the original art dimensions: Chef and weapons are 12 by 16 cells, food enemies are 14 to 22 by 11 to 16 cells, Ratatouille is 15 by 16 cells, and the fireball is 14 by 18 cells.

## Gameplay reference

Food Invaders takes its core gameplay idea from Space Invaders. A playable text-mode reference is [doctorfree/ninvaders at revision `dc38ab8`](https://github.com/doctorfree/ninvaders/tree/dc38ab8db9ecdb5f69fbd3b3deb42e253d6f08c3), an ncurses game with CMake build instructions. That revision built and entered gameplay in a Linux terminal and a Termux shell session on 2026-10-24. Food Invaders keeps its own 16-bit NASM DOSBox implementation and ASCII art.

## Build and run

See the [Windows and macOS building guide](../docs/BUILDING-GUIDE.md) for prerequisite installation and host-specific commands. From this directory, build the game with NASM:

```sh
nasm -f bin main.asm -o INVADERS.COM
```

`build.bat` provides the basic Windows build. `build.ps1 -Test -Core normal` assembles the 180x120 game and four regression programs, checks their size, then runs the three suites in DOSBox-X. Regression COM files use a compact 156x104 test display to stay below the 60,000-byte DOS segment budget; the shipped game remains 180x120. Repeat with `-Core dynamic` to test the other supported CPU core.

Run with **DOSBox-X** and the `machine=svga_s3` setting. The program sets custom horizontal and vertical timing for 180 columns and 120 rows of 8 scanlines. It maps a 64 KiB A000 text window for the expanded frame. `dosbox.conf` supplies the emulator settings and starts `INVADERS.COM` when DOSBox-X starts from this directory. On Windows, use `run-dosbox.ps1 -DosBoxPath <path-to-dosbox-x>`. On Termux, use `../run-termux.sh` with Termux X11.

## Controls and behavior

| Key | Action |
| --- | --- |
| A/D or arrow keys | Move the Chef three cells per keypress, or five with the speed boost |
| Space | Fire a cleaver (one damage) |
| X | Fire a rolling pin (two damage) |
| Escape | Quit |
| 1 | Select Easy and start, or restart on Easy from a result screen |
| 2 | Select Normal and start, or restart on Normal from a result screen |
| 3 | Select Hard and start, or restart on Hard from a result screen |
| P/Space | Start or restart on Normal |
| R | Restart after game over or victory at the current difficulty |
| Q/Esc | Quit from a menu or game |

The menu offers Easy, Normal, and Hard. Easy starts with five lives and lengthens enemy movement and firing delays by 50 percent. Normal starts with three lives and uses the stage delays. Hard starts with two lives and shortens both enemy delays by 25 percent.

The Chef fires the 12 by 16 document cleaver with Space and the 12 by 16 rolling pin with X. Three player shots can be active at once, and the weapons share a cooldown. Cleavers fire every 16 game ticks, or 0.8 seconds. Rolling pins fire every 28 ticks, or 1.4 seconds. Both travel two rows per update.

Each enemy defeat has a one-in-four chance to drop the 14 by 18 document fireball when no pickup is already falling. It falls one row every 50 milliseconds. Catching a green fireball increases movement speed. Catching a red fireball adds one damage per shot. Catching a yellow fireball shortens cooldowns and adds a second cleaver to each shot. Each effect lasts 80 game ticks. Distinct effects can overlap, and another pickup refreshes the timer. `activate_player_powerup` remains available to modules that need to activate all three effects together.

The four named waves are Patrol, Flankers, Crossfire, and Last Stand. Enemies spawn at random positions across the playfield. Each enemy chooses a new signed X and Y step independently when its movement timer expires. The steps are collision checked, keep a four-cell clearance between enemies, and stop above a safe line eight rows above the Chef. Every enemy has an independent randomized firing timer. Later waves shorten the movement and firing intervals, and the fifth wave starts Ratatouille at a random position.

Enemies move and fire on independent random timers. At Normal difficulty, movement delays are configured from 120 to 360 milliseconds in Patrol and from 60 to 240 milliseconds in Last Stand. Random step ranges grow each wave: Patrol uses up to four columns and two rows per axis; Last Stand uses up to ten columns and five rows. Each monster's firing delay falls from 2.6 to 5 seconds in Patrol to 1.55 to 2.9 seconds in Last Stand. Easy and Hard scale movement and firing delays. The 50 ms game tick quantizes the timers.

Hostile-shot markers occupy one text cell and move faster each wave. Their configured delay falls from 80 milliseconds in Patrol to 35 milliseconds in Last Stand. The 50 ms game tick limits the fastest movement to one row per tick. The 20-HP Ratatouille boss appears on stage five and fires every 1 to 2 seconds. Defeating it produces victory. Game-over and victory screens preview the exact Chef, Ratatouille, and fireball designs from the document, then show the score and restart or quit controls. Contact, hostile fire, and safe-line breaches aggregate to at most one life loss per tick. The Chef receives one second of invulnerability. Life loss takes priority over a simultaneous stage clear.

Hostile shots use visible 1×1 red markers and collide with the Chef's 12 by 16 bounds. The first overlap with the head, body, or side registers a hit.

## Architecture and interfaces

| File | Responsibility |
| --- | --- |
| `main.asm` | Initialization, keyboard input, menus and game loop |
| `variables.inc` | Shared constants, player pool and DWORD enemy/encounter state |
| `modules/player.asm` | Chef movement, lives and timed boosts |
| `modules/bullet.asm` | Both player weapons, hostile projectile pool and combat timers |
| `modules/enemy.asm` | Random roaming, attacks, metadata and damage API |
| `modules/collision.asm` | Weapon/enemy rectangles, chef contact, hostile hits and breaches |
| `modules/encounter.asm` | Simulation ordering, aggregated life loss and progression |
| `modules/display.asm` | Clipped colored rendering, original artwork, HUD and DWORD scores |
| `modules/menu.asm` | Main menu, game over and victory |
| `modules/features.asm` | Random fireball drops, falling, collection, and timed effect activation |

`simulate_tick` updates the player boost, timers, projectiles, enemies and collisions once per tick, then resolves damage/progression. Call `initialize_game` to reset everything. `fire_bullet` and `fire_secondary` allocate player shots; `remove_bullet_slot` takes the slot in SI. Collision checks use half-open rectangles and captured weapon damage, preserving all general-purpose registers. They queue life loss in `loss_pending`; `resolve_game_events` applies it once. Enemy deaths emit clear/boss events rather than immediately ending the game.

Enemy APIs use DWORD arguments with real-mode WORD return addresses: callers normalize ESP, push arguments right-to-left and remove them after the call. `get_enemy_bounds(index)` returns a slot pointer in EAX and metadata in EDX. `apply_enemy_damage(index, damage)` returns a new-death flag in EAX and a one-time reward in EDX; collision adds that reward to the DWORD score. Enemy APIs preserve EBX/ESI/EDI/EBP. DS/ES address the shared COM segment. Legacy `enemy_*` names alias DWORD fields in slot zero; legacy `bullet_*` names alias byte player-projectile slot zero.

Keep gameplay free of rendering interrupts, use one shared definition for each variable, preserve documented register contracts, and rebuild after integration changes. Collision bounds match the original artwork dimensions used by the renderer.

## Tests

`build.ps1 -Test` assembles and runs the core, player/weapon, and collision suites. The script saves their DOSBox-X output to `tests/integrated-<core>-result.txt`. `tests/integrated-binary-hashes.json` records the game and core-test binary hashes for that validation.

For direct assembly, use these commands:

```sh
nasm -f bin -Wall -w-reloc -Werror -DSELFTEST main.asm -o TEST.COM
nasm -f bin -Wall -w-reloc -Werror tests/player-bullet.asm -o PBTEST.COM
nasm -f bin -Wall -w-reloc -Werror tests/collision.asm -o COLLTEST.COM
nasm -f bin -Wall -w-reloc -Werror -DSELFTEST -DVISUAL_TEST main.asm -o WINTEST.COM
```

Run each COM in DOSBox-X. The core suite reports its assertion count; the player/weapon and collision suites report a named PASS or failure. The core suite includes the five-stage campaign, 20,000 simulation ticks, and cell-by-cell checks for all six source enemy/boss designs plus the fireball. It also checks random starting coverage, movement in both directions on both axes, spacing, and the Chef safety boundary across all waves. The player suite checks the Chef and both documented weapons, timed boosts, boundaries, pickup movement, and collection. The collision suite checks rectangle edges, immediate hostile hits on the Chef's head and outer edge, the safe-line breach path, damage priorities, inactive-state guards, registers, and stack balance. `WINTEST.COM` runs the core suite, then pauses on the rendered victory screen for a visual capture. The campaign state comes from the automated simulation.

For headless CPU-level checks, install the pinned optional Python dependency and run:

```sh
python3 -m pip install -r requirements-test.txt
python3 tests/run-headless.py TEST.COM PBTEST.COM COLLTEST.COM
```

This optional runner executes assembled x86 code with stubbed BIOS/DOS services and verifies frame-buffer/VGA memory. It does **not** validate DOSBox-X video timing or a manual playthrough. The current normal and dynamic DOSBox-X results are stored in `tests/integrated-normal-result.txt` and `tests/integrated-dynamic-result.txt`. The host-specific prerequisite instructions are in [the building guide](../docs/BUILDING-GUIDE.md).
