# Build and run Food Invaders on Windows and macOS

Use this guide to install NASM and DOSBox-X, build `INVADERS.COM`, and start the game. Food Invaders is a 16-bit DOS program. It needs DOSBox-X with SVGA S3 mode enabled. The display uses a 180×120 text field and a 64 KiB VGA memory window at A000.

## Requirements

| Requirement | Use | Required for |
| --- | --- | --- |
| NASM 3.02 or later | Builds the DOS `.COM` program and test binaries. | Building on Windows or macOS. |
| DOSBox-X | Runs the game with the required SVGA S3 text mode. | Playing the game. Standard DOSBox builds have not been verified for this display mode. |
| Git | Clones the repository. | Optional. You can download the repository ZIP instead. |
| PowerShell | Runs the provided `.ps1` build and DOSBox-X test scripts. | Included on Windows. Optional on macOS. |
| Keyboard and display | Controls the game. | Playing the game. |

## Get the source

If Git is installed, clone the repository:

```sh
git clone https://github.com/Patt-00/Food-Invaders.git
```

Without Git, open the [Food Invaders repository](https://github.com/Patt-00/Food-Invaders), choose **Code**, then choose **Download ZIP**. GitHub documents this source archive method in its [download guide](https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives).

The game source and build scripts are in `asm-space-invaders-main`. The repository does not include generated `.COM` files. Build `INVADERS.COM` before launching the game.

## Windows

### Install NASM

1. Download and run the [NASM 3.02 x64 installer](https://www.nasm.us/pub/nasm/releasebuilds/3.02/win64/nasm-3.02-installer-x64.exe). NASM lists this installer in its [official Windows release directory](https://www.nasm.us/pub/nasm/releasebuilds/3.02/win64/).
2. Keep the install location shown by the installer.
3. Open a new PowerShell window and check NASM:

```powershell
nasm -v
```

If PowerShell cannot find `nasm`, pass the full path to `nasm.exe` to the build script. The example path is `C:\Program Files\NASM\nasm.exe`; use the location on your computer.

### Install DOSBox-X

1. Open the [official DOSBox-X download page](https://dosbox-x.com/).
2. Under Windows, download the 32/64-bit Setup for Windows 7 or later. The project recommends this installer for a standard Windows installation. See the DOSBox-X [installation guide](https://github.com/joncampbell123/dosbox-x/blob/master/INSTALL.md) for package details.
3. Run the installer and note where it places `dosbox-x.exe`.

### Install Git when cloning

If you want to clone the source instead of downloading the ZIP, install [Git for Windows](https://git-scm.com/install/windows). Run the x64 installer, keep the standard options, then open a new PowerShell window and verify it with `git --version`.

### Build and play

Open PowerShell and move into the game source folder. Replace the example paths with the locations on your computer.

```powershell
cd Food-Invaders\asm-space-invaders-main
$NasmPath = 'C:\Program Files\NASM\nasm.exe'
$DosBoxPath = 'C:\Program Files\DOSBox-X\dosbox-x.exe'
.\build.ps1 -NasmPath $NasmPath
.\run-dosbox.ps1 -DosBoxPath $DosBoxPath
```

If `nasm` and `dosbox-x` are on `PATH`, run `build.ps1` and `run-dosbox.ps1` without path parameters. Otherwise, pass each executable's full path as shown above.

If Windows blocks a local PowerShell script, run it with a process-only execution policy. This does not change the machine-wide policy:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build.ps1 -NasmPath $NasmPath
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\run-dosbox.ps1 -DosBoxPath $DosBoxPath
```

### Optional regression tests

`build.ps1 -Test` builds the game, all four test programs, checks the DOS segment size, and runs the core, player/weapon, and collision suites in DOSBox-X. Run both CPU cores:

```powershell
.\build.ps1 -NasmPath $NasmPath -DosBoxPath $DosBoxPath -Test -Core normal
.\build.ps1 -NasmPath $NasmPath -DosBoxPath $DosBoxPath -Test -Core dynamic
```

The test results are written to `tests/integrated-normal-result.txt` and `tests/integrated-dynamic-result.txt`. The [host platform workflow](../.github/workflows/platform-build-test.yml) runs both cores on Windows and macOS with the same build script. Its surface-output test configuration does not verify a manual, full-screen play session.

## macOS

### Install Git and command-line tools

Git is optional if you download the repository ZIP. To install Apple's Command Line Tools, including Git, open Terminal and run:

```sh
xcode-select --install
```

Apple explains this installation in its [Command Line Tools guide](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools). The tools include Git. Verify it from Terminal with `git --version`. You can also download the repository ZIP and skip Git.

### Install NASM

Homebrew installs NASM for your Mac's processor architecture. After installing the Command Line Tools, run Homebrew's official installer:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the shell setup command printed at the end of installation. See [Homebrew's installation instructions](https://docs.brew.sh/Installation). Then install NASM:

```sh
brew install nasm
nasm -v
```

Homebrew lists the NASM install command on its [NASM formula page](https://formulae.brew.sh/formula/nasm). Its standard supported setup requires Apple silicon and macOS 15 or later. Intel Macs and older macOS versions may have limited support. Check Homebrew's [installation requirements](https://docs.brew.sh/Installation) before installing it.

The [official NASM release directory](https://www.nasm.us/pub/nasm/releasebuilds/3.02/macosx/) also provides a macOS ZIP. That binary is Intel-based. On Apple silicon, use Homebrew for a native NASM build or install Apple's [Rosetta support](https://support.apple.com/en-us/102527) before using the Intel binary.

### Install DOSBox-X

1. Open the [official DOSBox-X download page](https://dosbox-x.com/).
2. Download the package for an Intel Mac or Apple silicon Mac.
3. Unzip the package and move its `dosbox-x.app` to `/Applications`. The official [DOSBox-X installation guide](https://github.com/joncampbell123/dosbox-x/blob/master/INSTALL.md) describes the SDL1 and SDL2 packages. Choose SDL2 on macOS 12 or later, and choose SDL1 on older supported macOS versions.

If Gatekeeper blocks the downloaded app, confirm the archive came from the official DOSBox-X page, then follow the macOS Privacy & Security prompt. The DOSBox-X installation guide describes this prompt.

Homebrew also provides a `dosbox-x` command through `brew install dosbox-x`. The Homebrew package is maintained by Homebrew contributors; the DOSBox-X project provides the direct Mac packages on its download page.

To use that Homebrew command, run:

```sh
brew install dosbox-x
```

### Build and play

Open Terminal and change to the game source directory:

```sh
cd Food-Invaders/asm-space-invaders-main
nasm -f bin -Wall -w-reloc -Werror main.asm -o INVADERS.COM
```

If DOSBox-X was installed with Homebrew, start the game with:

```sh
dosbox-x -conf dosbox.conf
```

If you installed the official app package, start its executable from the same source directory:

```sh
/Applications/dosbox-x.app/Contents/MacOS/dosbox-x -conf dosbox.conf
```

The configuration mounts the current source directory and starts `INVADERS.COM`. If the app is stored under another name or location, use its actual `Contents/MacOS/dosbox-x` path.

### Optional regression tests

To run `build.ps1` on macOS, install PowerShell 7 from Microsoft's official macOS package. Open the [PowerShell for macOS install guide](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-macos). Select the Arm64 `.pkg` for Apple silicon or the x64 `.pkg` for an Intel Mac, open the package, and follow its installer. Then verify PowerShell:

```sh
pwsh -NoProfile -Command '$PSVersionTable.PSVersion'
```

From `asm-space-invaders-main`, run the tests on both DOSBox-X CPU cores:

```sh
pwsh -NoProfile -File ./build.ps1 -NasmPath "$(command -v nasm)" -DosBoxPath "$(command -v dosbox-x)" -Test -Core normal
pwsh -NoProfile -File ./build.ps1 -NasmPath "$(command -v nasm)" -DosBoxPath "$(command -v dosbox-x)" -Test -Core dynamic
```

If you installed the official DOSBox-X app instead of the Homebrew command, replace `$(command -v dosbox-x)` with the app executable path.

## Controls

| Key | Action |
| --- | --- |
| `1`, `2`, or `3` | Start on Easy, Normal, or Hard |
| `P` or Space | Start on Normal |
| A/D or arrow keys | Move the Chef |
| Space | Fire the cleaver |
| `X` | Fire the rolling pin |
| `R` | Restart after a result screen |
| `Q` or Escape | Quit |

## Troubleshooting

Start DOSBox-X with the repository's `dosbox.conf`. It selects `machine=svga_s3`, mounts the game folder, and starts `INVADERS.COM`. If DOSBox reports an unsupported video mode, confirm that you launched DOSBox-X with this configuration.

If DOSBox-X reports that `INVADERS.COM` is missing, return to `asm-space-invaders-main` and build the game before launching it. The host operating system cannot run the DOS `.COM` file directly.
