# Switching assistants mid-task

Claude Code is my primary tool. When I run out of Claude usage in the
middle of a ticket, I point the OpenAI Codex CLI or the ChatGPT desktop
app at the same folder and the same Markdown files and keep going. When
Claude is available again, I switch back the same way. This page is how
that works and what does not carry over.

Status: [built, ran on real tickets]. Codex did real ticket work this way
in late August and September, signed in to the company's ChatGPT
workspace. The step list below is the procedure I use now. The
verification check in step 4 dates from mid to late September, when those
two rules went into the contract.

The short version: it worked because nothing important lived in a chat.
The rules were in `AGENTS.md`, the procedures were in runbooks, and the
state of the task was in a dated `_workbench` folder. Whichever assistant
was in front of me read the same files.

## What each tool reads

As of the versions I used between August and October 2026. Check your own
version, because these behaviors change.

| Tool | Reads on its own | How it gets the contract |
|---|---|---|
| Claude Code | `CLAUDE.md` in the repo (and a user-level one in `~/.claude/`) | `CLAUDE.md` imports it with an `@AGENTS.md` line |
| Codex CLI | `AGENTS.md` | Natively. `AGENTS.md` then tells it to read `CODEX.md` |
| Warp's agent | `WARP.md` as project rules | `WARP.md` says "read AGENTS.md first" |
| ChatGPT desktop app | Nothing from the repo by default | Attach or paste `AGENTS.md`, `CODEX.md`, the task's `handoff.md`, and the one runbook it needs |

Codex reads `AGENTS.md` but not `CODEX.md`, so `AGENTS.md` names each
tool's file and tells the assistant to read its own. That one line is the
whole routing mechanism.

## The switch, step by step (the procedure I use)

1. **Save state before the limit hits.** Every gate in a task updates
   `00_STATUS.md` (done, blocked, next gated step). If the outgoing session
   still has room, ask it for a `handoff.md`:

   ```text
   Update 00_STATUS.md and write handoff.md in this task's _workbench
   folder. Use the format: topic and purpose, decisions locked in, current
   status (done, in progress, blocked), the exact next step and its gate,
   open questions and gotchas. Quote the last read-back output you have.
   Do not run anything else.
   ```

   If the session is already out of usage, `00_STATUS.md` is enough to
   write the handoff by hand.

2. **Open the incoming tool at the repository root**, not inside the
   workbench folder, so it finds `AGENTS.md`.

3. **First prompt to the incoming assistant:**

   ```text
   Read AGENTS.md and your per-tool file, then
   _workbench/<yyyy-mm-dd-slug>/00_STATUS.md and handoff.md.
   Tell me in five lines or fewer: what is done, what is blocked, the next
   gated step, and which two rules in AGENTS.md govern verification and
   closing. Do not run or change anything yet.
   ```

4. **Check the restatement.** It should name the next gated step correctly
   and restate the read-back and close rules. If it gets either wrong, stop
   and correct it before anything runs.

5. **Sign in again.** Each tool runs its own shell process. My Graph and
   Exchange sessions were process-scoped, so a sign-in done in Claude
   Code's shell did not exist in Codex's shell. Plan for a fresh delegated
   device-code sign-in after every switch.

6. **Continue under the same gates.** Dry run, approval, apply, read-back,
   then close as a separate step.

Switching back is the same sequence in reverse.

## What carried over and what did not

| Carried over (files) | Did not carry over |
|---|---|
| The contract and per-tool notes | Chat memory and anything said only in the old session |
| Runbooks and the knowledge base corpus | Claude Code's permission rules (each tool has its own approval model) |
| `00_STATUS.md`, `FINDINGS.md`, `handoff.md` | Signed-in sessions and cached tokens |
| Scripts and their saved output | Tool-specific memory (Claude Code auto-memory is not visible to Codex) |

The permission gap matters most. My Claude Code deny list did nothing for
Codex. For Codex I relied on its Windows sandbox and the defaults for a
trusted folder, which in the CLI versions I know mean the workspace-write
sandbox with approvals on request (`--sandbox workspace-write
--ask-for-approval on-request`, also what the `--full-auto` shorthand
meant). Two things about that setting:

- Inside the sandbox, commands run without asking. What protects live
  systems is that workspace-write is meant to block network access by
  default, so a Graph or Exchange call needs an escalation, and the
  escalation asks. Test that on your platform before you rely on it.
- The mode to avoid near production is the one that turns off both
  approvals and the sandbox (`--dangerously-bypass-approvals-and-sandbox`,
  or `--sandbox danger-full-access`). For sessions close to production,
  `--ask-for-approval untrusted` asks before anything outside a short list
  of safe read commands.

Flag names change between releases, so check `codex --help` on your
version. For Warp's agent, set command execution to ask every time.

## Differences I noticed

- **The one serious Codex failure was about verification.** A Codex session
  on ticket work claimed checks it had not run and closed a ticket in the
  same step as the change. That is why `CODEX.md` exists and restates the
  two rules with the reason attached. A rule with its reason gets followed
  more reliably than a bare rule.
- **Codex was useful for spreadsheet work.** It wrote a script to check a
  spreadsheet for a ticket in late August and a builder for a role-audit
  workbook in September, both for real ticket work.
- **Warp's agent does run things on its own.** In one terminal history I
  checked, Warp's agent had run 31 of 118 recorded commands, under the
  agent profile I used, which let it decide which commands needed my
  approval. All 31 were reads or local file housekeeping (AWS CLI
  listings, two mailbox folder statistics queries: sizes and item counts,
  no message content). Every Graph sign-in and every tenant change in that
  history was typed or pasted by me. Set it to ask from the start; the
  template's `WARP.md` says so.
- **Two models are a cheap second opinion.** On an early onboarding I
  checked Claude's answer against ChatGPT, and ChatGPT was the one that had
  it right. For anything touching identity or licensing, asking the other
  assistant the same question costs a minute.

## If you build your own

- Keep the contract product-neutral. Tool names appear only in the shim
  files and in the routing line.
- Put the "why" next to every hard rule. The incoming assistant has none of
  the history.
- Update `00_STATUS.md` at every gate, not at the end. The end is exactly
  when you run out of usage.
- Keep the shims short. Mine are under 30 lines each. Anything longer
  belongs in `AGENTS.md`, where every tool can see it.
