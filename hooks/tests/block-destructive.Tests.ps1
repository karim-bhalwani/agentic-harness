# Pester tests for block-destructive.ps1

BeforeAll {
    $script:HookPath = (Resolve-Path (Join-Path $PSScriptRoot '..' 'block-destructive.ps1')).Path
    Unblock-File -Path $script:HookPath -ErrorAction SilentlyContinue

    function script:Invoke-Hook {
        param(
            [Parameter(Mandatory)] $Payload,
            [hashtable] $EnvVars = @{}
        )
        $json = $Payload | ConvertTo-Json -Depth 10 -Compress
        $original = @{}
        foreach ($k in $EnvVars.Keys) {
            $original[$k] = [Environment]::GetEnvironmentVariable($k)
            [Environment]::SetEnvironmentVariable($k, $EnvVars[$k])
        }
        try {
            # Use cmd shell pipe: PowerShell-to-pwsh stdin piping is unreliable, but cmd's pipe is reliable
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
}

Describe 'block-destructive.ps1' {

    Context 'dangerous commands' {
        It 'blocks rm -rf' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'rm -rf /tmp/foo' }
            }
            # Note: /tmp/ also matches the temp bypass; use a non-temp path
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'rm -rf C:\Users\me\project' }
            }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Match 'permissionDecision'
            $r.Stdout | Should -Match 'deny'
        }

        It 'blocks DROP TABLE' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'sqlcmd -Q "DROP TABLE users"' }
            }
            $r.Stdout | Should -Match 'deny'
        }

        It 'blocks git push --force' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'git push --force origin main' }
            }
            $r.Stdout | Should -Match 'deny'
        }

        It 'blocks Remove-Item -Recurse without -Force' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'Remove-Item -Recurse C:\Users\me\project' }
            }
            $r.Stdout | Should -Match 'deny'
        }

        It 'blocks Remove-Item with params reordered (-Force -Recurse)' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'Remove-Item -Force -Recurse C:\Users\me\project' }
            }
            $r.Stdout | Should -Match 'deny'
        }

        It 'blocks Clear-Content' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'Clear-Content C:\project\config.json' }
            }
            $r.Stdout | Should -Match 'deny'
        }

        It 'blocks reg delete' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'reg delete HKLM\SOFTWARE\MyApp /f' }
            }
            $r.Stdout | Should -Match 'deny'
        }

        It 'blocks diskpart' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'diskpart' }
            }
            $r.Stdout | Should -Match 'deny'
        }

        It 'blocks cipher /w' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'cipher /w:C:\' }
            }
            $r.Stdout | Should -Match 'deny'
        }
    }

    Context 'temp-dir bypass' {
        It 'allows Remove-Item under \\Temp\\' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'Remove-Item -Recurse -Force C:\Temp\scratch-1234' }
            }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Not -Match 'deny'
        }

        It 'allows scaffold-test-* paths' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'Remove-Item -Recurse -Force C:\Temp\scaffold-test-9999' }
            }
            $r.Stdout | Should -Not -Match 'deny'
        }
    }

    Context 'safe commands' {
        It 'passes through harmless commands' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'ls -la' }
            }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Not -Match 'deny'
        }

        It 'ignores non-terminal tool calls' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'read_file'
                tool_input = @{ filePath = 'README.md' }
            }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Not -Match 'deny'
        }
    }

    Context 'circuit breakers' {
        It 'respects SKIP_DESTRUCTIVE_GUARD=true' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'rm -rf C:\Users\me\project' }
            } -EnvVars @{ SKIP_DESTRUCTIVE_GUARD = 'true' }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Not -Match 'deny'
        }

        It 'respects TOOL_GUARD_ALLOWLIST' {
            $r = Invoke-Hook -Payload @{
                tool_name  = 'run_in_terminal'
                tool_input = @{ command = 'rm -rf C:\Users\me\my-safe-cleanup-script-output' }
            } -EnvVars @{ TOOL_GUARD_ALLOWLIST = 'my-safe-cleanup-script' }
            $r.Stdout | Should -Not -Match 'deny'
        }
    }
}
