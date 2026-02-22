param(
    [Parameter(Mandatory = $false)]
    [string]$Repo,

    [Parameter(Mandatory = $false)]
    [string]$BacklogPath,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-GhExe {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'GitHub CLI\gh.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'GitHub CLI\gh.exe')
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    throw "GitHub CLI (gh) not found. Install it: winget install --id GitHub.cli -e"
}

function Invoke-Gh {
    param(
        [Parameter(Mandatory = $true)][string]$GhExe,
        [Parameter(Mandatory = $true)][string[]]$Args
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $GhExe
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.Arguments = ($Args | ForEach-Object {
        if ($_ -match '\s' -and $_ -notmatch '^".*"$') { '"' + ($_ -replace '"', '\\"') + '"' } else { $_ }
    }) -join ' '

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()

    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()

    if ($p.ExitCode -ne 0) {
        throw "gh failed (exit $($p.ExitCode)).\nSTDOUT: $stdout\nSTDERR: $stderr"
    }

    return $stdout
}

function Get-RepoFromGitOrigin {
    $origin = (git remote get-url origin) 2>$null
    if (-not $origin) { return $null }

    if ($origin -match 'github.com[:/](?<owner>[^/]+)/(?<repo>[^/.]+)(\.git)?$') {
        return "$($Matches.owner)/$($Matches.repo)"
    }

    return $null
}

$gh = Get-GhExe
Write-Host "Using gh: $gh"

if (-not $BacklogPath) {
    $BacklogPath = Join-Path $PSScriptRoot 'backlog.json'
}

if (-not (Test-Path $BacklogPath)) {
    throw "Backlog file not found: $BacklogPath"
}

$backlog = Get-Content $BacklogPath -Raw | ConvertFrom-Json

if (-not $Repo) {
    $Repo = Get-RepoFromGitOrigin
}
if (-not $Repo) {
    $Repo = $backlog.repo
}
if (-not $Repo) {
    throw "Repo not provided and not found. Pass -Repo owner/name"
}

Write-Host "Target repo: $Repo"

# Ensure auth
try {
    Invoke-Gh -GhExe $gh -Args @('auth', 'status', '-h', 'github.com') | Out-Null
} catch {
    Write-Host "Not authenticated to GitHub CLI." -ForegroundColor Yellow
    Write-Host "Run: & \"$gh\" auth login --web" -ForegroundColor Yellow
    throw
}

if ($DryRun) {
    Write-Host "DRY RUN enabled: no changes will be made." -ForegroundColor Cyan
}

# Labels
$labelColor = @{
    epic     = '5319e7'
    backend  = '0e8a16'
    api      = '1d76db'
    security = 'b60205'
    database = 'fbca04'
    testing  = 'c5def5'
    docker   = '0052cc'
    docs     = 'bfdadc'
}

$allLabels = New-Object System.Collections.Generic.HashSet[string]
foreach ($issue in $backlog.issues) {
    foreach ($lab in $issue.labels) {
        [void]$allLabels.Add([string]$lab)
    }
}

$existingLabelsJson = Invoke-Gh -GhExe $gh -Args @('label', 'list', '--repo', $Repo, '--json', 'name', '--limit', '500')
$existingLabels = ($existingLabelsJson | ConvertFrom-Json | ForEach-Object { $_.name })
$existingLabelSet = New-Object System.Collections.Generic.HashSet[string]
$existingLabels | ForEach-Object { [void]$existingLabelSet.Add($_) }

foreach ($lab in $allLabels) {
    if (-not $existingLabelSet.Contains($lab)) {
        $color = if ($labelColor.ContainsKey($lab)) { $labelColor[$lab] } else { 'ededed' }
        Write-Host "Creating label: $lab" -ForegroundColor Green
        if (-not $DryRun) {
            Invoke-Gh -GhExe $gh -Args @('label', 'create', $lab, '--repo', $Repo, '--color', $color) | Out-Null
        }
    }
}

# Milestones (via API)
$existingMilestonesJson = Invoke-Gh -GhExe $gh -Args @('api', "/repos/$Repo/milestones", '--paginate')
$existingMilestones = @{}
foreach ($m in ($existingMilestonesJson | ConvertFrom-Json)) {
    $existingMilestones[$m.title] = $m.number
}

foreach ($m in $backlog.milestones) {
    if (-not $existingMilestones.ContainsKey($m.title)) {
        Write-Host "Creating milestone: $($m.title)" -ForegroundColor Green
        if (-not $DryRun) {
            $payload = @{ title = $m.title; description = $m.description } | ConvertTo-Json
            Invoke-Gh -GhExe $gh -Args @('api', '-X', 'POST', "/repos/$Repo/milestones", '-H', 'Accept: application/vnd.github+json', '-f', "title=$($m.title)", '-f', "description=$($m.description)") | Out-Null
        }
    }
}

# Refresh milestone map after potential creation
$existingMilestonesJson = Invoke-Gh -GhExe $gh -Args @('api', "/repos/$Repo/milestones", '--paginate')
$milestoneTitles = New-Object System.Collections.Generic.HashSet[string]
foreach ($m in ($existingMilestonesJson | ConvertFrom-Json)) {
    [void]$milestoneTitles.Add([string]$m.title)
}

# Existing issues by title (avoid duplicates)
$issuesJson = Invoke-Gh -GhExe $gh -Args @('issue', 'list', '--repo', $Repo, '--state', 'all', '--limit', '500', '--json', 'title')
$existingTitles = New-Object System.Collections.Generic.HashSet[string]
foreach ($i in ($issuesJson | ConvertFrom-Json)) {
    [void]$existingTitles.Add([string]$i.title)
}

foreach ($issue in $backlog.issues) {
    $title = [string]$issue.title
    if ($existingTitles.Contains($title)) {
        Write-Host "Skipping existing issue: $title" -ForegroundColor DarkGray
        continue
    }

    $labels = @($issue.labels | ForEach-Object { [string]$_ })
    $labelArg = if ($labels.Count -gt 0) { $labels -join ',' } else { $null }

    $milestone = [string]$issue.milestone
    if ($milestone -and (-not $milestoneTitles.Contains($milestone))) {
        throw "Milestone not found on GitHub: $milestone"
    }

    $body = [string]$issue.body
    if ($issue.complexity) {
        $body = $body + "\n\nComplexity: $($issue.complexity)"
    }

    Write-Host "Creating issue: $title" -ForegroundColor Green
    if (-not $DryRun) {
        $args = @('issue', 'create', '--repo', $Repo, '--title', $title, '--body', $body)
        if ($labelArg) { $args += @('--label', $labelArg) }
        if ($milestone) { $args += @('--milestone', $milestone) }
        Invoke-Gh -GhExe $gh -Args $args | Out-Null
    }
}

Write-Host "Done." -ForegroundColor Cyan
