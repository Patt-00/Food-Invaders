# Presentation readiness

## Application overview

Food Invaders is a single-player Assembly game based on the Space Invaders concept. A Chef defends the kitchen from five food enemies and Ratatouille. The game runs offline in DOSBox-X and renders the team's colored ASCII designs in text mode.

The project modifies the Space Invaders game loop with independently moving enemies, individual enemy firing timers, two weapons, three difficulty settings, falling power-ups, four regular stages, and a final boss. These changes affect gameplay rather than only its theme.

The intended users are the CS 003 project group and classmates who can play the game with a keyboard. The player moves the Chef, avoids hostile projectiles, fires at enemies, collects temporary boosts, and tries to defeat the final boss.

## Technical architecture

| Area | Current implementation |
|---|---|
| Language and format | NASM Assembly, 16-bit real-mode DOS `.COM`; 386 instructions support DWORD game calculations. |
| Runtime | DOSBox-X with `machine=svga_s3`; the game configures a 132 by 88 character display. |
| Display | The game draws colored ASCII cells into a memory back buffer, then copies the frame to text memory at `B800h`. `INT 10h` initializes video mode and text services. |
| Input | `INT 16h` checks the keyboard buffer. `main.asm` accepts only assigned keys and ignores other keys while play continues. |
| State | `variables.inc` defines shared screen, player, enemy, weapon, difficulty, stage, and power-up state. |
| Gameplay modules | `modules/player.asm`, `bullet.asm`, `enemy.asm`, `collision.asm`, `encounter.asm`, and `features.asm` update the simulation. |
| Rendering and screens | `modules/display.asm` draws the HUD and 132 by 88 game field. `modules/menu.asm` draws the title, ASCII preview, game-over, and victory screens. DOSBox-X launches full-screen; compact ASCII redraws retain each character's identifying features. |
| External services | None. The game does not use authentication, a server, a database, or a network connection. |

Each game iteration polls input, updates state and timers, resolves collisions and stage events, draws the ASCII frame, and waits about 50 milliseconds before the next iteration. The five-stage campaign clears four food-enemy stages before presenting the 20-HP Ratatouille boss.

## Demonstration sequence

The group can use this sequence for the live demonstration. The final item takes longer than the other steps, so rehearse the full campaign before deciding whether to show it live.

1. Launch DOSBox-X with the repository's `dosbox.conf`. Show the title screen, the ten ASCII previews, the controls, and the difficulty choices.
2. Press `2` to start Normal mode, or press `1` if the group wants five starting lives for the presentation.
3. Press `A` or `D` to move the Chef. Use the arrow keys if preferred.
4. Press Space to fire a cleaver. Press `X` to fire the slower rolling pin. Point out the HUD cooldown after a shot.
5. Wait for enemies to move and fire independently. Defeat enemies to show score changes. A defeated enemy has a one-in-four chance to drop a fireball when no pickup is active.
6. Catch a fireball if one appears. Explain the temporary speed, damage, or rapid-fire effect shown by the HUD. Do not claim to demonstrate a boost if a pickup did not appear during the run.
7. Continue through four stages and defeat Ratatouille on stage five if the presentation slot allows a full campaign.
8. Show the victory result. If the Chef loses all lives first, show the game-over screen and explain how to restart or quit.

## Demo requirements

### Accounts and services

No account, internet access, backend, or external service is required. The group needs a keyboard and a DOSBox-X build that supports the configured SVGA S3 text mode.

### Build and launch

From the source directory, assemble the game with NASM:

```sh
cd asm-space-invaders-main
nasm -f bin -Wall -w-reloc -Werror main.asm -o INVADERS.COM
```

Start DOSBox-X with the source directory as its working directory and `dosbox.conf` as the configuration. The config mounts the directory and starts `INVADERS.COM`. The repository also contains `run-dosbox.ps1` for Windows and `../run-termux.sh` for Termux X11.

The current host ran DOSBox-X 2026.10.01 with a 386 CPU and SVGA S3 mode. The PowerShell launcher was not run on Windows, and the Termux launcher was not run on a Termux device. Check those paths on the presentation computer before choosing them.

### Expected results

