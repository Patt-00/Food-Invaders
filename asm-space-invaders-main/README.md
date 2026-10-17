# Food Invaders - DOSBox, with 32-bit calculations

This is the active implementation. It starts from the original DOS project, retains real-mode `BITS 16` execution and `.COM` output, and uses 386+ 32-bit registers/operations for enemy state, movement, damage, collision and hostile projectiles. It is not a native Windows executable or protected-mode `BITS 32` program. DOSBox runs it inside its own window.

The earlier native Windows attempt is archived under `outputs/Superseded-Win32`. The pre-implementation DOS source is preserved in `outputs/Original-DOS-Baseline.zip`. The Desktop project shortcut still opens this active source folder.

## Run

The compiled game is `INVADERS.COM`. Run it inside DOSBox, not by double-clicking it as a Windows executable:

```dos
mount c "C:\path\to\asm-space-invaders-main"
c:
INVADERS.COM
```

Alternatively, from this project folder on the current machine:

```powershell
.\run-dosbox.ps1
```

Supply `-DosBoxPath 'C:\path\to\dosbox.exe'` if DOSBox is elsewhere. The script checks PATH, then the workspace's portable test runtime. The provided `dosbox.conf` mounts the working directory and launches the game. The supplied runtime is DOSBox Staging 0.82.2; the game itself uses standard DOS/BIOS/VGA interfaces.

Controls retain the original project's keyboard behavior: A/D or Left/Right move; Space throws one cleaver projectile; Escape quits. At the menu, 1/P/Space starts and 2/Q/Escape quits. At game over or victory, R/Space restarts and Q/Escape quits. Movement/fire use BIOS buffered key events and the OS's repeat behavior; this is not a simultaneous held-key input system.

The arena is always 80 columns x 25 rows. Row zero contains the HUD; enemies occupy logical rows 2-24. Resizing the host DOSBox window scales the emulated screen and never changes enemy positions or hitboxes. There are no native Windows client-area or pixel calculations in gameplay.

## Build and execute the tests

Install NASM on the host, or point to its executable. From this source folder:

```powershell
.\build.ps1
.\build.ps1 -Test
.\build.ps1 -Test -Core dynamic
```

On another machine:

```powershell
.\build.ps1 -NasmPath 'C:\tools\nasm.exe' -Test -DosBoxPath 'C:\tools\dosbox-staging\dosbox.exe'
```

`build.bat` also retains the original simple build, provided NASM is on PATH:

```text
nasm -f bin main.asm -o INVADERS.COM
```

The PowerShell script additionally treats assembler warnings as errors, excludes NASM 3's opt-in relocation diagnostics for normally resolved COM addresses, checks the COM size budget and can run `TEST.COM` inside DOSBox Staging. It checks a fresh test status file rather than treating the emulator's exit code as the DOS program's result. A normal core/386 configuration is generated under `tests/` without changing the user's primary DOSBox configuration.

