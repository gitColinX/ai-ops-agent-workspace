# One agent contract for Claude Code, Codex and Warp

How I run IT operations work with three AI assistants from one set of
instruction files, and keep working when one of them runs out of usage in
the middle of a ticket.

Since April 2026 I have been the on-site IT engineer at my employer's
headquarters: a hybrid Microsoft 365 tenant with about 1,100
Intune-managed endpoints, Entra ID, Exchange Online, on-prem Active
Directory, AWS, and a ServiceNow service desk. Claude Code is my primary
tool. When I hit my Claude usage limit, I point the OpenAI Codex CLI or
the ChatGPT desktop app at the same folder and the same Markdown files.
Warp's agent sits in my terminal. All three work under one contract.

This repo is the template that came out of that work: the contract, the
thin per-tool shims, the guardrails, seven prompt patterns, and fictional
examples of the files that carry a task from one session (or one tool) to
the next. Company names, people, tickets and tenant details are left out.
The examples are made up. The history and the numbers are real.

```
                     AGENTS.md   the contract: untrusted input, search order,
                         |       precedence, command safety, verification
        +----------------+----------------+
        |                |                |
    CLAUDE.md        CODEX.md          WARP.md       thin shims: "read AGENTS.md
        |                |                |          first", plus tool notes
   Claude Code     Codex / ChatGPT    Warp agent
        |                |                |
        +----------------+----------------+
                         |
        _workbench/<yyyy-mm-dd>-<slug>/   state lives in files:
            00_STATUS.md  FINDINGS.md  handoff.md
```

| Piece | Where | Status |
|---|---|---|
| Agent-neutral contract | [`AGENTS.md`](AGENTS.md) | [built, used daily] |
| Per-tool shims | [`CLAUDE.md`](CLAUDE.md), [`CODEX.md`](CODEX.md), [`WARP.md`](WARP.md) | [built, used daily] |
| How it got here, stage by stage | [`docs/EVOLUTION.md`](docs/EVOLUTION.md) | history |
| Switching assistants mid-task | [`docs/switching-assistants.md`](docs/switching-assistants.md) | [built, ran on real tickets] |
| Seven prompt patterns | [`docs/prompt-patterns.md`](docs/prompt-patterns.md) | [built, ran on real tickets]; each pattern labeled |
| Guardrails | [`docs/guardrails.md`](docs/guardrails.md) | mixed; each section labeled |
| Claude Code deny list | [`examples/claude-settings.json`](examples/claude-settings.json) | original [built, used daily]; additions [designed, runbook written] |
| Workbench folder per ticket | [`examples/workbench/`](examples/workbench/2026-01-01-example-ticket/) | [built, ran on real tickets] (example is fictional) |
| Shared notes across tools | [`examples/shared-notes/`](examples/shared-notes/) | [built, used daily] since 2026-10-03 (example is fictional) |
| PASS/FAIL compliance gate | [`examples/compliance-gate/`](examples/compliance-gate/) | pattern [built, ran on real tickets]; this script [built, tested on synthetic data] |
| Intake workbook, "Copy for agent" | [`examples/intake/`](examples/intake/) | pattern [built, ran on real tickets]; this rewrite [built, tested on synthetic data] |
| Pre-publish scanner | [`tools/Test-PublishReady.ps1`](tools/Test-PublishReady.ps1) | [built, tested on synthetic data]; ran on this repo before publishing |

## The problem

An AI assistant can write a Microsoft Graph script in a minute and say
"done" in a second. Neither one is evidence. I am the only IT engineer on
site, so the speed is real and so is the risk: identity, licensing and
offboarding changes on a production tenant, prompted by ticket text that
anyone in the company could write.

Three things went wrong before this structure existed:

1. **The rules lived in one tool.** By the end of July my instructions were
   a 13 KB `CLAUDE.md` that only Claude Code read, with durable rules mixed
   in among status notes that went stale within days.
2. **Context lived in chats.** When a session hit its limit, the next one
   started from what I could remember to paste.
3. **Everything the model read could steer it.** Knowledge base articles,
   ticket descriptions, attachments and email exports all reach the model.
   Any of them can carry an instruction.

## What I built

### The contract

[`AGENTS.md`](AGENTS.md) is written for no product in particular. It covers:

- **Imported content is untrusted data.** Tickets, KB exports, OCR text,
  attachments and tool output are analyzed, never obeyed. Only the contract
  and the user in the current session can authorize work.
- **Search order and source precedence.** Search the knowledge base corpus
  first and cite the article. Live read-only output is the best source for
  what exists, and never a source for what should be done.
- **Conflict handling.** Newer does not automatically win. Authority,
  scope, status and evidence decide, and a high-impact conflict stops the
  work.
