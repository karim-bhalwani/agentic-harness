# Pester tests for artifact-manifest.ps1

BeforeAll {
    $script:HookPath = (Resolve-Path (Join-Path $PSScriptRoot '..' 'artifact-manifest.ps1')).Path
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
    # Redirect the manifest to a temp file so tests never pollute the real one.
    $script:ManifestPath = Join-Path ([System.IO.Path]::GetTempPath()) "amtest-$(Get-Random).jsonl"

    function script:Invoke-Hook {
        param(
            [Parameter(Mandatory)] $Payload,
            [hashtable] $EnvVars = @{}
        )
        # Always redirect output to the temp manifest unless a test overrides it.
        if (-not $EnvVars.ContainsKey('ARTIFACT_MANIFEST_PATH')) {
            $EnvVars = $EnvVars.Clone()
            $EnvVars['ARTIFACT_MANIFEST_PATH'] = $script:ManifestPath
        }
        $json = $Payload | ConvertTo-Json -Depth 10 -Compress
        $original = @{}
        foreach ($k in $EnvVars.Keys) {
            $original[$k] = [Environment]::GetEnvironmentVariable($k)
            [Environment]::SetEnvironmentVariable($k, $EnvVars[$k])
        }
        try {
            $tmp = [System.IO.Path]::GetTempFileName()
            try {
                [System.IO.File]::WriteAllText($tmp, $json)
                $stdout = & cmd /c "type `"$tmp`" | pwsh -NoProfile -File `"$script:HookPath`" 2>&1" | Out-String
                return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Stdout = $stdout }
            }
            finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
        }
        finally {
            foreach ($k in $original.Keys) {
                [Environment]::SetEnvironmentVariable($k, $original[$k])
            }
        }
    }

    function script:Get-LastEntry {
        if (-not (Test-Path $script:ManifestPath)) { return $null }
        $line = Get-Content $script:ManifestPath -Tail 1
        if ([string]::IsNullOrWhiteSpace($line)) { return $null }
        return $line | ConvertFrom-Json
    }
}

AfterAll {
    if (Test-Path $script:ManifestPath) { Remove-Item $script:ManifestPath -Force -ErrorAction SilentlyContinue }
}

