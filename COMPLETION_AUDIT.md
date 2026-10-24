# Completion audit

## Active code and game scope

The active goal covers the Assembly source and the playable DOSBox-X game. It excludes the DOCX and other course, group, and presentation deliverables.

**Code and game completion: 100%**

**Remaining code and game gap: none identified**

| Acceptance item | Current state | Evidence |
|---|---|---|
| Warning-clean build and COM size budget | COMPLETE AND VERIFIED | NASM built `INVADERS.COM`, `TEST.COM`, `PBTEST.COM`, `COLLTEST.COM`, and `WINTEST.COM` with `-Wall -w-reloc -Werror`; every binary is below 60,000 bytes. |
| Automated game logic and campaign | COMPLETE AND VERIFIED | DOSBox-X 2026.10.01 passed `TEST.COM`, `PBTEST.COM`, and `COLLTEST.COM` on normal and dynamic 386 cores. `TEST.COM` reports 43,538 assertions, including the five-stage campaign and 20,000 simulation ticks. |
| DOSBox-X launch and visible gameplay | COMPLETE AND VERIFIED | A DOSBox-X windowed preview shows the full menu and gameplay with compact ASCII redraws. The fullscreen setting and 3:2 aspect ratio are enabled in the launch config. |
| Input, weapons, incoming fire, and player loss | COMPLETE AND VERIFIED | A DOSBox-X play session selected Normal and Hard, moved the Chef, fired both weapons, displayed hostile shots, reduced lives on a hit, showed Game Over, restarted with `R`, and quit with Escape. |
| Enemy spacing and breach behavior | COMPLETE AND VERIFIED | Enemies spawn across the playfield, roam on independent random vectors, keep two-cell clearance, and stop at the safe line eight rows above the Chef. `tests/core.asm` checks their bounds and spacing; `tests/collision.asm` verifies one-life breach resolution and reset behavior. |
| Victory and result screens | COMPLETE AND VERIFIED | `TEST.COM` completes the five-stage campaign and verifies the victory state with 43,538 assertions. The game-over result path is also covered by the campaign and player/collision tests. |

The full campaign was verified by the real-mode simulation, not a human-length playthrough. The virtual DOSBox-X run covered the menu, controls, weapons, hostile hits, game over, restart, and quit. No source or game blocker remains within the active scope.

## Broader project estimate

**Broader project completion: 84%**

**Target completion: 100%**

**Remaining gap: 16 percentage points**

This estimate measures the full CS 003 project, including course documents, group confirmation, and presentation readiness. Those deliverables are outside the active code and game goal. The score does not represent a grade. The project is an offline, single-player DOS game, so authentication, user roles, network services, and database persistence do not apply and do not reduce the score.

The calculation assigns points to measurable requirements inside six weighted categories. A point counts only when source, test output, or a live observation supports it. The reports in `tests/integrated-normal-result.txt`, `tests/integrated-dynamic-result.txt`, and `tests/integrated-binary-hashes.json` are the test evidence for the current source revision.

| Category | Weight | Verified points | Evidence summary |
|---|---:|---:|---|
| Functional completeness | 35 | 35 | The three DOSBox-X suites pass on normal and dynamic 386 cores. The core suite verifies the five-stage campaign, game state, controls, enemies, weapons, boosts, and results. |
| UI and UX | 15 | 12 | All ten source designs render at native cell sizes, including on the revised menu and result screens. The current custom viewport works in DOSBox-X. The group has not accepted the updated proportions. |
| Technical reliability | 20 | 16 | NASM builds all five COM files below the 60,000-byte limit. DOSBox-X runs the game and suites. Windows and Termux launchers have not been run on those platforms. |
| Repository completeness | 10 | 7 | The correct Patt-00 repository and `main` branch are synchronized. Local setup documentation is updated. The course document still contains stale evidence and incomplete required appendices. |
| Testing and quality assurance | 10 | 9 | The core, player/weapon, and collision suites pass on both DOSBox-X CPU cores. A live menu, start, movement, and weapon input were also observed. A full manual campaign was not completed. |
| Presentation readiness | 10 | 5 | A ten-slide deck and demonstration plan are prepared. Group review, contribution confirmation, final course-document evidence, and a full rehearsal remain open. |
| **Total** | **100** | **84** | **16 points remain open.** |

