# Codex adapter (also for ChatGPT)

Read `AGENTS.md` first. It is the source of truth for this repository and
applies to you exactly as written. It is not Claude-specific.

Two rules there matter most for ticket work. A Codex session in the
workspace this template came from broke both: it claimed checks it had not
run, and it closed a ticket in the same step as the change.

- The words "verified", "confirmed", "shown", and "visible" need their
  evidence in the same turn: the literal command output, API response, or
  screenshot region that backs them. Saying what a check would show is not
  the same as running it.
- A change and its close are two separate steps. Make the change, read the
  changed record back, then close it as its own action with that read-back
  quoted in the close note. "Close it when done" means close it if the
  read-back succeeds, not if the change was attempted.

When a check fails, is blocked, or cannot be completed, report that plainly
instead of a success message.

Keep approvals on for any session that can reach a live system, and never
use the mode that turns off both approvals and the sandbox
(`--dangerously-bypass-approvals-and-sandbox` in the CLI versions I know).
The settings I use are in `docs/switching-assistants.md`.
