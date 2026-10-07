$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
# Keep the repository landing page bilingual without GitHub blob-page navigation.
$readmePath = Join-Path $projectRoot 'README.md'
$englishPath = Join-Path $projectRoot 'README.en.md'
$marker = '<!-- ENGLISH_SECTION -->'
$dutch = ([IO.File]::ReadAllText($readmePath) -split [regex]::Escape($marker), 2)[0].TrimEnd()
$english = [IO.File]::ReadAllText($englishPath)
$englishHeading = [regex]::Match($english, '(?m)^## ')
if (!$englishHeading.Success) { throw 'English README content missing' }
$english = $english.Substring($englishHeading.Index).Trim()
$combined = $dutch + "`n`n$marker`n`n---`n`n<a name=`"english`"></a>`n`n# English`n`n[Nederlands](#nederlands) | **English**`n`n" + $english + "`n"
[IO.File]::WriteAllText($readmePath, $combined, [Text.UTF8Encoding]::new($false))
$files = @(
    'scripts/vpn_ipcatcher.sh',
    'scripts/vpn_ipcatcher.real.sh',
    'scripts/vpn_ipcatcher_watchdog.sh',
    'addons/vpn_ipcatcher.d/vpn_ipcatcher_webui.sh',
    'addons/vpn_ipcatcher.d/vpn_ipcatcher_presets.sh',
    'addons/vpn_ipcatcher.d/vpn_ipcatcher.asp',
    'addons/vpn_ipcatcher.d/install_vpn_ipcatcher.sh',
    'addons/vpn_ipcatcher.d/vpn_ipcatcher_doctor.sh',
    'addons/vpn_ipcatcher.d/vpn_ipcatcher_update.sh',
    'addons/vpn_ipcatcher.d/vpn_ipcatcher_routing.sh',
    'addons/vpn_ipcatcher.d/vpn_ipcatcher_backup.sh',
    'addons/vpn_ipcatcher.d/vpn_ipcatcher_amtm.sh'
)
$manifest = foreach ($relative in $files) {
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $projectRoot $relative)).Hash.ToLowerInvariant()
    "$hash  $relative"
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'SHA256SUMS'), ($manifest -join "`n") + "`n", $utf8)
$releaseRoot = Join-Path $projectRoot 'release'
$version = (Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'VERSION')).Trim()
$packageRoot = Join-Path $releaseRoot "vpn-ipcatcher-$version"
New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null
$publishFiles = $files + @('install.sh', 'backup.sh', 'VERSION', 'SHA256SUMS', 'README.md', 'README.en.md', 'CHANGELOG.md', 'RELEASE-NOTES.md', '.gitattributes',
    'tests/engine-checks.sh', 'tests/update-checks.sh', 'tests/lifecycle-checks.sh', 'tests/installer-checks.sh', 'tests/path-checks.sh', 'tests/routing-checks.sh', 'tests/managed-routing-checks.sh', 'tests/bootstrap-checks.sh', 'tests/stream-safety-checks.sh', 'tests/backup-checks.sh', 'tests/amtm-checks.sh', 'tests/webui-backend-checks.sh', 'tests/webui-checks.js', '.github/workflows/release.yml', 'tools/build-release.ps1')
foreach ($relative in $publishFiles) {
    $target = Join-Path $packageRoot $relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot $relative) -Destination $target
}
$routerArchive = Join-Path $releaseRoot "vpn-ipcatcher-$version.tar.gz"
& tar -czf $routerArchive -C $projectRoot @files VERSION SHA256SUMS
if ($LASTEXITCODE -ne 0) { throw 'Router archive creation failed' }
$githubArchive = Join-Path $releaseRoot "vpn-ipcatcher-$version-github.zip"
& tar -a -cf $githubArchive -C $packageRoot @publishFiles
if ($LASTEXITCODE -ne 0) { throw 'GitHub archive creation failed' }
Write-Output "Router package: $routerArchive"
Write-Output "GitHub package: $githubArchive"
