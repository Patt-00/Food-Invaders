# Food Invaders

[![Windows and macOS build tests](https://github.com/Patt-00/Food-Invaders/actions/workflows/platform-build-test.yml/badge.svg?branch=main)](https://github.com/Patt-00/Food-Invaders/actions/workflows/platform-build-test.yml)

Food Invaders is a 16-bit NASM arcade game for 386-compatible real-mode DOS. Play as the Chef and defend the kitchen from food-themed invaders. The game keeps the original colored ASCII art at its source dimensions and displays it in a 180×120 SVGA text field. DOSBox-X runs it full-screen at a 3:2 aspect ratio.

## Game features

- The 180×120 field has 21,600 character cells, about 86% more than a 132×88 field.
- Four waves of randomized food enemies lead to a fifth stage with Ratatouille, a 20 HP boss.
- Enemies move and fire on independent timers, keep four cells apart, and stay above the Chef's eight-row safety line.
- Choose Easy, Normal, or Hard. Use the cleaver, rolling pin, and temporary power-ups.

## Run on Linux

From the repository root, run:

```sh
./run-linux.sh
```

The script builds `INVADERS.COM` from `asm-space-invaders-main/main.asm` and launches DOSBox-X. It uses the native `dosbox-x` command when available, or the DOSBox-X Flatpak. The preset uses `cycles=max`, which can increase CPU use, heat, and battery drain on mobile devices.

## Run on Termux

See the [Termux installation guide](docs/TERMUX-INSTALLATION.md) for app setup, package installation, launch steps, and troubleshooting. Then run this from the repository root:

```sh
./run-termux.sh
```

The game uses DOSBox-X's SVGA S3 mode. The launcher fills the Termux:X11 display while keeping the board's proportions. A text-only Termux session cannot display the game window.

## Run on Windows or macOS

Use the [Windows and macOS building guide](docs/BUILDING-GUIDE.md) to install NASM and DOSBox-X, build the game, and launch it.

## Controls

| Key | Action |
| --- | --- |
| A/D or arrow keys | Move the Chef |
| Space | Fire a cleaver |
| X | Fire a rolling pin |
| 1, 2, or 3 | Start on Easy, Normal, or Hard |
| P or Space | Start on Normal |
| R | Restart after a result screen |
| Q or Escape | Quit |

The campaign has four regular waves and a final Ratatouille boss stage. Enemy positions and firing delays are randomized, and later waves increase the difficulty. Enemy bullets use a single text cell. The fireball power-up falls one row every 50 ms.

## Project details

The project documentation includes:

- [Game details and code structure](asm-space-invaders-main/README.md)
- [Windows and macOS building guide](docs/BUILDING-GUIDE.md)
- [Developer 2 contribution](asm-space-invaders-main/DEVELOPER2.md)
- [Windows and macOS build workflow](.github/workflows/platform-build-test.yml)

The [normal-core result](asm-space-invaders-main/tests/integrated-normal-result.txt) and [dynamic-core result](asm-space-invaders-main/tests/integrated-dynamic-result.txt) record the latest local DOSBox-X regression runs.
