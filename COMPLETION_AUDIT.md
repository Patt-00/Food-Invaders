# Completion audit

## Current estimate

**Current completion: 84%**

**Target completion: 100%**

**Remaining gap: 16 percentage points**

This estimate measures verified work against the CS 003 project requirements and the current repository. It does not represent a grade. The project is an offline, single-player DOS game, so authentication, user roles, network services, and database persistence do not apply and do not reduce the score.

The calculation assigns points to measurable requirements inside six weighted categories. A point counts only when source, test output, or a live observation supports it. The reports in `tests/integrated-normal-result.txt`, `tests/integrated-dynamic-result.txt`, and `tests/integrated-binary-hashes.json` are the test evidence for the current source revision.

| Category | Weight | Verified points | Evidence summary |
|---|---:|---:|---|
| Functional completeness | 35 | 35 | The three DOSBox-X suites pass on normal and dynamic 386 cores. The core suite verifies the five-stage campaign, game state, controls, enemies, weapons, boosts, and results. |
| UI and UX | 15 | 12 | All ten source designs render at native cell sizes, including on the revised menu and result screens. The current custom viewport works in DOSBox-X. The group has not accepted the updated proportions. |
| Technical reliability | 20 | 16 | NASM builds all five COM files below the 60,000-byte limit. DOSBox-X runs the game and suites. Windows and Termux launchers have not been run on those platforms. |
| Repository completeness | 10 | 7 | The correct Patt-00 repository and `main` branch are synchronized. Local setup documentation is updated. The course document still contains stale evidence and incomplete required appendices. |
| Testing and quality assurance | 10 | 9 | The core, player/weapon, and collision suites pass on both DOSBox-X CPU cores. A live menu, start, movement, and weapon input were also observed. A full manual campaign was not completed. |
| Presentation readiness | 10 | 5 | A ten-slide deck and demonstration plan are prepared. Group review, contribution confirmation, final course-document evidence, and a full rehearsal remain open. |
| **Total** | **100** | **82** | **18 points remain open.** |

## Weighted requirements

The sub-requirements below sum to each category's assigned weight.

