# trivuedev public installer (Windows)
# Downloads a release binary from github.com/orashus/trivuedev and verifies checksums.
#
# Usage:
#   irm https://raw.githubusercontent.com/orashus/trivuedev/main/install.ps1 | iex
#   $env:TRIVUEDEV_VERSION = "v0.1.0"; irm https://raw.githubusercontent.com/orashus/trivuedev/main/install.ps1 | iex
#   $env:TRIVUEDEV_INSTALL_DIR = "$env:LOCALAPPDATA\trivuedev\bin"; .\install.ps1
#
# Inspect before running:
#   Invoke-WebRequest https://raw.githubusercontent.com/orashus/trivuedev/main/install.ps1 -OutFile install.ps1
#   notepad install.ps1
#   .\install.ps1

$ErrorActionPreference = "Stop"

$Repo = "orashus/trivuedev"
$BaseUrl = "https://github.com/$Repo/releases"

function Get-InstallDir {
    if ($env:TRIVUEDEV_INSTALL_DIR -and $env:TRIVUEDEV_INSTALL_DIR.Trim() -ne "") {
        return $env:TRIVUEDEV_INSTALL_DIR.Trim()
    }
    return Join-Path $env:LOCALAPPDATA "trivuedev\bin"
}

function Get-Version {
    if ($env:TRIVUEDEV_VERSION -and $env:TRIVUEDEV_VERSION.Trim() -ne "") {
        $v = $env:TRIVUEDEV_VERSION.Trim()
        if (-not $v.StartsWith("v")) { $v = "v$v" }
        return $v
    }
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
    if (-not $release.tag_name) {
        throw "Could not resolve latest release tag."
    }
    return $release.tag_name
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -Path $Path).Hash.ToLowerInvariant()
}

function Assert-Checksum([string]$ArchivePath, [string]$ChecksumsPath) {
    $name = Split-Path -Leaf $ArchivePath
    $expected = $null
    foreach ($line in Get-Content $ChecksumsPath) {
        $parts = $line -split "\s+", 2
        if ($parts.Count -ge 2 -and $parts[1] -eq $name) {
            $expected = $parts[0].ToLowerInvariant()
            break
        }
    }
    if (-not $expected) {
        throw "Checksum entry not found for $name"
    }
    $actual = Get-Sha256 $ArchivePath
    if ($actual -ne $expected) {
        throw "Checksum mismatch for $name (expected $expected, got $actual)"
    }
    Write-Host "Checksum OK for $name"
}

$arch = $env:PROCESSOR_ARCHITECTURE
switch ($arch) {
    "AMD64" { $goArch = "amd64" }
    "ARM64" { $goArch = "arm64" }
    default { throw "Unsupported architecture: $arch (supported: AMD64)" }
}

# First public Windows target is amd64; refuse unexpected arches for now.
if ($goArch -ne "amd64") {
    throw "Unsupported Windows architecture: $goArch (supported: amd64)"
}

$version = Get-Version
$installDir = Get-InstallDir
$asset = "trivuedev_${version}_windows_amd64.zip"
$url = "$BaseUrl/download/$version/$asset"
$sumsUrl = "$BaseUrl/download/$version/checksums.txt"

Write-Host "Installing trivuedev $version (windows/amd64)"
Write-Host "Download: $url"

$tmp = New-Item -ItemType Directory -Path ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString("N")))
try {
    $archive = Join-Path $tmp.FullName $asset
    $checksums = Join-Path $tmp.FullName "checksums.txt"
    Invoke-WebRequest -Uri $url -OutFile $archive
    Invoke-WebRequest -Uri $sumsUrl -OutFile $checksums

    Assert-Checksum -ArchivePath $archive -ChecksumsPath $checksums

    Expand-Archive -Path $archive -DestinationPath $tmp.FullName -Force
    $bin = Get-ChildItem -Path $tmp.FullName -Recurse -Filter "trivuedev.exe" | Select-Object -First 1
    if (-not $bin) {
        throw "Archive did not contain trivuedev.exe"
    }

    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    $dest = Join-Path $installDir "trivuedev.exe"
    Copy-Item -Force -Path $bin.FullName -Destination $dest

    Write-Host "Installed to $dest"

    $onPath = ($env:PATH -split ";") -contains $installDir
    if (-not $onPath) {
        Write-Host ""
        Write-Host "Note: $installDir is not on your PATH."
        Write-Host "Add it for this session:"
        Write-Host "  `$env:PATH = `"$installDir;`$env:PATH`""
    }

    Write-Host ""
    Write-Host "Try: trivuedev --help"
}
finally {
    Remove-Item -Recurse -Force $tmp.FullName -ErrorAction SilentlyContinue
}