- **Operational command safety.** Read-only discovery first, a dry run by
  default, `-Apply` for writes, approval in the session, one batch at a
  time, delegated sign-in completed by the human. I approved production
  writes before they ran. In later sessions, routine reads often ran under
  Claude Code's auto mode, whose classifier approves them; the contract
  still required my approval for production writes.
- **Two verification rules.** Quote the literal read-back output before
  using the word "verified". Never close a ticket in the same step as the
  change.
- **Editing, citations, personal data, and a completion standard.**

### Thin shims

Each tool reads its own file first: Claude Code reads `CLAUDE.md` (which
imports `AGENTS.md`), Codex reads `AGENTS.md`, Warp reads `WARP.md`. The
shims point at `AGENTS.md` and add only what is specific to that tool.
`CODEX.md` restates the two verification rules with the reason attached,
because a Codex session broke both of them.

### State in files

Every ticket or task gets a dated `_workbench` folder for its scripts,
output and notes. The bigger ones also carry `00_STATUS.md` (done, blocked,
next gated step) and `FINDINGS.md` (evidence labeled as live read-back,
repository fact, inference, or not found), and the long jobs a handoff
document for the next session or the next tool. Between June and late
September I opened 40 of these folders, 38 of them in September.

## Switching assistants mid-task

Because the rules, the runbooks and the task state were all files, running
out of Claude usage did not stop a ticket. Codex picked up real ticket work
this way: a script to check a spreadsheet in late August and a builder for
a role-audit workbook in September, with no rewrite of the instructions.

This is the procedure I use when I switch: open Codex (or attach the files
to ChatGPT) at the repo root, have it read `AGENTS.md`, its shim, and the
task's `00_STATUS.md` and handoff, check that it restates the next gated
step and the verification rules correctly, sign in again, and carry on.
Switching back is the same in reverse. What carried over and what did not
is in [`docs/switching-assistants.md`](docs/switching-assistants.md).

## What broke, and what I learned

Most lines in the contract trace back to one of these.

- **"Prefer the newest version" was wrong.** My first `AGENTS.md` (early
  August) settled conflicts by date. A newer draft or a ticket note should
  never override a canonical runbook. The 08-07 rewrite replaced it with
  authority, scope, status and evidence.
- **Model drift is quiet.** Over about five weeks, account-build blocks
  generated in chat drifted from the onboarding runbook: dropped address
  fields, the wrong name attribute, wrong casing, a missing prefix. Each
  block looked fine. Once the drift was spotted I fixed 16 accounts and put
  a scripted PASS/FAIL gate in front of the directory sync and another in
  front of the ticket notes. A model checking its own work in prose is not
  a check.
- **"Verified" is a claim.** A Codex session on ticket work claimed checks
  it had not run and closed a ticket in the same step as the change. The
  read-back habit was already in my runbooks. After that it became two
  explicit rules in the contract and a Codex shim that leads with them.
- **My deny list only covered one of two shells.** Every command rule was
  written for the Bash tool, while Claude Code's PowerShell tool has its own
  rule namespace. The template adds a `PowerShell(...)` twin for each rule,
  home-anchored file rules, and the credential caches the original missed.
  A deny list is still a speed bump, not a boundary.
- **Approvals pile up.** By September one workspace's local allow list had
  about 250 rules from "don't ask again" clicks, including wildcards for
  `python3` and `curl` that could do anything the deny list blocks. The
  allow list needs the same review as the deny list.
