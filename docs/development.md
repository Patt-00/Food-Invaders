# Food Invaders

A 16-bit NASM game for 386-compatible real-mode DOS. `main.asm` renders the original colored ASCII designs from the project document in a 180 by 120 SVGA text field. DOSBox-X launches the game full-screen with a 3:2 aspect ratio. The field has about 86% more character cells than the 132 by 88 version, and keeps the original art dimensions: Chef and weapons are 12 by 16 cells, food enemies are 14 to 22 by 11 to 16 cells, Ratatouille is 15 by 16 cells, and the fireball is 14 by 18 cells.

## Gameplay reference

Food Invaders takes its core gameplay idea from Space Invaders. A playable text-mode reference is [doctorfree/ninvaders at revision `dc38ab8`](https://github.com/doctorfree/ninvaders/tree/dc38ab8db9ecdb5f69fbd3b3deb42e253d6f08c3), an ncurses game with CMake build instructions. That revision built and entered gameplay in a Linux terminal and a Termux shell session on 2026-10-24. Food Invaders keeps its own 16-bit NASM DOSBox implementation and ASCII art.

## Build and run

See the [installation guide](BUILDING-GUIDE.md) for prerequisites and platform-specific steps. From the repository root, build and run the game with:

```sh
./scripts/build.sh
./run-linux.sh
```

`scripts/build.ps1 -Test -Core normal` assembles the game and four regression programs, checks their size, then runs the three suites in DOSBox-X. Regression COM files use a compact 156x104 test display to stay below the 60,000-byte DOS segment budget; the shipped game remains 180x120. Repeat with `-Core dynamic` to test the other supported CPU core.

Run with **DOSBox-X** and the `machine=svga_s3` setting. The program sets custom horizontal and vertical timing for 180 columns and 120 rows of 8 scanlines. It maps a 64 KiB A000 text window for the expanded frame. `packaging/dosbox/desktop.conf` supplies the emulator settings. The platform launch scripts mount `build/standard` and start `INVADERS.COM`; on Termux, `run-termux.sh` builds the faster profile and uses Termux:X11.

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
| `src/main.asm` | Initialization, keyboard input, menus and game loop |
| `src/variables.inc` | Shared constants, player pool and DWORD enemy/encounter state |
| `src/modules/player.asm` | Chef movement, lives and timed boosts |
| `src/modules/bullet.asm` | Both player weapons, hostile projectile pool and combat timers |
| `src/modules/enemy.asm` | Random roaming, attacks, metadata and damage API |
| `src/modules/collision.asm` | Weapon/enemy rectangles, chef contact, hostile hits and breaches |
| `src/modules/encounter.asm` | Simulation ordering, aggregated life loss and progression |
| `src/modules/display.asm` | Clipped colored rendering, original artwork, HUD and DWORD scores |
| `src/modules/menu.asm` | Main menu, game over and victory |
| `src/modules/features.asm` | Random fireball drops, falling, collection, and timed effect activation |

`simulate_tick` updates the player boost, timers, projectiles, enemies and collisions once per tick, then resolves damage/progression. Call `initialize_game` to reset everything. `fire_bullet` and `fire_secondary` allocate player shots; `remove_bullet_slot` takes the slot in SI. Collision checks use half-open rectangles and captured weapon damage, preserving all general-purpose registers. They queue life loss in `loss_pending`; `resolve_game_events` applies it once. Enemy deaths emit clear/boss events rather than immediately ending the game.

Enemy APIs use DWORD arguments with real-mode WORD return addresses: callers normalize ESP, push arguments right-to-left and remove them after the call. `get_enemy_bounds(index)` returns a slot pointer in EAX and metadata in EDX. `apply_enemy_damage(index, damage)` returns a new-death flag in EAX and a one-time reward in EDX; collision adds that reward to the DWORD score. Enemy APIs preserve EBX/ESI/EDI/EBP. DS/ES address the shared COM segment. Legacy `enemy_*` names alias DWORD fields in slot zero; legacy `bullet_*` names alias byte player-projectile slot zero.

Keep gameplay free of rendering interrupts, use one shared definition for each variable, preserve documented register contracts, and rebuild after integration changes. Collision bounds match the original artwork dimensions used by the renderer.

## Tests

`scripts/build.sh --test --core both` assembles and runs the core, player/weapon, and collision suites on both DOSBox-X CPU cores. Generated binaries, logs, and fresh results go under the ignored `build/tests/` directory; generated results are not committed.

For direct assembly, use these commands:

```sh
mkdir -p build/tests
nasm -I ./ -I src/ -I tests/ -f bin -Wall -w-reloc -Werror -DCOMPACT_TEST_DISPLAY -DSELFTEST src/main.asm -o build/tests/TEST.COM
nasm -I ./ -I src/ -I tests/ -f bin -Wall -w-reloc -Werror -DCOMPACT_TEST_DISPLAY tests/player-bullet.asm -o build/tests/PBTEST.COM
nasm -I ./ -I src/ -I tests/ -f bin -Wall -w-reloc -Werror -DCOMPACT_TEST_DISPLAY tests/collision.asm -o build/tests/COLLTEST.COM
nasm -I ./ -I src/ -I tests/ -f bin -Wall -w-reloc -Werror -DCOMPACT_TEST_DISPLAY -DSELFTEST -DVISUAL_TEST src/main.asm -o build/tests/WINTEST.COM
```

Run each COM in DOSBox-X, or let `scripts/build.sh --test --core both` do so. The core suite reports its assertion count; the player/weapon and collision suites report a named PASS or failure. The core suite includes the five-stage campaign, 20,000 simulation ticks, and cell-by-cell checks for all six source enemy/boss designs plus the fireball. It also checks random starting coverage, movement in both directions on both axes, spacing, and the Chef safety boundary across all waves. The player suite checks the Chef and both documented weapons, timed boosts, boundaries, pickup movement, and collection. The collision suite checks rectangle edges, immediate hostile hits on the Chef's head and outer edge, the safe-line breach path, damage priorities, inactive-state guards, registers, and stack balance. `WINTEST.COM` runs the core suite, then pauses on the rendered victory screen for a visual capture. The campaign state comes from the automated simulation.

For headless CPU-level checks, install the pinned optional Python dependency and run:

```sh
python3 -m pip install -r tests/requirements-test.txt
python3 tests/run-headless.py build/tests/TEST.COM build/tests/PBTEST.COM build/tests/COLLTEST.COM
```

This optional runner executes assembled x86 code with stubbed BIOS/DOS services and verifies frame-buffer/VGA memory. It does **not** validate DOSBox-X video timing or a manual playthrough. The host-specific prerequisite instructions are in the [installation guide](BUILDING-GUIDE.md).
