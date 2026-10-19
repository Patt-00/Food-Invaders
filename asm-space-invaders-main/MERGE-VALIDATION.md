# Branch merge validation

Validated on 17 October 2026. The integrated source combines `origin/main`, `origin/dev-1/collision-module` (including `origin/dev-2`), and `origin/food-invaders-imp-enemies`.

## Conflict decisions

- Preserve the 132×120 display, original 12×16 chef, 6×8 dual-weapon sprites, three-shot pool, shared cooldowns, and timed player boosts.
- Retain the enemy branch's type metadata, ten-enemy formation, hostile projectile pool, DWORD health/score, life-loss aggregation, stages, and final boss.
- Apply rectangle collisions and captured weapon damage to every enemy slot through the enemy bounds/damage APIs. Keep register preservation and non-playing-state guards. Enemy death emits a progression event; contact/breaches preserve surviving enemy health and resolve one life loss per tick.
- Update arena bounds, rendering, menu placement, HUD, input, reset logic, and DOSBox-X launchers to use the combined interfaces. Tick player boosts once per simulation update.
- Port all three existing suites to the combined contracts while retaining their boundary, damage, register, rendering, campaign, and stress checks.

## Executed checks

NASM 2.16.03 assembled the game and all suites with `-f bin -Wall -w-reloc -Werror`. The relocation warning exclusion matches the existing flat-binary build configuration.

| Binary | Bytes | Result |
| --- | ---: | --- |
| `INVADERS.COM` | 37,858 | Build passed |
| `TEST.COM` | 45,974 | 40,280 assertions passed, including the five-stage campaign and 20,000 simulation ticks |
| `PBTEST.COM` | 47,674 | Player, dual weapons, boosts, collision and artwork checks passed |
| `COLLTEST.COM` | 19,592 | Collision geometry, damage, priority, state guards, registers and stack checks passed |

All binaries remain below the 60,000-byte code/data budget. The tracked game and core-test binaries were rebuilt from the merged sources; their SHA-256 hashes are in `tests/binary-hashes.json`.

The suites ran as actual assembled x86 instructions under Unicorn 2.1.4 through `tests/run-headless.py`. BIOS/DOS services are stubs; rendering checks inspect emulated frame-buffer/VGA memory. This validates gameplay and memory behavior, but does not establish real DOSBox-X video timing, physical input, launcher behavior on Windows/Termux, or a manual playthrough. DOSBox-X was unavailable on this host.

`tests/merged-result.txt` records these results. The older `TEST-REPORT.md`, `tests/normal-result.txt`, and `tests/dynamic-result.txt` remain historical evidence for the enemy branch, not validation of this merge. Reproduction commands are in `README.md`.

## Follow-up: document artwork and integrated tests, 2026-10-19

The playable renderer uses the artwork in `assets/player_art.inc`, `assets/bullet_art.inc`, `assets/enemy_art.inc`, and `assets/feature_art.inc`. It draws each design at the same cell size as the team document.

| Design | Rendered cells |
| --- | ---: |
| Chef | 12 by 16 |
| Cleaver | 12 by 16 |
| Rolling pin | 12 by 16 |
| Cupcake | 22 by 16 |
| French fries | 14 by 16 |
| Burger | 14 by 11 |
| Hotdog | 14 by 16 |
| Pizza | 14 by 16 |
| Ratatouille | 15 by 16 |
| Fireball pickup | 14 by 18 |

Regular enemies choose independent random targets within five 26-cell columns and two vertical bands. These bounds leave a gap between adjacent source designs, including the 22-cell cupcake. Each enemy keeps its own randomized movement timer. Hotdogs and pizzas also keep separate firing timers. The boss chooses targets across the full screen.

`tests/core.asm` compares each food-enemy and boss frame cell against separate copies in `assets/source_art.inc`. `tests/player-bullet.asm` compares the Chef and both full-size weapons against those copies. The core suite also compares every fireball cell. The live reference arrays remain test-only; the game renders the source assets.

NASM 3.02 assembled the following COM files with `-f bin -Wall -w-reloc -Werror`:

| Binary | Bytes | Result |
| --- | ---: | --- |
| `INVADERS.COM` | 41,601 | Built below the 60,000-byte limit |
| `TEST.COM` | 54,117 | Built below the limit |
| `PBTEST.COM` | 55,016 | Built below the limit |
| `COLLTEST.COM` | 22,781 | Built below the limit |
| `WINTEST.COM` | 54,133 | Built below the limit |

DOSBox-X 2026.10.01 with a 386 CPU ran `RUNTEST.BAT` on both the normal and dynamic cores. `TEST.COM` passed 40,300 assertions. `PBTEST.COM` and `COLLTEST.COM` also reported PASS on both cores. The outputs are preserved in `tests/integrated-normal-result.txt` and `tests/integrated-dynamic-result.txt`. Unicorn 2.1.4 also passed the same three COM test programs with stubbed BIOS/DOS services. That host-side run does not replace the DOSBox-X results.

`tests/integrated-binary-hashes.json` records the game and core-test hashes for this verification. The earlier `tests/binary-hashes.json` remains paired with the 17 October record.

`build.ps1 -Test` ran under PowerShell 7.6.6 on Fedora 44 for both CPU cores, using a temporary adapter to the installed DOSBox-X Flatpak. The wrapper's headless `-silent` invocation passed all three suites and recorded the results above. The Windows-specific PowerShell/DOSBox-X path was not tested on Windows.
