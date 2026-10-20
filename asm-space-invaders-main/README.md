# Food Invaders

A 16-bit NASM game for 386-compatible real-mode DOS. `main.asm` renders colored ASCII in a 132 by 88 SVGA text screen. Eight-pixel cells produce a 1056 by 704 gameplay field with a 3:2 ratio. The playable build uses all ten ASCII designs from the team document: the Chef, five food enemies, Ratatouille, two weapons, and the fireball pickup. The main menu previews all ten designs at their source cell dimensions.

## Build and run

From this directory, build the game with NASM:

```sh
nasm -f bin main.asm -o INVADERS.COM
```

`build.bat` provides the same basic build on Windows. `build.ps1 -Test -Core normal` assembles the game and three regression suites, then runs them in DOSBox-X. Repeat with `-Core dynamic` to test the other supported CPU core. All COM files must stay below 60,000 bytes to leave room for the DOS stack.

Run with **DOSBox-X** and the `machine=svga_s3` setting. The program sets custom vertical timing for 88 rows of 8 scanlines. `dosbox.conf` supplies the emulator settings and starts `INVADERS.COM` when DOSBox-X starts from this directory. On Windows, use `run-dosbox.ps1 -DosBoxPath <path-to-dosbox-x>`. On Termux, use `../run-termux.sh` with Termux X11.

## Controls and behavior

| Key | Action |
| --- | --- |
| A/D or arrow keys | Move the chef |
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

The Chef fires the full 12 by 16 cleaver design with Space and the full 12 by 16 rolling pin with X. Three player shots can be active at once, and the weapons share a cooldown. Cleavers fire every 24 game ticks and rolling pins every 40 ticks. Both travel two rows per update so shots stay visible long enough to overlap their firing cooldowns.

Each enemy defeat has a one-in-four chance to drop the document's 14 by 18 fireball when no pickup is already falling. It falls one row every 200 milliseconds. Catching a green fireball increases movement speed. Catching a red fireball adds one damage per shot. Catching a yellow fireball shortens cooldowns and adds a second cleaver to each shot. Each effect lasts 80 game ticks. Distinct effects can overlap, and another pickup refreshes the timer. `activate_player_powerup` remains available to modules that need to activate all three effects together.

The five food enemies use their documented source dimensions: the cupcake is 22 by 16, fries, hotdog, and pizza are 14 by 16, and the burger is 14 by 11. Ratatouille is 15 by 16. Each regular enemy gets a random destination, a movement delay, and, for hotdogs and pizzas, a separate firing timer. Five 26-cell columns and two 17-row vertical bands keep the full designs readable without sprite overlap. The front band starts at row 5; the rear band starts at row 24 and ends at row 41, leaving 30 rows before the Chef's initial top row. The boss moves across the screen and selects vertical targets beginning at row 6. Clearing four stages leads to the 20-HP Ratatouille boss. Defeating it produces victory. Game-over and victory screens preview the Chef, Ratatouille, and fireball at native sizes, then show the score and restart or quit controls. Contact, hostile fire, and bottom breaches aggregate to at most one life loss per tick. Surviving enemies retain health and reset positions after a hit. The Chef receives one second of invulnerability. Life loss takes priority over a simultaneous stage clear.

Hostile shots use visible 2×2 red markers, move one row every 200 ms, and collide with the Chef's full 12 by 16 sprite bounds. The first overlap with the head, body, or side registers a hit. Each shot interval is randomized within a stage-dependent range so enemies do not create a steady synchronized stream.

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
| `modules/features.asm` | Random fireball drops, falling, collection, and timed effect activation |

`simulate_tick` updates the player boost, timers, projectiles, enemies and collisions once per tick, then resolves damage/progression. Call `initialize_game` to reset everything. `fire_bullet` and `fire_secondary` allocate player shots; `remove_bullet_slot` takes the slot in SI. Collision checks use half-open rectangles and captured weapon damage, preserving all general-purpose registers. They queue life loss in `loss_pending`; `resolve_game_events` applies it once. Enemy deaths emit clear/boss events rather than immediately ending the game.

Enemy APIs use DWORD arguments with real-mode WORD return addresses: callers normalize ESP, push arguments right-to-left and remove them after the call. `get_enemy_bounds(index)` returns a slot pointer in EAX and metadata in EDX. `apply_enemy_damage(index, damage)` returns a new-death flag in EAX and a one-time reward in EDX; collision adds that reward to the DWORD score. Enemy APIs preserve EBX/ESI/EDI/EBP. DS/ES address the shared COM segment. Legacy `enemy_*` names alias DWORD fields in slot zero; legacy `bullet_*` names alias byte player-projectile slot zero.

Keep gameplay free of rendering interrupts, use one shared definition for each variable, preserve documented register contracts, and rebuild after integration changes. The Chef and both weapons render at their full 12 by 16 source size. Enemy and fireball bounds come from the artwork metadata and constants.

## Tests

`build.ps1 -Test` assembles and runs the core, player/weapon, and collision suites. The script saves their DOSBox-X output to `tests/integrated-<core>-result.txt`. `tests/integrated-binary-hashes.json` records the current game and core-test binary hashes. The older `tests/normal-result.txt`, `tests/dynamic-result.txt`, `tests/merged-result.txt`, and `tests/binary-hashes.json` preserve earlier validation records.

For direct assembly, use these commands:

```sh
nasm -f bin -Wall -w-reloc -Werror -DSELFTEST main.asm -o TEST.COM
nasm -f bin -Wall -w-reloc -Werror tests/player-bullet.asm -o PBTEST.COM
nasm -f bin -Wall -w-reloc -Werror tests/collision.asm -o COLLTEST.COM
nasm -f bin -Wall -w-reloc -Werror -DSELFTEST -DVISUAL_TEST main.asm -o WINTEST.COM
```

Run each COM in DOSBox-X. The core suite reports its assertion count; the player/weapon and collision suites report a named PASS or failure. The core suite includes the five-stage campaign, 20,000 simulation ticks, and cell-by-cell checks for all six enemy/boss designs plus the fireball. The player suite checks the Chef, both native-size weapons, timed boosts, boundaries, pickup movement, and collection. The collision suite checks rectangle edges, immediate hostile hits on the Chef's head and outer edge, damage priorities, inactive-state guards, registers, and stack balance. `WINTEST.COM` runs the core suite, then pauses on the rendered victory screen for a visual capture. The campaign state comes from the automated simulation.

For headless CPU-level checks, install the pinned optional Python dependency and run:

```sh
python3 -m pip install -r requirements-test.txt
python3 tests/run-headless.py TEST.COM PBTEST.COM COLLTEST.COM
```

This runs the assembled x86 code with stubbed BIOS/DOS services and verifies frame-buffer/VGA memory. It does **not** validate actual DOSBox-X video timing or a manual playthrough. See `MERGE-VALIDATION.md` for validation of this integrated version. `TEST-REPORT.md`, `tests/normal-result.txt`, and `tests/dynamic-result.txt` describe the earlier enemy-branch baseline.
