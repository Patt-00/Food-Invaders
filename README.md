# Food Invaders

Food Invaders is a 16-bit NASM game for 386-compatible real-mode DOS. You play as the Chef and defend the kitchen from food-themed invaders with a cleaver and rolling pin. The original ASCII art is displayed in a 156 by 104 SVGA text field. The field has about 40% more character cells than the 132 by 88 version while keeping the artwork at its original dimensions. DOSBox-X launches it full-screen with a 3:2 aspect ratio.

## Run on Linux

Install NASM and DOSBox-X, then run this script from the repository root:

```sh
./run-linux.sh
```

The script builds `INVADERS.COM` from `main.asm` and launches the game. It uses a native `dosbox-x` command when available, or the DOSBox-X Flatpak when installed. The preset uses `cycles=max`, which can increase CPU use, heat, and battery drain on mobile devices.

## Run on Termux

Install NASM and DOSBox-X in Termux. Install the Termux:X11 app and companion package, and make sure `xdpyinfo` is available. Then run:

```sh
./run-termux.sh
```

The game uses DOSBox-X's SVGA S3 mode. Its launcher fills the Termux:X11 display while preserving the board's proportions. A plain text-only Termux session is not enough for the game window.

## Run on Windows or macOS

See the [Windows and macOS building guide](docs/BUILDING-GUIDE.md) for NASM and DOSBox-X installation, build commands, and launch steps.

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

The four regular waves place enemies at random positions across the playfield. Each enemy takes independent random steps on both axes, avoids the others, stays above the Chef's safety line, and can fire on its own random timer. Later waves increase movement and firing speed. A 20 HP Ratatouille boss follows the fourth wave. Enemy bullets use a single text cell; the fireball power-up drops one row every 50 ms.

## Project details

The [game README](asm-space-invaders-main/README.md) covers wave behavior, the playable text-mode reference, module roles, and regression tests. The [Windows and macOS building guide](docs/BUILDING-GUIDE.md) installs prerequisites and walks through building and launching. The [Developer 2 contribution](asm-space-invaders-main/DEVELOPER2.md) describes the player and weapon work.

The [normal-core test result](asm-space-invaders-main/tests/integrated-normal-result.txt) and [dynamic-core test result](asm-space-invaders-main/tests/integrated-dynamic-result.txt) record the latest local DOSBox-X runs.