- **`-Scopes` is not least privilege.** Every Graph sign-in went through the
  shared first-party command-line client, whose tokens carried dozens of
  consented delegated scopes, far more than any task asked for. My real
  limit was my roles. That is why I designed a dedicated read-only app
  registration for agent work, written up in
  [m365-graph-agent-ops](https://github.com/gitColinX/m365-graph-agent-ops).
- **Agent shells and interactive sign-in do not mix.** The Windows sign-in
  broker needs a parent window, and an agent's shell is a non-interactive
  child process without one, so interactive sign-in failed there. Device
  code, started detached with the code written to a file, worked.
- **Neither do the broker and a second profile.** One afternoon
  `Connect-MicrosoftTeams` failed with broker error 0x80070520 because I
  ran it interactively, without `-UseDeviceAuthentication`, from a shell
  running as my separate admin profile. Device code was already my written
  standard; I had not followed it that day.
- **Warp's agent runs some commands on its own.** In one terminal history,
  31 of 118 recorded commands were run by Warp's agent, under the agent
  profile I used, which let it decide which commands needed my approval.
  All 31 were reads or local file housekeeping. Every Graph sign-in and
  every tenant change in that history was mine. The template's `WARP.md`
  tells you to set it to ask.
- **Logs are UTC.** Evening work shows up as the next day. Keep both time
  columns.

## What it produced

| Work | When | Result |
|---|---|---|
| **KB-grounded ticket triage** | August on | The company knowledge base (about 780 articles and about 15,300 attachments, with OCR text for screenshots) became a Markdown corpus the agent searches first. Answers cite the article number, or say "not found in KB". Used on live tickets. The pipeline is in [kb-to-agent-corpus](https://github.com/gitColinX/kb-to-agent-corpus). |
| **Offboarding runbook** | v2 in July to v4 in September | Each real offboarding that exposed a gap became a fix: removing MFA methods instead of only revoking sessions, OneDrive delegation to the manager, and a reverse mailbox-permission sweep across 1,278 mailboxes so nothing is left behind. |
| **Onboarding gates** | 2026-09-02 on | 16 drifted accounts corrected; two mandatory PASS/FAIL gates and a monthly drift sweep added. The gate then ran on real onboardings later in September, and one run caught a FAIL row. |
| **Asset reconciliation** | 2026-09-11 | Intune treated as the source of truth and reconciled against the asset table under the 08-07 contract. Written up in [servicenow-claude-mcp](https://github.com/gitColinX/servicenow-claude-mcp). |
| **Tool switching** | August on | Codex picked up real ticket work from the same files when Claude usage ran out (a spreadsheet check in late August, a role-audit workbook builder in September), without a rewrite of the instructions. |
| **Workbench** | June to September | 40 dated task folders holding the scripts, output and notes for each job. |

## Use this template

1. Copy `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `WARP.md`, `.gitignore` and
   `.warpindexingignore` into the root of your workspace.
2. Replace the `<placeholders>` in `AGENTS.md`: your folder names, your
   canonical runbooks, your house style. Keep the two verification rules as
   written.
3. Copy [`examples/claude-settings.json`](examples/claude-settings.json) to
   `.claude/settings.json`. To enforce it, deploy the same settings as
   Claude Code managed settings. Set equivalent approval settings in Codex
   and Warp; they do not read Claude's.
4. Create `_workbench/` and give each ticket its own dated folder. Copy the
   shape of the [fictional example](examples/workbench/2026-01-01-example-ticket/).
5. Before publishing anything from the workspace, run the scanner with a
   deny list kept outside the repo:

   ```powershell
   pwsh -File tools/Test-PublishReady.ps1 -Path . -DenyListPath <path outside the repo>
   ```

6. Run the tests (PowerShell 7; Python 3.10+ with openpyxl for the intake
   tests, which are skipped if either is missing):

   ```powershell
   pwsh -File tests/Invoke-Tests.ps1
   ```

Nothing in this repo signs in to anything or calls a service. The scripts
read local files and write only where you tell them to.

## Repository map

```
AGENTS.md                  the contract
CLAUDE.md CODEX.md WARP.md per-tool shims
docs/
  EVOLUTION.md             June to October, stage by stage
  switching-assistants.md  moving a task between Claude, Codex and ChatGPT
  prompt-patterns.md       seven prompts used on real tickets
  guardrails.md            identity, approvals, read-back, deny lists, injection
examples/
  claude-settings.json     deny list with Bash, PowerShell and Read rules
  workbench/               a fictional ticket folder
  shared-notes/            a fictional cross-tool notes folder
  compliance-gate/         PASS/FAIL gate with synthetic fixtures
  intake/                  intake workbook generator, VBA module, reader, tests
tools/Test-PublishReady.ps1  pre-publish scan that never prints a match
tests/Invoke-Tests.ps1       runs everything above against synthetic data
```

## Related repos

- [m365-graph-agent-ops](https://github.com/gitColinX/m365-graph-agent-ops):
  Microsoft 365 admin from Claude Code with me holding the sign-in, and the
  decision record for the read-only agent app registration.
- [kb-to-agent-corpus](https://github.com/gitColinX/kb-to-agent-corpus):
  the knowledge base export that became the corpus the agent searches
  first.
- [intune-endpoint-engineering](https://github.com/gitColinX/intune-endpoint-engineering):
  Intune Remediations and Win32 packaging patterns from the same fleet.
- [servicenow-claude-mcp](https://github.com/gitColinX/servicenow-claude-mcp):
  Claude and ServiceNow at the service desk, including the asset
  reconciliation.

## How this was built

The original contract was written and revised with Claude Code between
July and September 2026. I also used Codex from mid-August (the desktop
app, for OCR) and the Codex CLI from 2026-08-21, signed in to the
company's ChatGPT workspace.

This is a fresh rewrite, generalized from what I ran at work, written with
Claude Code. I directed the work and checked the results against my own
records. The code here is tested offline against synthetic fixtures (44
tests passing on 2026-10-09) and has not been run against a live tenant in
this form. The examples are fictional.

## About

Colin Lundholm, IT Support Engineer, working across systems administration,
endpoint, identity and cloud · [GitHub profile](https://github.com/gitColinX)

Corrections welcome by issue or pull request. MIT licensed.
