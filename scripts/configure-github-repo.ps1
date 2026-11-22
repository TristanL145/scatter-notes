<#
.SYNOPSIS
    Configures GitHub repository settings, security features, GitHub Actions permissions,
    and branch protection rules for Scatter Notes.

.DESCRIPTION
    Idempotent script using GitHub CLI (`gh`) and the GitHub REST API.
    Locates `gh.exe` in PATH or the default winget install location (`C:\Program Files\GitHub CLI\gh.exe`).

.PARAMETER Owner
    GitHub username or organization that owns the repository. If omitted, uses the authenticated `gh` user.

.PARAMETER Repo
    Repository name. Defaults to `scatter-notes`.

.EXAMPLE
    .\scripts\configure-github-repo.ps1 -Repo scatter-notes
#>

[CmdletBinding()]
param(
    [string]$Owner,
    [string]$Repo = "scatter-notes"
)

$ErrorActionPreference = "Stop"

function Resolve-GhCli {
    $cmd = Get-Command gh -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }
    $candidates = @(
        "C:\Program Files\GitHub CLI\gh.exe",
        "$env:LOCALAPPDATA\Programs\GitHub CLI\gh.exe"
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) {
            return $path
        }
    }
    throw "GitHub CLI (gh) was not found in PATH or standard install directories. Install with: winget install --id GitHub.cli -e"
}

function Invoke-GhApi {
    param(
        [Parameter(Mandatory = $true)][string]$GhPath,
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Endpoint,
        [hashtable]$Body,
        [string]$Label
    )

    Write-Host "==> $Label ($Method $Endpoint)" -ForegroundColor Cyan
    $tempFile = $null
    try {
        if ($null -ne $Body) {
            $json = $Body | ConvertTo-Json -Depth 10 -Compress
            $tempFile = [System.IO.Path]::GetTempFileName()
            [System.IO.File]::WriteAllText($tempFile, $json, [System.Text.UTF8Encoding]::new($false))
            $output = & $GhPath api --method $Method $Endpoint --input $tempFile 2>&1
        } else {
            $output = & $GhPath api --method $Method $Endpoint 2>&1
        }
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            Write-Warning "FAILED ($Label) [exit $exitCode]: $output"
            return $false
        }
        Write-Host "    OK: $Label" -ForegroundColor Green
        return $true
    } finally {
        if ($tempFile -and (Test-Path $tempFile)) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

$gh = Resolve-GhCli
Write-Host "Using GitHub CLI: $gh" -ForegroundColor Gray

# Verify authentication
& $gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run '$gh auth login' first."
}

if ([string]::IsNullOrWhiteSpace($Owner)) {
    $Owner = (& $gh api user --jq .login).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Owner)) {
        throw "Could not determine authenticated GitHub username."
    }
}

Write-Host "Configuring repository: $Owner/$Repo" -ForegroundColor Yellow
$allOk = $true

# 1. Core repository merge & feature settings
$repoBody = @{
    allow_squash_merge          = $true
    allow_merge_commit          = $false
    allow_rebase_merge          = $false
    delete_branch_on_merge      = $true
    allow_update_branch         = $true
    has_issues                  = $true
    has_projects                = $true
    has_wiki                    = $false
    squash_merge_commit_title   = "PR_TITLE"
    squash_merge_commit_message = "PR_BODY"
}
if (-not (Invoke-GhApi -GhPath $gh -Method PATCH -Endpoint "repos/$Owner/$Repo" -Body $repoBody -Label "Repository merge & feature settings")) {
    $allOk = $false
}

# 2. Security & analysis: Secret Scanning + Push Protection
$secBody = @{
    security_and_analysis = @{
        secret_scanning = @{
            status = "enabled"
        }
        secret_scanning_push_protection = @{
            status = "enabled"
        }
    }
}
if (-not (Invoke-GhApi -GhPath $gh -Method PATCH -Endpoint "repos/$Owner/$Repo" -Body $secBody -Label "Secret scanning & push protection")) {
    $allOk = $false
}

# 3. Dependabot vulnerability alerts
if (-not (Invoke-GhApi -GhPath $gh -Method PUT -Endpoint "repos/$Owner/$Repo/vulnerability-alerts" -Label "Dependabot vulnerability alerts")) {
    $allOk = $false
}

# 4. Dependabot automated security fixes
if (-not (Invoke-GhApi -GhPath $gh -Method PUT -Endpoint "repos/$Owner/$Repo/automated-security-fixes" -Label "Dependabot security updates")) {
    $allOk = $false
}

# 5. Private vulnerability reporting
if (-not (Invoke-GhApi -GhPath $gh -Method PUT -Endpoint "repos/$Owner/$Repo/private-vulnerability-reporting" -Label "Private vulnerability reporting")) {
    $allOk = $false
}

# 6. GitHub Actions workflow token permissions (least privilege)
$actionsBody = @{
    default_workflow_permissions    = "read"
    can_approve_pull_request_reviews = $false
}
if (-not (Invoke-GhApi -GhPath $gh -Method PUT -Endpoint "repos/$Owner/$Repo/actions/permissions/workflow" -Body $actionsBody -Label "GitHub Actions read-only permissions")) {
    $allOk = $false
}

# 7. Branch protection on `main`
$protectionBody = @{
    required_status_checks = @{
        strict   = $true
        contexts = @("repo-hygiene")
    }
    enforce_admins = $false
    required_pull_request_reviews = @{
        dismiss_stale_reviews           = $true
        require_code_owner_reviews      = $false
        required_approving_review_count = 0
        require_last_push_approval      = $false
    }
    restrictions                   = $null
    required_conversation_resolution = $true
    allow_force_pushes             = $false
    allow_deletions                = $false
}
if (-not (Invoke-GhApi -GhPath $gh -Method PUT -Endpoint "repos/$Owner/$Repo/branches/main/protection" -Body $protectionBody -Label "Branch protection on main")) {
    $allOk = $false
}

if (-not $allOk) {
    Write-Warning "One or more settings reported warnings above. Review the output to confirm account/plan support."
    exit 1
}

Write-Host "All GitHub repository, security, and branch protection settings applied successfully!" -ForegroundColor Green
