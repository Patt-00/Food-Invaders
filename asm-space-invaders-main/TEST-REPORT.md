> Historical enemy-branch report: this document describes the pre-merge 80×25 version. See [README.md](README.md) and [MERGE-VALIDATION.md](MERGE-VALIDATION.md) for the integrated 132×120 game and its validation.

# Food Invaders DOSBox implementation and test report

17 October 2026. This report supersedes the earlier native Windows implementation report.

## Baseline and delivered target

The active project was verified against the pre-implementation snapshot before editing. No native Windows source was copied into the original project as an executable platform layer. The old Win32 project and its ZIP are archived separately under `outputs/Superseded-Win32`. `outputs/Original-DOS-Baseline.zip` preserves the source before these DOSBox changes.

The delivered game is `INVADERS.COM`, assembled with `BITS 16`, `CPU 386`, `ORG 100h` and `nasm -f bin`. Its enemy/collision calculations use 32-bit registers, DWORD metadata and 386 operand/address-size prefixes. It is real-mode DOS code using 32-bit calculations; it is not a protected-mode `BITS 32` executable. Player/bullet byte variables are explicitly zero-extended when used in 32-bit calculations.

## Final executed verification

| Check | Result |
| --- | --- |
| NASM 3.01 flat binary assembly, warnings treated as errors except opt-in relocation diagnostics | Passed |
| Game COM size | 8,511 bytes; below the build's 60,000-byte code/data budget |
| Test COM size | 16,610 bytes; below the same budget |
| DOSBox Staging 0.82.2, normal CPU core, cputype 386 | 40,280 assertions passed |
| DOSBox Staging 0.82.2, dynamic CPU core, cputype 386 | 40,280 assertions passed |
| Full five-stage campaign using bullet collision and live simulation path | Passed; score 1,220, three lives retained, final boss defeated |
| Deterministic simulation stress | 20,000 ticks per run; bounds, health, living-slot count and projectile invariants passed |
| Real DOS/BIOS input and output integration | BIOS-enqueued movement, firing and Escape passed; rendered cupcake verified in emulated B800h VGA memory |
| Sprite/HUD/results renderer | Colored cupcake/chef/boss/hostile shot, menu title, game over, victory and 10-digit DWORD score checks passed |
| Rendering memory/register safety | Buffer canaries intact after clipping tests; full EAX/EBX/ECX/EDX preservation checks passed |
| Untouched source interfaces | `player.asm`, `features.asm`, `build.bat`, `assets/variables.inc`, `assets/bullet_art.inc`, `assets/gameover_art.inc` match baseline hashes |

The two successful result files are `tests/normal-result.txt` and `tests/dynamic-result.txt`. These are two runs of the same suite, not 80,560 distinct cases. Tests invoke the actual modules included by `main.asm`; they do not substitute a Python or Windows model for DOS execution.

## Mechanics covered by the regression suite

- Timed horizontal movement, both side turns, one descent per turn, dead-slot exclusion, mixed sprite widths and bottom-breach latching without off-screen coordinates.
- Per-type HP, partial damage, saturating death, invalid/dead targets, one-time score rewards and consumed-once completion events.
- Half-open point/rectangle collision: right/bottom boundaries excluded, interior points included, and mere touching not counted as player contact.
- Player projectile stepping, hostile projectile spawn bounds, pool allocation/saturation, no pool overwrite, shooter round-robin and upper-row blocking.
- Aggregated contact/projectile/breach damage, one life per tick, invulnerability, survivor position/HP reset, clearing shots, last-life game over and no life-count underflow.
- Loss-before-stage-clear ordering, restart initialization, boss-only encounter, boss width/patrol without descent, shot origin, 20-HP defeat, boss completion and final victory.
- Original player movement clamps; real-mode near-call stack balance and representative nonvolatile-register preservation.
- Real BIOS keyboard services, direct text-mode screen presentation, software-cell clipping and DWORD decimal formatting.

## Scope and remaining limits

This implements the enemy-focused Food Invaders design: the five regular food types, Ratatouille, formations, attacks, damage, score, stages and completion. Type-specific stats/roles and the stage-five ending are adopted plan choices; the document does not define all of them precisely. Compact ASCII sprites fit the 80x25 arena rather than reproducing the document's oversized artwork.

The player's secondary weapon, power-up effects, sound, save data and a difficulty-selection menu are not included. `features.asm` remains its original placeholder. Host focus/minimize pause and physical window resizing are handled by DOSBox, not by Windows APIs in the COM program. Nominal timing uses the original BIOS-wait game-loop approach, so rendering/emulator speed can increase wall-clock intervals.

The final binary was executed in DOSBox Staging on the current Windows host. Classic DOSBox 0.74, physical DOS hardware, protected-mode execution and every possible emulator configuration were not tested. A user-desktop DOSBox launch was attempted, but the window became minimized/unavailable before a manual visual session could be completed. Rendering is verified by the actual VGA-memory and screen-content tests above; this is not a claim of a completed manual playthrough.

No test suite proves absolute absence of defects. The preserved original baseline also contained missing art/color symbols and a broken colored-row loop; it is provided as original source, not certified as an independently working legacy build.

## Reproduce

```powershell
.\build.ps1 -Test -Core normal
.\build.ps1 -Test -Core dynamic
```

Supply `-NasmPath` and `-DosBoxPath` on another machine. The test runner checks fresh DOS result/status files, runs without the user's primary DOSBox configuration, and explicitly exits the emulator when done.