## Weighted requirements

The sub-requirements below sum to each category's assigned weight.

| Requirement | Current state | Points | Evidence | Remaining work | Priority |
|---|---|---:|---|---|---|
| Menu, keyboard polling, valid controls, ignored keys, restart, and quit | COMPLETE AND VERIFIED | 7 / 7 | `main.asm`, `modules/menu.asm`, `tests/core.asm`, `tests/integrated-normal-result.txt`, `tests/integrated-dynamic-result.txt`; a live start input reached gameplay. | None identified in the tested path. | Low |
| Chef movement, both weapons, fireball effects, lives, and score | COMPLETE AND VERIFIED | 7 / 7 | `modules/player.asm`, `modules/bullet.asm`, `modules/features.asm`, `tests/player-bullet.asm`; suite passes on both CPU cores. | None identified in the tested path. | Low |
| Independent enemy movement and firing, collision, invulnerability, and life-loss aggregation | COMPLETE AND VERIFIED | 7 / 7 | `modules/enemy.asm`, `modules/collision.asm`, `modules/encounter.asm`, and both DOSBox-X suite outputs. Tests verify random movement, two-cell clearance, first-overlap head hits, half-open edges, safe-line breach, and one-life resolution. | None identified in the tested collision paths. | Low |
| Difficulty, four regular stages, boss stage, victory, defeat, restart, and state reset | COMPLETE AND VERIFIED | 9 / 9 | `main.asm`, `modules/menu.asm`, `modules/encounter.asm`, five-stage campaign assertions in `tests/core.asm`. | A full human playthrough to victory and game over remains presentation QA, not a code-path test gap. | Medium |
| Meaningful Space Invaders modification using offline Assembly and DOSBox-X | COMPLETE AND VERIFIED | 5 / 5 | NASM 16-bit real-mode `.COM` source, dual weapons, timed power-ups, difficulty levels, randomized enemies, stage progression, and the Ratatouille boss. | None identified for the stated course option. | Low |
| Compact ASCII artwork and title-screen preview | COMPLETE AND VERIFIED | 4 / 4 | Compact redraws retain the Chef's hat and face, food-enemy eyes and layers, and pickup face and trail. Core and player tests compare each rendered cell with independent compact references. | None identified in the tested render paths. | Medium |
| Full-screen 132 by 88 board and character proportions | IMPLEMENTED BUT UNVERIFIED | 3 / 6 | `dosbox.conf` and `run-termux.sh` request full-screen output with a 3:2 aspect ratio. The game retains its 132 by 88 logical board and uses smaller entity bounds. DOSBox-X normal and dynamic core suites pass. | Review full-screen presentation on the group's actual display. | High |
| HUD, instructions, result screens, and visual feedback | COMPLETE AND VERIFIED | 4 / 4 | Menu instructions, gameplay HUD, and both result-state code paths are covered by core assertions. `WINTEST.COM` displayed the victory artwork, title, score, and restart hints in DOSBox-X after the automated campaign simulation. | The group still needs to review the updated screen proportions and HUD. Add screenshots to the course document after the group reviews them. | Medium |
| Single supported DOS text mode | COMPLETE AND VERIFIED | 1 / 1 | The course project targets an offline emulator. DOSBox-X displays the single configured 132 by 88 mode. | No second display size is specified by the project requirements. | Low |
| Warning-clean NASM builds and COM size limit | COMPLETE AND VERIFIED | 6 / 6 | `nasm -f bin -Wall -w-reloc -Werror` built `INVADERS.COM`, `TEST.COM`, `PBTEST.COM`, `COLLTEST.COM`, and `WINTEST.COM`. Current sizes are below 60,000 bytes. | Run the documented PowerShell wrapper on Windows if Windows is a submission target. | Low |
| DOSBox-X SVGA S3 startup and current interactive build | IMPLEMENTED BUT UNVERIFIED | 3 / 4 | DOSBox-X 2026.10.01 passes the test suites using the fullscreen 3:2 config; the compact artwork was visually checked in a windowed preview. | Review the fullscreen output on the presentation display. | Medium |
| Memory safety, calling conventions, register preservation, stress, and artwork checks | COMPLETE AND VERIFIED | 5 / 5 | `tests/core.asm`, `tests/player-bullet.asm`, `tests/collision.asm`, and 43,538 core assertions on each CPU core. | None identified in the automated suites. | Low |
| Windows and Termux launchers | IMPLEMENTED BUT UNVERIFIED | 0 / 3 | `run-dosbox.ps1` and `run-termux.sh` exist. `run-termux.sh` passed shell syntax validation before this audit, but no platform launch was observed. | Test on an approved Windows or Termux device if the group plans to use those launchers. | Medium |
| Runtime failure handling and measured performance | PARTIALLY IMPLEMENTED | 1 / 2 | Unsupported video mode exits with an error. The test suite runs 20,000 simulation ticks. | No measured frame-time or performance budget is documented. | Low |
| Correct repository, remote owner, and synchronized `main` branch | COMPLETE AND VERIFIED | 3 / 3 | `origin` is `https://github.com/Patt-00/asm-space-invaders.git`; the verified source revision is pushed to `main`. | None after the final push check. | Low |
| Source files, setup files, ignore rules, and secret scan | COMPLETE AND VERIFIED | 3 / 3 | Repository contains source, artwork, build scripts, DOSBox-X config, and tests. `.gitignore` excludes generated COM and logs. No credential-like files or secret patterns were found in the audit scan. | Re-run the scan on the final commit. | Low |
| Repository README and current test instructions | PARTIALLY IMPLEMENTED | 1 / 2 | Root and source READMEs describe build, controls, architecture, and emulator requirements. `MERGE-VALIDATION.md` records current DOSBox-X tests. | The Windows and Termux launch steps remain unverified on their target systems. | Medium |
| Course document, screenshots, and required appendices | BROKEN | 0 / 2 | Duplicate Chapter 5 tabs contain older assertion claims, `CORETEST.COM`, a DOSBox Staging capture, and 132 by 120 pixels. Current source uses `TEST.COM`, passes 43,538 assertions, and uses a 132 by 88 board with compact artwork. The output description says INT 10h draws the screen; current rendering copies a back buffer to B800h. Appendix C has no link, Appendix D proof cells are blank, and the library reference is pending. | Update and visually verify the course document after explicit approval. Confirm which original-game or code sources need citations. The current instruction is to leave that Google Doc unchanged. | High |
| DOSBox-X normal and dynamic core test suites | COMPLETE AND VERIFIED | 6 / 6 | `RUNTEST.BAT` passed under DOSBox-X 2026.10.01 on normal and dynamic 386 cores with fullscreen enabled. `TEST.COM` reports 43,538 assertions; `PBTEST.COM` and `COLLTEST.COM` report PASS. | None for automated suites on this host. | Low |
| Automated campaign, stress, art, collision, and player coverage | COMPLETE AND VERIFIED | 2 / 2 | Core suite covers 20,000 simulation ticks, the five-stage campaign, and rendered ASCII cells. Player and collision suites cover their named APIs and edge cases. | None identified in current suite scope. | Low |
| Manual end-to-end playthrough | PARTIALLY IMPLEMENTED | 1 / 2 | Xvfb DOSBox-X interaction covered menu selection, movement, both weapons, hostile damage, game over, restart, and quit. `TEST.COM` and `WINTEST.COM` cover the full five-stage campaign and victory. | A human-length campaign on the presentation computer has not been played. | High |
| Ten-slide presentation and speaker notes | IMPLEMENTED BUT UNVERIFIED | 3 / 4 | The [editable presentation deck](presentation/Food-Invaders-Final-Presentation-v2.pptx) contains ten slides and presenter notes. Artifact Tool checks passed, and LibreOffice 26.2.6.3 imported the deck and rendered a ten-page PDF that was visually inspected. | Have the group review facts and slide assignments. Open the deck in the target PowerPoint or Google Slides application before delivery. | High |
| Demo requirements, sequence, and fallback | COMPLETE AND VERIFIED | 2 / 2 | `PRESENTATION_READINESS.md` documents build/run commands, controls, demo sequence, risks, and a clearly labeled non-live fallback. | Rehearse on the presentation computer. | High |
| Member participation and actual code contributions | BLOCKED | 0 / 2 | The course document lists six report-section assignments, but proof cells are blank. Those assignments do not establish each member's code contribution or presentation readiness. | Each member confirms their contribution and speaking part; fill Appendix D with evidence. | High |
| Library reference, report screenshots, AI disclosure, and group sign-off | BLOCKED | 0 / 2 | The course document says the library visit has not happened, lists a pending library-book reference, and says the group must review its AI disclosure. Current course screenshots contain older evidence. | Visit the TIP library, add a cited book, replace stale screenshots, confirm other AI tools, and complete the required signatures. | High |

