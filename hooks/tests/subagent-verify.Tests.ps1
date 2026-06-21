# Pester tests for subagent-verify.ps1

BeforeAll {
    $script:HookPath = (Resolve-Path (Join-Path $PSScriptRoot '..' 'subagent-verify.ps1')).Path
    $script:ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..', '..')).Path
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

Describe 'subagent-verify.ps1' {

    Context 'circuit breaker' {
        It 'exits 0 immediately when SKIP_SUBAGENT_VERIFY=true' {
            $r = Invoke-Hook -Payload @{
                agent_type = 'story-master'
                cwd        = $script:ProjectRoot
            } -EnvVars @{ SKIP_SUBAGENT_VERIFY = 'true' }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Not -Match 'block'
        }
    }

    Context 'unknown / unregistered agent types' {
        It 'passes through for unknown agent type' {
            $r = Invoke-Hook -Payload @{
                agent_type = 'some-unknown-agent'
                cwd        = $script:ProjectRoot
            }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Not -Match 'block'
        }

        It 'passes through when no agent_type field' {
            $r = Invoke-Hook -Payload @{
                cwd = $script:ProjectRoot
            }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Not -Match 'block'
        }
    }

    Context 'story-master: no artifact dir' {
        It 'passes through when .copilot\stories directory does not exist' {
            # The hook only runs verifiers when the artifact dir exists.
            # The stories dir is unlikely to exist in a fresh clone, so this
            # should always pass without actually running verify_stories.py.
            $fakeCwd = [System.IO.Path]::GetTempPath()
            $r = Invoke-Hook -Payload @{
                agent_type = 'story-master'
                cwd        = $fakeCwd
            }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Not -Match 'block'
        }
    }

    Context 'story-planner: no artifact dir' {
        It 'passes through when .copilot\stories directory does not exist' {
            $fakeCwd = [System.IO.Path]::GetTempPath()
            $r = Invoke-Hook -Payload @{
                agent_type = 'story-planner'
                cwd        = $fakeCwd
            }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Not -Match 'block'
        }
    }

    Context 'story-master: artifact dir exists, verifier passes' {
        BeforeAll {
            # Scaffold a fake .copilot\stories dir so the hook enters the switch arm
            $script:FakeRoot = Join-Path ([System.IO.Path]::GetTempPath()) "svtest-$(Get-Random)"
            $script:StoriesDir = Join-Path $script:FakeRoot '.copilot\stories'
            New-Item -ItemType Directory -Force -Path $script:StoriesDir | Out-Null
            # Drop a stub verify_stories.py that always exits 0 (pass)
            $script:VerifyDir = Join-Path $script:FakeRoot 'skills\story-master\scripts'
            New-Item -ItemType Directory -Force -Path $script:VerifyDir | Out-Null
            Set-Content -Path (Join-Path $script:VerifyDir 'verify_stories.py') -Value 'import sys; sys.exit(0)'
        }
        AfterAll {
            Remove-Item $script:FakeRoot -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'exits 0 (no block) when verifier passes' {
            $r = Invoke-Hook -Payload @{
                agent_type = 'story-master'
                cwd        = $script:FakeRoot
            }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Not -Match '"decision".*"block"'
        }
    }

    Context 'story-master: artifact dir exists, verifier fails' {
        BeforeAll {
            $script:FakeRootFail = Join-Path ([System.IO.Path]::GetTempPath()) "svtest-fail-$(Get-Random)"
            $storiesDir2 = Join-Path $script:FakeRootFail '.copilot\stories'
            New-Item -ItemType Directory -Force -Path $storiesDir2 | Out-Null
            $verifyDir2 = Join-Path $script:FakeRootFail 'skills\story-master\scripts'
            New-Item -ItemType Directory -Force -Path $verifyDir2 | Out-Null
            # Stub verifier that always fails
            Set-Content -Path (Join-Path $verifyDir2 'verify_stories.py') -Value 'import sys; sys.exit(1)'
        }
        AfterAll {
            Remove-Item $script:FakeRootFail -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'emits block decision when verifier fails (block mode)' {
            $r = Invoke-Hook -Payload @{
                agent_type = 'story-master'
                cwd        = $script:FakeRootFail
            } -EnvVars @{ SUBAGENT_VERIFY_MODE = 'block' }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Match 'block'
        }

        It 'warns but does not block in warn mode' {
            $r = Invoke-Hook -Payload @{
                agent_type = 'story-master'
                cwd        = $script:FakeRootFail
            } -EnvVars @{ SUBAGENT_VERIFY_MODE = 'warn' }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Not -Match '"decision".*"block"'
        }
    }

    Context 'story-planner: artifact dir exists, verifier passes' {
        BeforeAll {
            $script:FakePlanRoot = Join-Path ([System.IO.Path]::GetTempPath()) "svtest-plan-$(Get-Random)"
            $storiesDir3 = Join-Path $script:FakePlanRoot '.copilot\stories'
            New-Item -ItemType Directory -Force -Path $storiesDir3 | Out-Null
            $planDir = Join-Path $script:FakePlanRoot 'skills\story-planner\scripts'
            New-Item -ItemType Directory -Force -Path $planDir | Out-Null
            Set-Content -Path (Join-Path $planDir 'verify_plan.py') -Value 'import sys; sys.exit(0)'
            Set-Content -Path (Join-Path $planDir 'verify_validation.py') -Value 'import sys; sys.exit(0)'
        }
        AfterAll {
            Remove-Item $script:FakePlanRoot -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'exits 0 when both plan verifiers pass' {
            $r = Invoke-Hook -Payload @{
                agent_type = 'story-planner'
                cwd        = $script:FakePlanRoot
            }
            $r.ExitCode | Should -Be 0
            $r.Stdout | Should -Not -Match '"decision".*"block"'
        }
    }
}