Official tools: [NASM](https://www.nasm.us/) and [DOSBox Staging](https://www.dosbox-staging.org/). No linker or Windows SDK is required. The portable assembler used here is a 64-bit host tool; it generates the real-mode COM program independently of its own host architecture.

## Enemy mechanics implemented

The document supports formations, edge descent, varying enemy health/score, enemy attacks, stage progression and a tougher rat boss. It does not assign exact attributes or individual attacks to the five food types. The following values are adopted implementation choices from the agreed plan:

| Enemy | HP | Reward | Behavior |
| --- | ---: | ---: | --- |
| Cupcake Eater Monster | 1 | 10 | Formation movement |
| French Fries Monster | 1 | 10 | Formation movement |
| Burger Eater Monster | 2 | 20 | Tougher formation member |
| Hotdog Madness Monster | 1 | 20 | Formation movement and downward bullets |
| Pizza Goblin Monster | 2 | 30 | Tougher formation member and downward bullets |
| Ratatouille | 20 | 500 | Solo upper-arena patrol and downward bullets; no descent |

Each of stages 1-4 contains two rows of five food enemies. The formation moves one cell horizontally; at an edge it reverses once and descends once, without also moving sideways on that tick. Dead enemies do not affect bounds or attacks. Stage five contains Ratatouille alone; defeating it wins this version.

Regular movement intervals start at 300ms of simulation time and decrease by 20ms per stage. Regular shot intervals start at 1,200ms and decrease by 40ms per stage. Boss movement/shot intervals are 200/900ms. All are counted using 32-bit accumulators in nominal 50ms updates. The unchanged BIOS wait approach adds about 50ms after rendering, so these are simulation timings, not a promise of exact wall-clock timing on every emulator speed.

Shooters are selected round-robin, with an upper enemy blocked by a living enemy below it in the same formation column. Bullets spawn below the sprite, move downward one row every three ticks and leave the pool when off-screen or on player contact. Sixteen hostile slots bound memory use; a full pool skips the next scheduled shot. The player retains one active upward projectile with a 250ms minimum fire interval.

Collision uses each type's actual rectangle (5x3, 7x3 or boss 11x4). Right/bottom edges are exclusive; merely touching edges does not count as overlap. Full rectangular hitboxes include transparent cells. Before/after checks on one-cell projectile steps prevent tunnelling. Each newly defeated enemy awards its score once. Boss HP is reduced across successive hits rather than killed immediately.

Enemy contact, enemy bullets and a bottom breach aggregate into at most one life lost per tick. On a surviving life loss, surviving enemies return to their spawn slots with remaining HP retained, projectiles clear, and the player receives 1,000ms simulation invulnerability. Loss resolves before a simultaneous stage-clear transition. Three lives exhausted means game over. A full restart clears score, stage, enemy arrays, shots, timers and pending events.

## What changed, and why

| File | Change |
| --- | --- |
| `modules/enemy.asm` | Developer 3's core: 32-bit enemy records, initialization, movement, attack decisions, damage and encounter events |
| `modules/collision.asm` | 32-bit bounds/damage calculations across every enemy and hostile projectile; shared type dimensions |
| `variables.inc` | Central DWORD enemy/projectile metadata, counters and timers; original byte player/bullet coordinates retained |
| `modules/bullet.asm` | Hostile projectile pool/movement, original player bullet interface and cooldown |
| `modules/encounter.asm` | Small supporting module for the shared simulation tick, one-life-loss resolution and stages/victory |
| `main.asm` | Normalize ESP, invoke shared simulation, reset new state and show victory; original menu/input architecture retained |
| `modules/display.asm` | Buffered VGA text drawing for all enemies/projectiles and 32-bit scores; clips cells to the shared screen bounds |
| `modules/menu.asm` | Food Invaders menu, instructions and victory/results screen; original menu-input interface retained |
| `assets/enemy_art.inc`, `assets/player_art.inc`, `assets/title_art.inc` | Compact food enemies, rat boss, chef and title |
| `build.ps1`, `run-dosbox.ps1`, `dosbox.conf`, `tests/`, `RUNTEST.BAT` | Host build/run support and actual DOS regression harness |

`modules/player.asm`, `modules/features.asm`, `build.bat`, and unused original assets remain unchanged. Enemy attacks and multiple enemies cannot be displayed or collided correctly through only the original one-enemy renderer/collision interfaces; supporting changes above are explicit. The original missing art/color symbol errors and broken colored-row rendering path no longer block the active build.

The PDF's large ASCII illustrations were reduced to compact silhouettes to fit two enemy rows and the chef in 80x25 text mode. The type names and gameplay roles are retained; the PDF artwork is not reproduced at its original size. This work implements the enemy-focused design, not the report's separate secondary-weapon, power-up, sound, save-game or difficulty-menu features. Those remain future team work.

## Calling and data compatibility

`initialize_enemies`, `update_enemies` and `move_enemies` retain their original names and no-argument call interfaces. `update_enemies` advances one nominal 50ms tick. Enemy procedures preserve EBX, ESI, EDI and EBP; EAX/ECX/EDX and flags may change. `simulate_tick` and rendering entry points preserve all general-purpose registers.

New argument-taking helpers use DWORD arguments with real-mode near calls. CALL pushes a WORD return address, so the first argument is `[esp+2]`, not `[esp+4]`. The caller removes the DWORD arguments. DS/ES must address the program segment; main normalizes ESP from DOS's SP before using stack-relative 32-bit addressing. Example:

```nasm
push dword 1                  ; damage
push dword 4                  ; enemy slot index
call apply_enemy_damage
add esp, 8
; EAX=1 only on a new death; EDX=reward, otherwise both zero.
```

Other helpers are `get_enemy_bounds(index)` (EAX slot pointer / EDX type pointer, zero for invalid/dead), `spawn_enemy_projectile(x,y)` (EAX success flag), `reset_enemy_positions()` and `consume_enemy_events()` (EAX one-shot event bits).

Player/bullet coordinates, lives, flags and game state remain BYTE fields. New calculations zero-extend these before arithmetic and store only the intended byte afterward. Score and current wave are now DWORD fields and must be accessed accordingly. Old `enemy_x`, `enemy_y`, `enemy_alive` names alias slot zero only; `enemies` plus `alive_count` are the authoritative collection. Do not use a slot-zero alias to decide whether the entire formation is alive.

See `TEST-REPORT.md` for executed tests, limitations and the list of files preserved unchanged.
