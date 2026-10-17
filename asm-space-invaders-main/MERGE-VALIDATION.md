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
