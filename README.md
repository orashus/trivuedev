# trivuedev

`trivuedev` is distributed as a **precompiled native executable**. The source repository is private, but the release binaries and installation scripts are publicly available from this `orashus/trivuedev` distribution repository.

This repository does **not** contain the Go source code. It hosts installation scripts and GitHub Releases only.

## Install (macOS / Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/orashus/trivuedev/main/install.sh | sh
```

Pinned version:

```bash
curl -fsSL https://raw.githubusercontent.com/orashus/trivuedev/main/install.sh | TRIVUEDEV_VERSION=v0.1.0 sh
```

Custom install directory:

```bash
curl -fsSL https://raw.githubusercontent.com/orashus/trivuedev/main/install.sh | TRIVUEDEV_INSTALL_DIR="$HOME/.local/bin" sh
```

### Inspect before running

Piping a remote script to `sh` requires trusting this repository's installer. Prefer reviewing it first:

```bash
curl -fsSL https://raw.githubusercontent.com/orashus/trivuedev/main/install.sh -o install.sh
less install.sh
sh install.sh
```

The installer downloads the matching release archive, verifies `checksums.txt`, then installs `trivuedev` to `~/.local/bin` by default.

## Install (Windows)

```powershell
irm https://raw.githubusercontent.com/orashus/trivuedev/main/install.ps1 | iex
```

Pinned version / custom directory:

```powershell
$env:TRIVUEDEV_VERSION = "v0.1.0"
$env:TRIVUEDEV_INSTALL_DIR = "$env:LOCALAPPDATA\trivuedev\bin"
irm https://raw.githubusercontent.com/orashus/trivuedev/main/install.ps1 | iex
```

Inspect before running:

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/orashus/trivuedev/main/install.ps1 -OutFile install.ps1
notepad install.ps1
.\install.ps1
```

## Manual download

Browse releases:

https://github.com/orashus/trivuedev/releases

Archives look like:

```text
trivuedev_v0.1.0_darwin_arm64.tar.gz
trivuedev_v0.1.0_darwin_amd64.tar.gz
trivuedev_v0.1.0_linux_arm64.tar.gz
trivuedev_v0.1.0_linux_amd64.tar.gz
trivuedev_v0.1.0_windows_amd64.zip
checksums.txt
```

Verify the SHA-256 of your archive against `checksums.txt` before running the binary.

## Usage

```bash
# Copy the login command from Trivue Dashboard → Settings → Dev environments
trivuedev login <publicId> <environmentId>
trivuedev whoami
trivuedev http://localhost:3000
trivuedev http://localhost:3000 --json
trivuedev logout
```

Optional API override:

```bash
export TRIVUE_API_URL=http://localhost:3000
```

Default API: `https://trivue.orashus.com`

## Supported platforms

| OS | Arch |
| --- | --- |
| macOS | amd64, arm64 |
| Linux | amd64, arm64 |
| Windows | amd64 |

## What this CLI does

Fetches localhost HTML on your machine and submits it to Trivue for inspection. Production Trivue never fetches your localhost URL.
