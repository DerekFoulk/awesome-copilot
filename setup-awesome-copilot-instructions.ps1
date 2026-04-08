<#
.SYNOPSIS
  setup-awesome-copilot-instructions.ps1

.DESCRIPTION
  Clone/update github/awesome-copilot, generate a merged .github\copilot-instructions.md,
  and sync scoped instruction files into .github\instructions\awesome-copilot\.

  You can independently control:
    - Which instructions get MERGED into copilot-instructions.md
    - Which instructions get COPIED into .github\instructions\awesome-copilot\

  The merge file is always regenerated from scratch each run (previous content is overwritten).
  Before overwriting, the previous copilot-instructions.md is backed up with a timestamp.

  Scoped instructions are "fully synced" into .github\instructions\awesome-copilot\ by deleting and recreating
  ONLY that subfolder each run (so removed/upstream-deleted files don't linger). Any other custom instruction
  files you keep elsewhere under .github\instructions\ are preserved.

.PARAMETERS (selection)
  -MergeScope  : All | Subset
  -CopyScope   : All | Subset

  When Scope=Subset, you can filter by filename using wildcard pattern(s):
    -MergeIncludeNamePattern  (one or more wildcard patterns)
    -CopyIncludeNamePattern   (one or more wildcard patterns)

  Wildcard patterns are matched against the instruction file NAME only (not the path, not file content).
  Examples: '*dotnet*', '*blazor*', '*maui*', '*security*', '*owasp*', '*html*', '*css*'

.PARAMETER RepoRoot
  The root folder of your project repository (the folder that contains .git).
  Example: C:\source\repos\msp-coplogic

.PARAMETER ReposRoot
  The folder where you keep git repositories locally. The awesome-copilot repo
  will be cloned/updated into: <ReposRoot>\awesome-copilot

.PREREQUISITES
  - Git must be installed and available on PATH (git clone/pull is used).
  - You must have write access to your repo's .github folder.

.HOW TO RUN (examples)
  NOTE: The ".NET + Web + Security" subset patterns below align to a stack like:
        .NET/C#/ASP.NET/Blazor/MAUI/EF/SQL + general web (HTML/CSS/JS/TS) + security/OWASP + CI/Docker + testing/perf.

  1) Copy and merge ALL (everything):
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\source\repos\setup-awesome-copilot-instructions.ps1" -MergeScope All -CopyScope All

  2) Copy ALL, merge a ".NET + Web + Security" SUBSET:
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\source\repos\setup-awesome-copilot-instructions.ps1" `
      -MergeScope Subset `
      -MergeIncludeNamePattern '*dotnet*','*csharp*','*aspnet*','*blazor*','*razor*','*maui*','*ef*','*efcore*','*entity*','*sql*','*sqlite*','*ms-sql*','*javascript*','*typescript*','*nodejs*','*html*','*css*','*scss*','*sass*','*web*','*security*','*owasp*','*code-review*','*performance*','*testing*','*xunit*','*bunit*','*playwright*','*github-actions*','*ci-cd*','*docker*','*container*','*a11y*','*accessibility*','*localization*','*logging*','*telemetry*' `
      -CopyScope All

  3) Copy a ".NET + Web + Security" SUBSET, merge ALL:
     (You get a full merged copilot-instructions.md, but only vendor the subset under .github\instructions\awesome-copilot\.)
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\source\repos\setup-awesome-copilot-instructions.ps1" `
      -MergeScope All `
      -CopyScope Subset `
      -CopyIncludeNamePattern '*dotnet*','*csharp*','*aspnet*','*blazor*','*razor*','*maui*','*ef*','*efcore*','*entity*','*sql*','*sqlite*','*ms-sql*','*javascript*','*typescript*','*nodejs*','*html*','*css*','*scss*','*sass*','*web*','*security*','*owasp*','*code-review*','*performance*','*testing*','*xunit*','*bunit*','*playwright*','*github-actions*','*ci-cd*','*docker*','*container*','*a11y*','*accessibility*','*localization*','*logging*','*telemetry*'

  4) Copy and merge a ".NET + Web + Security" SUBSET:
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\source\repos\setup-awesome-copilot-instructions.ps1" `
      -MergeScope Subset `
      -MergeIncludeNamePattern '*dotnet*','*csharp*','*aspnet*','*blazor*','*razor*','*maui*','*ef*','*efcore*','*entity*','*sql*','*sqlite*','*ms-sql*','*javascript*','*typescript*','*nodejs*','*html*','*css*','*scss*','*sass*','*web*','*security*','*owasp*','*code-review*','*performance*','*testing*','*xunit*','*bunit*','*playwright*','*github-actions*','*ci-cd*','*docker*','*container*','*a11y*','*accessibility*','*localization*','*logging*','*telemetry*' `
      -CopyScope Subset `
      -CopyIncludeNamePattern  '*dotnet*','*csharp*','*aspnet*','*blazor*','*razor*','*maui*','*ef*','*efcore*','*entity*','*sql*','*sqlite*','*ms-sql*','*javascript*','*typescript*','*nodejs*','*html*','*css*','*scss*','*sass*','*web*','*security*','*owasp*','*code-review*','*performance*','*testing*','*xunit*','*bunit*','*playwright*','*github-actions*','*ci-cd*','*docker*','*container*','*a11y*','*accessibility*','*localization*','*logging*','*telemetry*'

.NOTES
  - Close any editor that has .github\copilot-instructions.md open before running (file locks can break writes).
  - This script clones/pulls from the internet (github.com).
#>

param(
  # Your repo root (where .git lives)
  [string]$RepoRoot = "C:\source\repos\msp-coplogic",

  # Where you keep git repos locally
  [string]$ReposRoot = "C:\source\repos",

  # Which instructions to MERGE into .github\copilot-instructions.md
  [ValidateSet("All","Subset")]
  [string]$MergeScope = "Subset",

  # Which instructions to COPY into .github\instructions\awesome-copilot\
  [ValidateSet("All","Subset")]
  [string]$CopyScope = "All",

  # Wildcard pattern(s) applied to the file NAME (not path) when MergeScope=Subset
  [string[]]$MergeIncludeNamePattern = @(
    '*dotnet*','*csharp*','*aspnet*','*blazor*','*razor*','*maui*','*ef*','*efcore*','*entity*',
    '*sql*','*sqlite*','*ms-sql*',
    '*javascript*','*typescript*','*nodejs*',
    '*html*','*css*','*scss*','*sass*','*web*',
    '*security*','*owasp*',
    '*code-review*','*performance*',
    '*testing*','*xunit*','*bunit*','*playwright*',
    '*github-actions*','*ci-cd*','*docker*','*container*',
    '*a11y*','*accessibility*','*localization*',
    '*logging*','*telemetry*'
  ),

  # Wildcard pattern(s) applied to the file NAME (not path) when CopyScope=Subset
  [string[]]$CopyIncludeNamePattern = @('*')
)

$ErrorActionPreference = "Stop"

$awesomeDir = Join-Path $ReposRoot "awesome-copilot"
$instructionsSrc = Join-Path $awesomeDir "instructions"

$githubDir = Join-Path $RepoRoot ".github"
$copilotInstructionsOut = Join-Path $githubDir "copilot-instructions.md"

# Destination is a subfolder to preserve your custom instructions elsewhere under .github\instructions\
$instructionsRootDest = Join-Path $githubDir "instructions"
$instructionsDest = Join-Path $instructionsRootDest "awesome-copilot"

function Get-AllInstructionFiles {
  param([string]$Root)
  return (Get-ChildItem $Root -Recurse -File -Filter "*.instructions.md" | Sort-Object FullName)
}

function Filter-ByNameWildcard {
  param(
    [System.IO.FileInfo[]]$Files,
    [string[]]$NamePatterns
  )

  # If user passed '*' (or empty), keep all
  if (-not $NamePatterns -or $NamePatterns.Count -eq 0 -or ($NamePatterns | Where-Object { $_ -eq '*' }).Count -gt 0) {
    return $Files
  }

  $out = @()
  foreach ($f in $Files) {
    foreach ($p in $NamePatterns) {
      if ($f.Name -like $p) { $out += $f; break }
    }
  }

  # Deduplicate while preserving order
  $seen = @{}
  return ($out | Where-Object { if ($seen.ContainsKey($_.FullName)) { $false } else { $seen[$_.FullName] = $true; $true } })
}

# 1) Clone or update awesome-copilot
if (-not (Test-Path $awesomeDir)) {
  git clone https://github.com/github/awesome-copilot.git $awesomeDir
} else {
  Push-Location $awesomeDir
  git fetch origin
  git checkout main
  git pull --ff-only
  Pop-Location
}

if (-not (Test-Path $instructionsSrc)) {
  throw "Missing source instructions folder: $instructionsSrc"
}

$allFiles = Get-AllInstructionFiles -Root $instructionsSrc

# 2) Select merge files
if ($MergeScope -eq "All") {
  $mergeFiles = $allFiles
} else {
  $mergeFiles = Filter-ByNameWildcard -Files $allFiles -NamePatterns $MergeIncludeNamePattern
}

if ($mergeFiles.Count -eq 0) {
  throw "No files selected for merge. MergeScope=$MergeScope. Check -MergeIncludeNamePattern."
}

# Ensure .github exists
New-Item -ItemType Directory -Path $githubDir -Force | Out-Null

# 3) Backup existing merged file
if (Test-Path $copilotInstructionsOut) {
  $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $backupPath = Join-Path $githubDir ("copilot-instructions.backup.{0}.md" -f $timestamp)
  Copy-Item -Path $copilotInstructionsOut -Destination $backupPath -Force
  Write-Host "Backed up existing copilot-instructions.md to:"
  Write-Host "  $backupPath"
}

# 4) Generate merged copilot-instructions.md
$header = @"
# Copilot Instructions (Merged from github/awesome-copilot)

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Source repo: https://github.com/github/awesome-copilot
Local clone: $awesomeDir
Source folder: instructions/

Merge scope: $MergeScope
Merge include patterns (MergeScope=Subset): $($MergeIncludeNamePattern -join ', ')
Copy scope: $CopyScope
Copy include patterns (CopyScope=Subset): $($CopyIncludeNamePattern -join ', ')

NOTE:
- This is a merged file intended to influence GitHub Copilot inside Visual Studio 2022.
- Scoped instructions are synced under .github/instructions/awesome-copilot/.

"@

Set-Content -Path $copilotInstructionsOut -Value $header -Encoding utf8

Add-Content -Path $copilotInstructionsOut -Value "`n---`n## Included files (merged)`n---`n" -Encoding utf8
foreach ($f in $mergeFiles) {
  $rel = $f.FullName.Substring($instructionsSrc.Length).TrimStart('\','/')
  Add-Content -Path $copilotInstructionsOut -Value "- instructions/$rel" -Encoding utf8
}

Add-Content -Path $copilotInstructionsOut -Value "`n---`n## Merged content`n---`n" -Encoding utf8
foreach ($f in $mergeFiles) {
  $rel = $f.FullName.Substring($instructionsSrc.Length).TrimStart('\','/')
  Add-Content -Path $copilotInstructionsOut -Value "`n`n<!-- BEGIN instructions/$rel -->`n" -Encoding utf8
  Get-Content -Path $f.FullName -Raw | Add-Content -Path $copilotInstructionsOut -Encoding utf8
  Add-Content -Path $copilotInstructionsOut -Value "`n<!-- END instructions/$rel -->`n" -Encoding utf8
}