## 100% completion checklist

- [x] The game implements the documented core mechanics and meaningful modifications.
- [x] The game builds with NASM and stays below the COM size budget.
- [x] The core, player/weapon, and collision suites pass on both DOSBox-X CPU cores.
- [x] The current game launches in DOSBox-X with the required SVGA S3 mode.
- [x] Game-over and victory result artwork, score, and restart instructions render in DOSBox-X test mode.
- [ ] The presentation deck reflects the current 43,538-assertion test result.
- [x] The README documents the build, controls, architecture, and test commands.
- [x] The verified source and current audit assets are synchronized to the Patt-00 GitHub `main` branch.
- [ ] The user and group approve the current menu and gameplay proportions.
- [ ] The group completes a full human campaign and game-over rehearsal on the presentation computer.
- [ ] The course document reflects the 132 by 88 screen, current tests, and current screenshots.
- [ ] Appendix C contains the simulation link and Appendix D contains confirmed contributions and proof.
- [ ] The group visits the TIP library and adds the required book reference.
- [ ] The group confirms the AI disclosure, each member's contribution, and speaking assignments.
- [ ] The group opens the editable deck in the target presentation application and approves all ten slides.
- [ ] Windows or Termux launchers pass a live test if the group will use them.

## Exact gaps preventing 100%