Describe 'artifact-manifest.ps1' {

    Context 'tool filtering' {
        It 'ignores non-write tools (exits 0, no entry)' {
            $before = if (Test-Path $script:ManifestPath) { (Get-Item $script:ManifestPath).Length } else { 0 }
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'echo hi' }
            }
            $r.ExitCode | Should -Be 0
            $after = if (Test-Path $script:ManifestPath) { (Get-Item $script:ManifestPath).Length } else { 0 }
            $after | Should -Be $before
        }

        It 'ignores when tool_input has no path (exits 0)' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'create_file'
                tool_input = @{ content = 'hi' }
            }
            $r.ExitCode | Should -Be 0
        }
    }

    Context 'role assignment' {
        It 'assigns role=artifact for files under artifacts/' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'create_file'
                tool_input = @{ filePath = 'artifacts/foo.md' }
            } -EnvVars @{ AGENT_ID = 'pester' }
            $r.ExitCode | Should -Be 0
            $entry = Get-LastEntry
            $entry.role | Should -Be 'artifact'
            $entry.path | Should -Be 'artifacts/foo.md'
            $entry.agent | Should -Be 'pester'
            $entry.tool | Should -Be 'create_file'
        }

        It 'assigns role=state for files under .copilot/state/' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'replace_string_in_file'
                tool_input = @{ filePath = '.copilot/state/SESSION_STATE.md' }
            } -EnvVars @{ AGENT_ID = 'pester' }
            $r.ExitCode | Should -Be 0
            (Get-LastEntry).role | Should -Be 'state'
        }

        It 'assigns role=scratch for files under scratch/ or tmp/' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'create_file'
                tool_input = @{ filePath = 'scratch/notes.txt' }
            } -EnvVars @{ AGENT_ID = 'pester' }
            (Get-LastEntry).role | Should -Be 'scratch'
        }

        It 'assigns role=source for code files like src/module.py' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'create_file'
                tool_input = @{ filePath = 'src/module.py' }
            } -EnvVars @{ AGENT_ID = 'pester' }
            (Get-LastEntry).role | Should -Be 'source'
        }

        It 'assigns role=unknown for everything else' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'create_file'
                tool_input = @{ filePath = 'data/raw.csv' }
            } -EnvVars @{ AGENT_ID = 'pester' }
            (Get-LastEntry).role | Should -Be 'unknown'
        }
    }

    Context 'circuit breaker' {
        It 'skips entirely when SKIP_ARTIFACT_MANIFEST=true' {
            $before = if (Test-Path $script:ManifestPath) { (Get-Item $script:ManifestPath).Length } else { 0 }
            $r = Invoke-Hook -Payload @{
                tool_name  = 'create_file'
                tool_input = @{ filePath = 'artifacts/should-not-record.md' }
            } -EnvVars @{ SKIP_ARTIFACT_MANIFEST = 'true'; AGENT_ID = 'pester' }
            $r.ExitCode | Should -Be 0
            $after = if (Test-Path $script:ManifestPath) { (Get-Item $script:ManifestPath).Length } else { 0 }
            $after | Should -Be $before
        }
    }

    Context 'entry schema' {
        It 'records all required fields including op, session, bytes' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'multi_replace_string_in_file'
                tool_input = @{ filePath = 'src/x.py' }
                session_id = 'abcdef1234567890'
            } -EnvVars @{ AGENT_ID = 'pester' }
            $r.ExitCode | Should -Be 0
            $entry = Get-LastEntry
            $entry.timestamp | Should -Not -BeNullOrEmpty
            $entry.agent | Should -Be 'pester'
            $entry.tool | Should -Be 'multi_replace_string_in_file'
            $entry.path | Should -Be 'src/x.py'
            $entry.role | Should -Be 'source'
            $entry.op | Should -Be 'edit'
            $entry.session | Should -Be 'abcdef12'
            $entry.PSObject.Properties.Name | Should -Contain 'bytes'
        }

        It 'records op=create for create_file' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'create_file'
                tool_input = @{ filePath = 'src/new.py' }
            } -EnvVars @{ AGENT_ID = 'pester' }
            (Get-LastEntry).op | Should -Be 'create'
        }

        It 'normalises backslashes to forward slashes' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'create_file'
                tool_input = @{ filePath = 'artifacts\sub\file.txt' }
            } -EnvVars @{ AGENT_ID = 'pester' }
            (Get-LastEntry).path | Should -Be 'artifacts/sub/file.txt'
        }

        It 'strips the project root prefix to record a repo-relative path' {
            $abs = Join-Path $script:RepoRoot 'artifacts\abs-leak.md'
            $r = Invoke-Hook -Payload @{
                tool_name  = 'create_file'
                tool_input = @{ filePath = $abs }
            } -EnvVars @{ AGENT_ID = 'pester' }
            $entry = Get-LastEntry
            $entry.path | Should -Be 'artifacts/abs-leak.md'
            $entry.path | Should -Not -Match '^[A-Za-z]:'
        }
    }

    Context 'agent identity fallback' {
        It 'falls back to .copilot/state/.active-agent when no agent field is supplied' {
            $activeAgent = Join-Path $script:RepoRoot '.copilot\state\.active-agent'
            $existed = Test-Path $activeAgent
            $backup = if ($existed) { Get-Content $activeAgent -Raw } else { $null }
            $stateDir = Split-Path -Parent $activeAgent
            if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
            Set-Content -Path $activeAgent -Value 'fallback-agent' -NoNewline
            try {
                $r = Invoke-Hook -Payload @{
                    tool_name  = 'create_file'
                    tool_input = @{ filePath = 'artifacts/from-fallback.md' }
                }
                $r.ExitCode | Should -Be 0
                (Get-LastEntry).agent | Should -Be 'fallback-agent'
            }
            finally {
                if ($existed) { Set-Content -Path $activeAgent -Value $backup -NoNewline }
                else { Remove-Item $activeAgent -Force -ErrorAction SilentlyContinue }
            }
        }
    }
}
