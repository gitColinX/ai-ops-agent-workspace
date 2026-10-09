# AI Ops Agent Workspace

The instruction files and folder layout I use to work IT tickets with Claude Code, Codex and Warp.

I'm the only IT engineer on site at my employer's headquarters. We run a
hybrid Microsoft 365 tenant with about 1,100 Intune-managed devices. I use
Claude Code for most of the work, and when I hit my usage limit in the
middle of a ticket, I point Codex at the same folder and keep going. That
works because the rules and each ticket's status live in plain files that
every tool reads.

The same rules keep the agent in check. Changes start as a dry run, nothing
is written to production until I approve it, and the agent has to quote the
read-back before it can call anything verified.

## What's in here

- [AGENTS.md](AGENTS.md) - the rules every assistant reads first.
  [CLAUDE.md](CLAUDE.md), [CODEX.md](CODEX.md) and [WARP.md](WARP.md) add a
  few notes per tool.
- [examples/workbench/](examples/workbench/2026-01-01-example-ticket/) - a
  made-up ticket folder with status, findings and handoff files
- [examples/compliance-gate/](examples/compliance-gate/) - a PASS/FAIL check
  of new accounts against the onboarding runbook
- [examples/intake/](examples/intake/) - an Excel intake form that copies a
  request as text for the agent, so nobody pastes screenshots
- [examples/claude-settings.json](examples/claude-settings.json) - a Claude
  Code deny list based on mine
- [tools/Test-PublishReady.ps1](tools/Test-PublishReady.ps1) - the scan I
  ran on this repo before publishing it

## What it did at work

- I turned the company knowledge base, about 780 articles and 15,300
  attachments, into Markdown files the agent searches first. Answers cite
  the article number or say it was not found.
- New-hire accounts built from AI-generated steps slowly drifted from the
  onboarding runbook. I fixed 16 accounts and added two scripted PASS/FAIL
  checks. One later caught a problem on a real onboarding.
- When an offboarding showed a gap, I fixed the runbook. It now removes MFA
  methods instead of only revoking sessions, and checks all 1,278 mailboxes
  so no access is left behind.

## Try it

```powershell
pwsh -File tests/Invoke-Tests.ps1
```

Runs every check offline against made-up data. Needs PowerShell 7, plus
Python 3.10+ with openpyxl for the intake tests. 44 tests passed on
2026-10-09. The code is a rewrite of what I ran at work, written with
Claude Code, and this version has not touched a live tenant.

## More detail

- [Full write-up](docs/WRITEUP.md): problems I hit, results, and how to use
  the template
- Other docs: [how it evolved](docs/EVOLUTION.md),
  [switching assistants](docs/switching-assistants.md),
  [prompt patterns](docs/prompt-patterns.md),
  [guardrails](docs/guardrails.md)
- Related repos:
  [m365-graph-agent-ops](https://github.com/gitColinX/m365-graph-agent-ops),
  [kb-to-agent-corpus](https://github.com/gitColinX/kb-to-agent-corpus),
  [servicenow-claude-mcp](https://github.com/gitColinX/servicenow-claude-mcp),
  [intune-endpoint-engineering](https://github.com/gitColinX/intune-endpoint-engineering)

## About

Colin Lundholm, IT Support Engineer. [GitHub](https://github.com/gitColinX).
MIT licensed.
