# Install, build, and run Food Invaders

Food Invaders is a 16-bit DOS game written in NASM Assembly. It runs inside
DOSBox-X because the game uses its SVGA S3 text mode and VGA memory. Release
packages include DOSBox-X and its corresponding source; a source build needs
NASM and a separate DOSBox-X installation.

## Install a release package

Download the package for your operating system from
[GitHub Releases](https://github.com/Patt-00/Food-Invaders/releases/latest).
The current release package targets x86_64 Windows, Fedora 44, Ubuntu 24.04,
or Debian 13.

### Windows 10 or 11, x64

1. Download `Food-Invaders-Setup-1.0.0-x64.exe` from the release page.
2. Run the installer and choose whether to create a desktop shortcut.
3. Start Food Invaders from the Start menu or desktop shortcut.

The installer is unsigned. It includes the DOSBox-X runtime, DOSBox-X's GPL
license and source archive, and the Food Invaders MIT license.

### Fedora 44, x86_64

```sh
sudo dnf install ./food-invaders-1.0.0-fedora44-x86_64.rpm
food-invaders
```

### Ubuntu 24.04, x86_64

```sh
sudo apt install ./food-invaders-1.0.0-ubuntu24.04-amd64.deb
food-invaders
```

### Debian 13, x86_64

```sh
sudo apt install ./food-invaders-1.0.0-debian13-amd64.deb
food-invaders
```

Each Linux package includes a desktop-menu entry. Packages install the game
under `/opt/food-invaders`, the command at `/usr/bin/food-invaders`, and
license and source files under `/usr/share/doc/food-invaders`.

## Build and run from source

### Linux

Install NASM and DOSBox-X using your distribution's package manager. On Fedora:

```sh
sudo dnf install nasm dosbox-x
```

On Ubuntu or Debian:

```sh
sudo apt install nasm dosbox-x
```

Build and launch from the repository root:

```sh
./scripts/build.sh
./run-linux.sh
```

The executable is written to `build/standard/INVADERS.COM`. The launch script
uses `dosbox-x` from `PATH`, `DOSBOX_X_PATH` if set, or the DOSBox-X Flatpak
when installed.

### Windows

Install NASM 3.02 or later and DOSBox-X. The
[NASM release page](https://www.nasm.us/pub/nasm/releasebuilds/) and
[DOSBox-X download page](https://dosbox-x.com/) provide Windows packages.
Clone or extract this repository, open PowerShell in its root, then run:

```powershell
.\scripts\build.ps1
.\scripts\run-windows.ps1 -DosBoxPath 'C:\Path\To\dosbox-x.exe'
```

If NASM is not on `PATH`, pass its executable path with `-NasmPath`. The
compiled game is in `build\standard\INVADERS.COM`.

### macOS

Install Git, NASM, and DOSBox-X. Homebrew provides NASM and DOSBox-X:

```sh
brew install nasm dosbox-x
```

From the repository root, build the game and launch it:

```sh
./scripts/build.sh
dosbox-x -nopromptfolder -fastlaunch -conf packaging/dosbox/desktop.conf -noautoexec \
  -c 'mount c "build/standard"' -c 'c:' -c 'INVADERS.COM' -c 'exit'
```

If DOSBox-X was installed as an app instead of a command-line package, run its
`Contents/MacOS/dosbox-x` executable with the same arguments.

## Run the automated Assembly suites

Install NASM and DOSBox-X, then run both DOSBox-X CPU cores:

```sh
./scripts/build.sh --test --core both
```

The script assembles the game and four test programs, checks the DOS `.COM`
size limit, then runs the core, player/weapon, and collision suites. Results
and generated `.COM` files are placed in `build/tests/`.

On PowerShell, run:

```powershell
.\scripts\build.ps1 -Test -Core both
```

The GitHub Actions workflow also runs the normal and dynamic core tests on
Windows and macOS. Those tests use DOSBox-X's surface output and do not replace
a manual full-screen play session.

## Controls

| Key | Action |
| --- | --- |
| `1`, `2`, or `3` | Start on Easy, Normal, or Hard |
| `P` or Space | Start on Normal |
| A/D or arrow keys | Move the Chef |
| Space | Fire the cleaver during play |
| `X` | Fire the rolling pin |
| `R` | Restart after victory or game over |
| `Q` or Escape | Quit |

## Troubleshooting

- **`nasm` is not found:** install NASM or pass `-NasmPath` on PowerShell.
- **DOSBox-X is not found:** install DOSBox-X, add it to `PATH`, or pass its
  path with `-DosBoxPath` to the Windows launcher.
- **The DOS game is not found:** build first. The host operating system cannot
  run the `.COM` file directly.
- **The display mode is unsupported or blank:** launch DOSBox-X with
  `packaging/dosbox/desktop.conf`, which selects SVGA S3 text mode and the
  game's 3:2 display ratio.
- **The Termux window is blank:** follow the separate
  [Termux:X11 guide](TERMUX-INSTALLATION.md); plain Termux has no graphical
  display.