| Requirement | Current state | Points | Evidence | Remaining work | Priority |
|---|---|---:|---|---|---|
| Menu, keyboard polling, valid controls, ignored keys, restart, and quit | COMPLETE AND VERIFIED | 7 / 7 | `main.asm`, `modules/menu.asm`, `tests/core.asm`, `tests/integrated-normal-result.txt`, `tests/integrated-dynamic-result.txt`; a live start input reached gameplay. | None identified in the tested path. | Low |
| Chef movement, both weapons, fireball effects, lives, and score | COMPLETE AND VERIFIED | 7 / 7 | `modules/player.asm`, `modules/bullet.asm`, `modules/features.asm`, `tests/player-bullet.asm`; suite passes on both CPU cores. | None identified in the tested path. | Low |
| Independent enemy movement and firing, collision, invulnerability, and life-loss aggregation | COMPLETE AND VERIFIED | 7 / 7 | `modules/enemy.asm`, `modules/collision.asm`, `modules/encounter.asm`, core and collision suite outputs. Live gameplay showed independently moving enemies and hostile shots. | None identified in the tested path. | Low |
| Difficulty, four regular stages, boss stage, victory, defeat, restart, and state reset | COMPLETE AND VERIFIED | 9 / 9 | `main.asm`, `modules/menu.asm`, `modules/encounter.asm`, five-stage campaign assertions in `tests/core.asm`. | A full human playthrough to victory and game over remains presentation QA, not a code-path test gap. | Medium |
| Meaningful Space Invaders modification using offline Assembly and DOSBox-X | COMPLETE AND VERIFIED | 5 / 5 | NASM 16-bit real-mode `.COM` source, dual weapons, timed power-ups, difficulty levels, randomized enemies, stage progression, and the Ratatouille boss. | None identified for the stated course option. | Low |
| Full-size ASCII artwork and title-screen preview | COMPLETE AND VERIFIED | 4 / 4 | `assets/`, `modules/display.asm`, `modules/menu.asm`, and ten new menu-render assertions in `tests/core.asm`; the live title screen was captured. | Group should review the current screen before submission. | Medium |
| 132 by 88 viewport and vertical game composition | IMPLEMENTED BUT UNVERIFIED | 3 / 6 | `variables.inc`, `modules/display.asm`, and the live DOSBox-X screenshot show a 1,056 by 704 field. Enemy bands now start at rows 5 and 32. | The user and group have not accepted the revised proportions. | High |
| HUD, instructions, result screens, and visual feedback | COMPLETE AND VERIFIED | 4 / 4 | Menu instructions, gameplay HUD, and both result-state code paths are covered by core assertions. `WINTEST.COM` displayed the victory artwork, title, score, and restart hints in DOSBox-X after the automated campaign simulation. | The group still needs to review the updated screen proportions and HUD. Add screenshots to the course document after the group reviews them. | Medium |
| Single supported DOS text mode | COMPLETE AND VERIFIED | 1 / 1 | The course project targets an offline emulator. DOSBox-X displays the single configured 132 by 88 mode. | No second display size is specified by the project requirements. | Low |
| Warning-clean NASM builds and COM size limit | COMPLETE AND VERIFIED | 6 / 6 | `nasm -f bin -Wall -w-reloc -Werror` built `INVADERS.COM`, `TEST.COM`, `PBTEST.COM`, `COLLTEST.COM`, and `WINTEST.COM`. Current sizes are below 60,000 bytes. | Run the documented PowerShell wrapper on Windows if Windows is a submission target. | Low |
| DOSBox-X SVGA S3 startup and current interactive build | COMPLETE AND VERIFIED | 4 / 4 | DOSBox-X 2026.10.01 launched the game in `dosbox.conf`; the live title and gameplay screens were observed. | Recheck on the actual presentation computer. | Medium |
| Memory safety, calling conventions, register preservation, stress, and artwork checks | COMPLETE AND VERIFIED | 5 / 5 | `tests/core.asm`, `tests/player-bullet.asm`, `tests/collision.asm`, and 40,317 core assertions on each CPU core. | None identified in the automated suites. | Low |
| Windows and Termux launchers | IMPLEMENTED BUT UNVERIFIED | 0 / 3 | `run-dosbox.ps1` and `run-termux.sh` exist. `run-termux.sh` passed shell syntax validation before this audit, but no platform launch was observed. | Test on an approved Windows or Termux device if the group plans to use those launchers. | Medium |
| Runtime failure handling and measured performance | PARTIALLY IMPLEMENTED | 1 / 2 | Unsupported video mode exits with an error. The test suite runs 20,000 simulation ticks. | No measured frame-time or performance budget is documented. | Low |
| Correct repository, remote owner, and synchronized `main` branch | COMPLETE AND VERIFIED | 3 / 3 | `origin` is `https://github.com/Patt-00/asm-space-invaders.git`; the verified source revision is pushed to `main`. | None after the final push check. | Low |
| Source files, setup files, ignore rules, and secret scan | COMPLETE AND VERIFIED | 3 / 3 | Repository contains source, artwork, build scripts, DOSBox-X config, and tests. `.gitignore` excludes generated COM and logs. No credential-like files or secret patterns were found in the audit scan. | Re-run the scan on the final commit. | Low |
| Repository README and current test instructions | PARTIALLY IMPLEMENTED | 1 / 2 | Root and source READMEs describe build, controls, architecture, and emulator requirements. `MERGE-VALIDATION.md` records current DOSBox-X tests. | The Windows and Termux launch steps remain unverified on their target systems. | Medium |
| Course document, screenshots, and required appendices | BROKEN | 0 / 2 | Duplicate Chapter 5 tabs contain 40,285 and 40,296-assertion claims, `CORETEST.COM`, a DOSBox Staging capture, and 132 by 120 pixels. Current source uses `TEST.COM`, passes 40,317 assertions, and uses 132 by 88. The output description says INT 10h draws the screen; current rendering copies a back buffer to B800h. Appendix C has no link, Appendix D proof cells are blank, and the library reference is pending. | Update and visually verify the course document after explicit approval. Confirm which original-game or code sources need citations. The current instruction is to leave that Google Doc unchanged. | High |
| DOSBox-X normal and dynamic core test suites | COMPLETE AND VERIFIED | 6 / 6 | `RUNTEST.BAT` passed under DOSBox-X 2026.10.01 on normal and dynamic 386 cores. `TEST.COM` reports 40,317 assertions; `PBTEST.COM` and `COLLTEST.COM` report PASS. | None for automated suites on this host. | Low |
| Automated campaign, stress, art, collision, and player coverage | COMPLETE AND VERIFIED | 2 / 2 | Core suite covers 20,000 simulation ticks, the five-stage campaign, and rendered ASCII cells. Player and collision suites cover their named APIs and edge cases. | None identified in current suite scope. | Low |
| Manual end-to-end playthrough | PARTIALLY IMPLEMENTED | 1 / 2 | Live DOSBox-X launch, start, movement, and firing were observed. | Play through a full campaign and a game-over case on the presentation setup. | High |
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
- [x] The presentation deck reflects the current 40,317-assertion test result.
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

1. The course document is incomplete and stale. Duplicate Chapter 5 tabs contain 40,285 and 40,296-assertion claims, refer to `CORETEST.COM` and DOSBox Staging, and show 132 by 120. The current source uses `TEST.COM`, passes 40,317 assertions, and uses 132 by 88. The output-flow explanation also needs to distinguish INT 10h video initialization from the B800h frame copy. Appendix C has no link, Appendix D proof cells are empty, and the library reference is pending. The user previously asked not to edit that document. This audit leaves it unchanged.
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
