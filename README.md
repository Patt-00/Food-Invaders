# Food Invaders

[![Build and test](https://github.com/Patt-00/Food-Invaders/actions/workflows/platform-build-test.yml/badge.svg?branch=main)](https://github.com/Patt-00/Food-Invaders/actions/workflows/platform-build-test.yml)
[![Latest release](https://img.shields.io/github/v/release/Patt-00/Food-Invaders)](https://github.com/Patt-00/Food-Invaders/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Food Invaders is a 16-bit NASM arcade game for 386-compatible DOS. Play as the
Chef, dodge food-themed enemies and defend the kitchen with two weapons. It
runs in DOSBox-X and renders the group's colored ASCII art in a 180 × 120
SVGA text field.

The game was built as a group project and takes its arcade idea from Space
Invaders. It has its own Assembly implementation, game rules, and artwork.
The project used [`doctorfree/ninvaders`](https://github.com/doctorfree/ninvaders/tree/dc38ab8db9ecdb5f69fbd3b3deb42e253d6f08c3)
as a playable text-mode reference; Food Invaders does not include its source
code.

## Download and play

Get the latest release from [GitHub Releases](https://github.com/Patt-00/Food-Invaders/releases/latest).
The Windows installer and Linux packages include the game and DOSBox-X, so
you can install and start playing without assembling the source first.

| Platform | Package | Install or launch |
| --- | --- | --- |
| Windows x64 | Unsigned setup installer | Run `Food-Invaders-Setup-1.0.0-x64.exe`, then open Food Invaders from the Start menu. |
| Fedora 44 x86_64 | RPM package | `sudo dnf install ./food-invaders-1.0.0-fedora44-x86_64.rpm` |
| Ubuntu 24.04 x86_64 | DEB package | `sudo apt install ./food-invaders-1.0.0-ubuntu24.04-amd64.deb` |
| Debian 13 x86_64 | DEB package | `sudo apt install ./food-invaders-1.0.0-debian13-amd64.deb` |

See the [installation guide](docs/BUILDING-GUIDE.md) for package details,
source builds, and troubleshooting. DOSBox-X remains under its own GPL
license; the packages include its license and corresponding source.

## Game features

- Four waves with independent enemy movement and firing, followed by a
  20-health Ratatouille boss.
- Easy, Normal, and Hard settings change starting lives and enemy timing.
- Space fires the cleaver; X fires the slower, stronger rolling pin.
- Collect falling fireballs for temporary speed, damage, and rapid-fire boosts.
- Original ASCII designs are rendered at their documented character-cell size.

## Controls

| Key | Action |
| --- | --- |
| A/D or arrow keys | Move the Chef |
| Space | Fire the cleaver; start on Normal in the menu |
| X | Fire the rolling pin |
| 1, 2, or 3 | Start on Easy, Normal, or Hard |
| R | Restart after a result screen |
| Q or Escape | Quit |

## Build from source

Requirements: NASM and DOSBox-X. From the repository root:

```sh
./scripts/build.sh
./run-linux.sh
```

On Termux:X11, install `git`, `nasm`, `dosbox-x`, `termux-x11-nightly`,
`xorg-xdpyinfo`, and `xdotool`, then run `./run-termux.sh`. See the
[Termux guide](docs/TERMUX-INSTALLATION.md). Windows and macOS setup steps are
in the [installation guide](docs/BUILDING-GUIDE.md).

To build and run the Assembly regression suites on DOSBox-X:

```sh
./scripts/build.sh --test --core both
```

PowerShell users can run the same build and tests with
`./scripts/build.ps1 -Test -Core both`. Test binaries and logs go under the
ignored `build/` directory.

## Source layout

| Path | Contents |
| --- | --- |
| `src/` | Game entry point, state, renderer, combat, enemy, and progression modules |
| `tests/` | Assembly regression programs, independent ASCII references, and the optional headless runner |
| `scripts/` | Build, launch, and Windows package scripts |
| `packaging/` | DOSBox-X settings, Windows installer, and Linux package definitions |
| `docs/` | Build and Termux guides, architecture notes, and release notes |

The [development notes](docs/development.md) describe the game loop,
module boundaries, playfield behavior, and test coverage.

## Credits and licensing

Food Invaders was developed as a group project. Contributor credit is shown in
the [GitHub contributors list](https://github.com/Patt-00/Food-Invaders/graphs/contributors).
The project is licensed under [MIT](LICENSE). Bundled third-party software has
separate licenses listed in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
