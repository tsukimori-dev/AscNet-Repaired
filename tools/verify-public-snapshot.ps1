[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Push-Location $repoRoot
try {
    $gitRoot = (& git rev-parse --show-toplevel).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitRoot)) {
        throw 'The verifier must be stored inside a Git worktree.'
    }
    if (-not [string]::Equals(
        [IO.Path]::GetFullPath($gitRoot).TrimEnd('\', '/'),
        [IO.Path]::GetFullPath($repoRoot).TrimEnd('\', '/'),
        [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The verifier resolved a different Git worktree than its own repository.'
    }

    $trackedFiles = @(& git ls-files)
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to enumerate tracked files.'
    }

    $forbiddenPathPatterns = [ordered]@{
        IdeState = '(^|/)\.idea/'
        MacMetadata = '(^|/)\.DS_Store$'
        LocalReports = '^docs/reports/'
        RuntimeResources = '^Resources/(Configs|Data|table)/'
        LocalHelpers = '(^|/)(proxylog|proxy\.py|run_steam\.py|launch-pgr-ascnet\.sh)$'
        ExtractionScripts = '^Scripts/'
        RuntimeArtifacts = '(?i)\.(exe|dll|pdb|dmp|zip|7z|tar|gz|pcap|db|sqlite|sqlite3|pem|key|p12|pfx|kdbx|msgpack|b64)$'
    }

    foreach ($rule in $forbiddenPathPatterns.GetEnumerator()) {
        $matches = @($trackedFiles | Where-Object { $_ -match $rule.Value })
        if ($matches.Count -gt 0) {
            throw "Forbidden tracked paths ($($rule.Key)): $($matches -join ', ')"
        }
    }

    $cacheFileMarker = 'KR' + 'SDK' + 'User' + 'Cache'
    $loginIdentityMarker = 'last' + '_login_' + 'cuid'
    $forbiddenContentPatterns = [ordered]@{
        PrivateKey = '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
        GitHubToken = '\b(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b'
        OpenAiKey = '\bsk-[A-Za-z0-9]{20,}\b'
        AwsAccessKey = '\b(AKIA|ASIA)[A-Z0-9]{16}\b'
        JsonWebToken = '\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b'
        CredentialInUri = '(https?|mongodb(\+srv)?):\/\/[^\/\s:@]+:[^\/\s@]+@'
        UserProfilePath = '(?i)[A-Z]:[\\/]Users[\\/]'
        LocalGamePath = '(?i)[A-Z]:[\\/][^\r\n]{0,120}Punishing Gray Raven'
        LoginCacheFile = [regex]::Escape($cacheFileMarker)
        LoginIdentityKey = [regex]::Escape($loginIdentityMarker)
    }

    foreach ($path in $trackedFiles) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            continue
        }

        $fileInfo = Get-Item -LiteralPath $path
        if ($fileInfo.Length -gt 8MB) {
            throw "Tracked file exceeds the public-snapshot size limit: $path"
        }

        try {
            $content = [IO.File]::ReadAllText($fileInfo.FullName)
        }
        catch {
            throw "Tracked file is not readable as text: $path"
        }

        foreach ($rule in $forbiddenContentPatterns.GetEnumerator()) {
            if ($content -match $rule.Value) {
                throw "Forbidden content category '$($rule.Key)' found in $path"
            }
        }
    }

    $schemaFiles = @($trackedFiles | Where-Object { $_ -match '^Schemas/table/.+\.tsv$' })
    if ($schemaFiles.Count -lt 70) {
        throw "Expected the compile-time schema set; found only $($schemaFiles.Count) TSV files."
    }

    foreach ($path in $schemaFiles) {
        $lines = @([IO.File]::ReadAllLines((Resolve-Path -LiteralPath $path)))
        if ($lines.Count -ne 3) {
            throw "Schema TSV must contain one header and two synthetic rows: $path"
        }

        foreach ($line in $lines | Select-Object -Skip 1) {
            foreach ($cell in $line.Split([char]9)) {
                if ($cell.Length -gt 0 -and $cell -ne '0' -and $cell -ne 'sample') {
                    throw "Non-synthetic schema value found in $path"
                }
            }
        }
    }

    & git diff --check
    if ($LASTEXITCODE -ne 0) {
        throw 'git diff --check failed.'
    }

    Write-Host "Public snapshot verification passed: $($trackedFiles.Count) tracked files, $($schemaFiles.Count) schema TSVs."
}
finally {
    Pop-Location
}