1. The course document is incomplete and stale. Duplicate Chapter 5 tabs contain older assertion claims, refer to `CORETEST.COM` and DOSBox Staging, and show 132 by 120. The current source uses `TEST.COM`, passes 43,538 assertions, and uses 132 by 88 with compact artwork. The output-flow explanation also needs to distinguish INT 10h video initialization from the B800h frame copy. Appendix C has no link, Appendix D proof cells are empty, and the library reference is pending. The user previously asked not to edit that document. This audit leaves it unchanged.
2. The required library visit and book reference remain pending according to the course document.
3. Group members have not confirmed their software contributions, disclosure, speaking roles, or final deck. The group must also confirm which source-code or original-game references were used and cite them as the instructor requires.
4. No group rehearsal or full human game campaign has been observed.
5. The user has not reviewed the new menu and game proportions.
6. Windows and Termux launch scripts have not been run on those target platforms.

## Evidence and sources

- Current gameplay and test implementation: `asm-space-invaders-main/main.asm`, `modules/`, `variables.inc`, `assets/`, and `tests/`.
- Current DOSBox-X results: `asm-space-invaders-main/tests/integrated-normal-result.txt`, `tests/integrated-dynamic-result.txt`, and `tests/integrated-binary-hashes.json`.
- Course requirements: [CS 003 final project requirements](https://docs.google.com/document/d/1vrURwJA0NXsWRs2CJFa2_cXt4Qz9jFLCCF0J97HvPz4).
- Project report reviewed read-only: [Food Invaders group document](https://docs.google.com/document/d/12_c8mBJUFdmfvfFPC60TDtMRk0SBgZ7B6iHOYjvszec).
