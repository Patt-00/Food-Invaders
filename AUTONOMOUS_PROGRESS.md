# Autonomous progress

## Current state

| Measure | Value |
|---|---|
| Active goal scope | Assembly source and playable DOSBox-X game; DOCX and other course deliverables are excluded. |
| Verified code/game completion | 100% |
| Remaining code/game gap | 0 percentage points |
| Initial completion estimate | 76% |
| Broader project estimate | 84% |
| Broader project gap | 16 percentage points, outside the active scope |
| Repository | `https://github.com/Patt-00/Food-Invaders` |
| Working branch | `main` |
| Published source | Compact character drawings, universal monster firing timers, faster power-ups, and fullscreen output are included in the current main-branch update. |
| Source branch synchronization | NASM and DOSBox-X normal/dynamic checks pass; GitHub `main` was read back after the fullscreen scaling update. |
| Goal status | Complete for the code/game scope. Broader course deliverables remain outside this goal. |

The broader project estimate uses the weighted rubric in `COMPLETION_AUDIT.md`. It includes group, course-document, and presentation requirements that the current code/game goal excludes. The Xvfb captures used a virtual X11 display, not a physical presentation computer, and a human-length campaign was not played.

## Verified work in this cycle

| Date | Work | Verification |
|---|---|---|
| 2026-10-20 | Reworked the main menu to preview the five regular enemies, Ratatouille, Chef, both weapons, and fireball using the existing source artwork. | The live DOSBox-X title screen was captured and inspected. Ten new core assertions check the rendered design cells. |
| 2026-10-20 | Moved the regular enemy bands lower and adjusted the boss's minimum vertical target row. | NASM assembled all five COM files with warnings treated as errors. DOSBox-X 2026.10.01 passed `TEST.COM`, `PBTEST.COM`, and `COLLTEST.COM` on normal and dynamic 386 cores. The core suite passed 40,312 assertions on each core. |
| 2026-10-20 | Added native-size ASCII art and centered score to game-over and victory screens. | Seven new core assertions cover both titles, three artwork cells, and score placement. DOSBox-X normal and dynamic 386 suites each pass with 40,317 core assertions. Interactive `WINTEST.COM` showed the victory renderer after automated campaign simulation; this is not a human playthrough. |
| 2026-10-20 | Expanded hostile-shot collision to the Chef's full 12 by 16 bounds and moved the regular enemy bands to rows 5 and 24, leaving a 30-row gap before the Chef's initial position. | Warning-clean NASM builds passed. DOSBox-X 2026.10.01 passed `TEST.COM`, `PBTEST.COM`, and `COLLTEST.COM` on normal and dynamic 386 cores; `TEST.COM` reported 40,317 assertions each run. The rebuilt game opened in its 1,056 by 704 field. Manual collision timing and spacing review remain open. |
| 2026-10-20 | Restored reachable enemy footer breaches with independent lane-pair descent, preserving randomized individual movement and the 30-row starting gap. | `COLLTEST.COM` now reproduces a lane drop through `simulate_tick`, verifies one life loss, and checks lane-state reset. `TEST.COM`, `PBTEST.COM`, and `COLLTEST.COM` pass on normal and dynamic 386 cores. Xvfb captures 18 seconds apart show staggered lane drops and hostile shots. |
| 2026-10-20 | Completed the code/game-only runtime check. | DOSBox-X in a 1920 by 1080 Xvfb display showed the full menu and gameplay. Keyboard input moved the Chef and fired both weapons. A Hard-mode run showed hostile shots, life loss, Game Over, restart, and Escape exit. `WINTEST.COM` showed victory after its full campaign simulation and reported PASS for 40,317 assertions. |
| 2026-10-20 | Updated the presentation verification slide to match the current test count. | Artifact Tool finalization passed on the revised deck. LibreOffice 26.2.6.3 imported it and rendered ten pages; the updated verification slide was inspected at full size. |
| 2026-10-20 | Audited the actual CS 003 requirements and the current group report without editing the Google Doc. | Read-only Google Drive review identified old screen dimensions and test counts, blank Appendix C, missing Appendix D evidence, pending library reference, and group review items. |
| 2026-10-20 | Added the weighted completion audit and presentation-readiness guide. | `COMPLETION_AUDIT.md` assigns status, points, evidence, remaining work, and priority to project-specific requirements. |
| 2026-10-20 | Created a ten-slide editable PowerPoint with presenter notes. | Artifact Tool finalization passed package integrity, layout geometry, font policy, and first-party import checks. LibreOffice 26.2.6.3 imported the deck and rendered ten PDF pages; all ten were inspected at full size. Slide 9 was corrected after the first visual review. |
| 2026-10-24 | Redrew compact ASCII characters with identifying details, armed every monster with an independent random firing timer, sped up falling power-ups, and set DOSBox-X to full-screen 3:2 output. | NASM built all four COM files. Headless suites pass; DOSBox-X normal and dynamic 386 suites each pass with 43,538 core assertions. A windowed DOSBox-X preview shows the compact art. Fullscreen Xvfb capture was blank, so review the fullscreen appearance on the presentation display. |

## Broader project backlog outside the active code/game goal

| Priority | Task | Owner or dependency | Status |
|---|---|---|---|
| High | Review and approve the title, gameplay, and result-screen proportions on the presentation computer. | User and group | Outside the code/game goal |
| High | Reconcile duplicate Chapter 5 tabs, document current 132 by 88 dimensions and 43,538 assertions, correct the INT 10h and B800h explanation, and replace old screenshots. | Group approval; document was left unchanged | Open |
| High | Add the Appendix C simulation link and Appendix D contribution proof. | Group members | Open |
| High | Visit the TIP library and add the required book reference. | Group | Pending according to the course document |
| High | Confirm each member's actual code contribution, AI disclosure, speaker assignment, and sign-off. | Group members | Open |
| High | Confirm and cite the original-game or source-code references used by the group. | Group confirmation and source details | Open |
| High | Rehearse the full live demonstration on the presentation computer. | Group and target device | Open |
| High | Review the ten-slide deck in PowerPoint or Google Slides. | Group | Open |
| Medium | Run the Windows PowerShell and Termux launchers on their target platforms if the group intends to use them. | Target devices | Unverified |
| Medium | Play a complete human campaign and a game-over path outside the automated harness. | DOSBox-X presentation setup | Not yet performed |

No further speculative gameplay feature is scheduled. The remaining 18 points depend on the documented course submission, group confirmation, or target-platform rehearsal. The Google Doc remains read-only under the earlier instruction not to modify it.
