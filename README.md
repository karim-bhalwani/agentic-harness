# Copilot Skills, Hooks & Agents Collection

![Version](https://img.shields.io/badge/version-9.0-blue)
![Status](https://img.shields.io/badge/status-Production%20Ready-brightgreen)
![Domain](https://img.shields.io/badge/domain-Data%20%2B%20AI%20Engineering-9933ff)
![Python](https://img.shields.io/badge/python-3.11%2B-blue)
![VS Code](https://img.shields.io/badge/VS%20Code-Copilot%20Compatible-0078d4)
![Agents](https://img.shields.io/badge/agents-16-blue)
![Skills](https://img.shields.io/badge/skills-25-blue)
![Hooks](https://img.shields.io/badge/hooks-14-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**Architect:** Karim Bhalwani | **Version:** 9.0 | **Updated:** 01-July-2026

---

## What Is This?

A production-ready **multi-agent development crew** for GitHub Copilot in VS Code. Instead of one general-purpose AI, you get 16 specialized agents that collaborate through a shared pipeline: discover → design → (plan) → build → review → ship.

Each agent has a defined role, knows its limits, and hands work off to the next agent in the chain. Domain knowledge lives in 25 on-demand skills. Quality invariants are enforced by 13 platform-level hooks that the model cannot override.

> **How counts are tallied:** headline numbers track files on disk, one `*.agent.md` per agent (the hidden `researcher` is included), one `skills/<name>/` directory per skill, one `*.prompt.md` per prompt, and one `*.ps1` per hook. The `audit.py` count-sync check fails the build if any badge or tagline drifts from these counts.

**The short version:** spec before code, one agent per phase, hooks enforce what instructions can't.

---

## What's Included

| Component                                             | Count | What it does                                                                                                                  |
| ----------------------------------------------------- | ----- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Agents** (`.agent.md`) & **Prompts** (`.prompt.md`) | 16+13 | Specialized personas (architect, senior-developer, guardian, etc.) + slash commands (/design, /code-review, /quick-fix, etc.) |
| **Skills** (`SKILL.md`)                               | 25    | Domain knowledge packs loaded on demand: data-engineering, genai-security, implementer, etc.                                  |
| **Instructions** (`.instructions.md`)                 | 4     | Global rules auto-applied to every session (core behavior, Python, SQL, YAML standards)                                       |
| **Hooks** (`.ps1`)                                    | 14    | Platform-level enforcement: quality gates, secrets scan, destructive command blocking, etc.                                   |

---

## Installation

### 1. Prerequisites

- VS Code 1.118+ with GitHub Copilot
- [UV](UV-GUIDE.md)  -  Python package manager (`irm https://astral.sh/uv/install.ps1 | iex`)

### 2. Install agents & prompts

```powershell
$profilePath = "$env:APPDATA\Code\User\prompts"
New-Item -ItemType Directory -Path $profilePath -Force
Copy-Item -Path ".\prompts\*" -Destination $profilePath -Recurse -Force
```

### 3. Install instructions

```powershell
$instructionsPath = "$env:USERPROFILE\.copilot\instructions"
New-Item -ItemType Directory -Path $instructionsPath -Force
Copy-Item -Path ".\instructions\*" -Destination $instructionsPath -Recurse -Force
```

### 4. Install skills

```powershell
$skillsPath = "$env:USERPROFILE\.copilot\skills"
New-Item -ItemType Directory -Path $skillsPath -Force
Copy-Item -Path ".\skills\*" -Destination $skillsPath -Recurse -Force
```

### 5. Install hooks

```powershell
$hooksPath = "$env:USERPROFILE\.copilot\hooks"
New-Item -ItemType Directory -Path $hooksPath -Force
Copy-Item -Path ".\hooks\*" -Destination $hooksPath -Force
Get-ChildItem "$hooksPath\*" | Unblock-File
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Verify: open Copilot Chat → Command Palette → "Chat: Configure Hooks". You should see 14 hooks registered.

> Full hook setup and troubleshooting: [hooks/INSTALL.md](hooks/INSTALL.md)

---

## Where to Go Next

| I want to...                            | Read this                                    |
| --------------------------------------- | -------------------------------------------- |
| Get started and run my first agent      | [USER-GUIDE.md](USER-GUIDE.md)               |
| Copy-paste prompts for every agent      | [PROMPT-CHEATSHEET.md](PROMPT-CHEATSHEET.md) |
| See the full agent catalog and pipeline | [MEGA-MINIONS.md](MEGA-MINIONS.md)           |
| Understand the architecture and design  | [ARCHITECTURE.md](ARCHITECTURE.md)           |
| Learn the philosophy behind the system  | [CORE_PRINCIPLES.md](CORE_PRINCIPLES.md)     |
| Set up a project knowledge mem          | [LLM-MEM-GUIDE.md](LLM-MEM-GUIDE.md)         |
| Set up UV / Python tooling              | [UV-GUIDE.md](UV-GUIDE.md)                   |
| Understand what hooks do                | [hooks/README.md](hooks/README.md)           |
| Install and configure hooks             | [hooks/INSTALL.md](hooks/INSTALL.md)         |

---

## License

MIT License. You are free to use, modify, and distribute this project for commercial and non-commercial purposes.