Write-Host "Merged repo-wide instructions written to:"
Write-Host "  $copilotInstructionsOut"
Write-Host "Merged files: $($mergeFiles.Count)"

# 5) Select copy files
if ($CopyScope -eq "All") {
  $copyFiles = $allFiles
} else {
  $copyFiles = Filter-ByNameWildcard -Files $allFiles -NamePatterns $CopyIncludeNamePattern
}

if ($copyFiles.Count -eq 0) {
  throw "No files selected for copy. CopyScope=$CopyScope. Check -CopyIncludeNamePattern."
}

# 6) Sync into .github/instructions/awesome-copilot/
New-Item -ItemType Directory -Path $instructionsRootDest -Force | Out-Null

# True sync of ONLY the awesome-copilot subfolder
if (Test-Path $instructionsDest) {
  Remove-Item -Path $instructionsDest -Recurse -Force
}
New-Item -ItemType Directory -Path $instructionsDest -Force | Out-Null

foreach ($f in $copyFiles) {
  $rel = $f.FullName.Substring($instructionsSrc.Length).TrimStart('\','/')
  $destPath = Join-Path $instructionsDest $rel
  $destDir = Split-Path -Parent $destPath
  New-Item -ItemType Directory -Path $destDir -Force | Out-Null
  Copy-Item -Path $f.FullName -Destination $destPath -Force
}

Write-Host "Copied scoped instructions to:"
Write-Host "  $instructionsDest"
Write-Host "Copied files: $($copyFiles.Count)"
Write-Host "Done."