| Step | Expected result |
|---|---|
| Launch | DOSBox-X opens full-screen with the compact ASCII roster and instructions. The field keeps a 3:2 aspect ratio. |
| Start | The selected difficulty sets the starting lives and enemy timing. |
| Move and fire | The Chef moves within the field. Space fires a cleaver; `X` fires a rolling pin. |
| Defeat enemies | Score increases, enemies move and fire on separate timers, and a fireball may fall. |
| Finish the campaign | Clearing four regular stages starts the Ratatouille boss stage. Defeating its 20 HP produces a victory result. |
| Lose all lives | The game shows its game-over result and accepts restart or quit input. |

## Proposed speaker assignments

The project document's task table lists the report sections below. It does not prove each person's code contribution or confirm that the assigned section is complete. The group should confirm each speaker, their current work, and the slides they will present before submission.

| Member listed in the project document | Listed report assignment | Proposed presentation section |
|---|---|---|
| Dela Torre, Princess M. | Project overview; input, output, and control flow | Overview and game loop |
| Nera, Stephen Jarcelle D. | Design choices; original game versus modification; registers and memory | Design choices and Assembly state |
| Ramirez, Jamaimah Janna P. | Project objectives; Assembly instructions | Objectives and code example |
| Sabando, Christianne Denise S. | Game design; Assembly instructions | Rules, features, and code concepts |
| Urbina, Patrick M. | Game rules and mechanics; game features; input, output, and control flow | Controls, mechanics, and player workflow |
| San Jose, Tobiel R. | Game description; architecture concepts | Game concept and architecture |

These roles are proposals based on the existing task table. Members should speak from work they can explain and correct the slide assignments if the team plan changed.

## Presentation risks and fallback

| Risk | Effect | Response |
|---|---|---|
| DOSBox-X or SVGA S3 mode fails on the presentation computer | The game may not open its 132 by 88 screen. | Rebuild and launch on that computer before presenting. Bring the source, NASM build instructions, and current test logs on offline storage. |
| A power-up does not drop during a short demonstration | The group cannot show a temporary boost live. | Explain the one-in-four drop rule and show the passing player-suite result. Identify it as automated evidence rather than live gameplay. |
| The full campaign takes longer than the presentation slot | The audience may not see the final boss and victory in time. | Rehearse a timed run. If there is no time for a complete campaign, show the core live controls and label the five-stage campaign output as automated test evidence. |
| The group has not reviewed the revised game on the presentation computer | Local DOSBox-X testing may not match the target display or the group's preferred spacing. | Run the full-screen 132 by 88 game on the presentation computer. Check the 3:2 board, compact art details, random movement and firing, and head-hit timing before approving the layout. |
| The course report does not match the current build | Duplicate Chapter 5 tabs show different old test counts and an older screen size. The output-flow explanation also needs to match the current B800h renderer. | Update the course document's resolution, current assertion count, screenshots, Appendix C, Appendix D, and library reference after the group approves those edits. Confirm and cite any original-game or source-code references. The current audit has not edited that Google Doc. |
| Speaker roles or contributions are inaccurate | A member may be unable to explain the assigned work. | Each member confirms their completed work and speaking section. Do not present the documentation assignment table as proof of code authorship. |

If DOSBox-X cannot launch during the presentation, show the repository's source and current test logs. State that these logs verify automated Assembly tests, not a live playthrough. A current screenshot is visible in the task conversation, but the group has not saved or approved a backup recording.

## Readiness status

The current code passes the automated DOSBox-X suites on normal and dynamic CPU cores, with 43,538 core assertions per run. Both suites ran with the full-screen 3:2 DOSBox-X preset. A windowed DOSBox-X preview confirms the compact Chef, enemies, weapons, and fireball. The Xvfb fullscreen screenshot was blank, so review the actual fullscreen layout on the presentation display. The collision tests verify the compact hitboxes, but a human play check is still useful. `WINTEST.COM` reports the victory result after its automated campaign simulation; this is not a human playthrough. LibreOffice 26.2.6.3 imported the revised ten-slide deck and rendered a ten-page PDF. I inspected the updated verification slide in that render. The group has not rehearsed the full campaign, confirmed speaking assignments, or updated the course Google Doc. The ten-slide editable deck is [available here](presentation/Food-Invaders-Final-Presentation-v2.pptx). The group still needs to open and approve it in the target PowerPoint or Google Slides application.
