# How the contract evolved

The `AGENTS.md` in this repo did not start as a design. It is what was left
after several months of IT operations work with AI assistants in 2026, at
an employer with a hybrid Microsoft 365 tenant and about 1,100
Intune-managed endpoints. Each stage below exists because the one before
it broke in a specific way. Dates are local (Mountain) time and come from
file timestamps, archive notes, and dated workbench folders.

| Stage | When | Shape | What forced the next stage |
|---|---|---|---|
| 0 | June | claude.ai Project with numbered master docs | Copies went stale; the assistant could not see the system |
| 1 | July (13 KB by 07-31) | One large `CLAUDE.md` for Claude Code | Only one tool could read it; rules buried under status |
| 2 | 08-07 | Agent-neutral `AGENTS.md` plus thin shims; superseded files archived with reasons | Rules about verification were habits, not text |
| 3 | September | PASS/FAIL gates in scripts (09-02); read-back and close rules in the contract after a Codex incident | Every tool kept its own memory |
| 4 | October (10-03) | Shared notes folder read and written by more than one tool | (current) |

## Stage 0: a claude.ai Project (June)

Before Claude Code ran on my admin profile, most of my work was in
claude.ai chats. By June the first setup with any structure was in place:
a claude.ai Project. Its knowledge held a set of numbered master
documents, one per area of work. A short always-on
instruction block set the house rules: key facts first and detail after,
no em dashes in anything I would send, every PowerShell block states where
it runs (domain controller in Windows PowerShell 5.1, or my workstation in
PowerShell 7), and every ticket gets full work notes plus a separate
one-line resolution note.

Claude wrote the commands. I ran them in my own shell and pasted the output
back. On an early onboarding in June, I checked an answer against ChatGPT
and ChatGPT was the one that had it right. That habit of cross-checking
stuck.

What broke:

- The knowledge files were copies. Every new rule meant editing a file and
  uploading it again, and it was easy to forget.
- Long chats hit their limits mid-task. I wrote a handoff prompt (topic,
  decisions locked in, status, next steps, open questions) so a fresh chat
  could pick up the work. It is pattern 7 in
  [prompt-patterns.md](prompt-patterns.md).
- The assistant only knew what I pasted. Screenshots of request forms were
  slow, expensive, and easy to misread, which led to the intake workbook in
  [`examples/intake/`](../examples/intake/) (first version early July).

## Stage 1: Claude Code and a 13 KB CLAUDE.md (July)

Claude Code's first launch on my admin profile was 07-03. Now the
assistant could read files and run commands, asking first for anything
not on its allow list, so the instructions moved into a `CLAUDE.md` at the
root of a local workspace. At the end of July I exported the company
knowledge base and built it into a Markdown corpus the agent could search
(the companion repo
[kb-to-agent-corpus](https://github.com/gitColinX/kb-to-agent-corpus)
covers that).

By 07-31 `CLAUDE.md` was about 13 KB and 224 lines. It held a
search-the-knowledge-base-first rule, who and where, execution environment
labels, standing rules, an attribute usage table, an index of the knowledge
base, cleanup status, notes for resuming work, plans for the next session,
and AWS guidance with secret-handling rules.

What broke:

- Durable rules sat next to status lines that went stale within days.
- The rules that mattered most were buried in the middle.
- Only Claude Code read it.
- It contradicted the onboarding playbook on the account-naming
  convention, and that conflict was not settled until September (Stage 3).

## Stage 2: one contract, thin shims, archived history (August)

On 08-05 a minimal `AGENTS.md` appeared (about 680 bytes): search first,
prefer existing runbooks, and "if documentation conflicts, prefer the
newest version". On 08-07 I rewrote it as the full agent-neutral contract
and cut `CLAUDE.md` down to a 1.1 KB adapter that says "read AGENTS.md
first" and lists the canonical documents.

The rewrite changed three things that mattered:

1. **Newest-wins was wrong.** A newer draft, a ticket note, or a chat
   summary should not override a canonical runbook. Conflicts are now
   settled by authority, scope, status, and evidence, and high-impact
   conflicts stop the work.
2. **Imported content became untrusted data.** The knowledge base export,
   OCR text, attachments, and ticket text can contain instructions. None of
   them can steer the agent.
3. **Facts and policy got separate precedence lists.** Live read-only
   output is the best source for what exists. It is never a source for what
   should be done.

Superseded guidance moved into `_archive_superseded/<topic>/`, one folder
per topic, each with a short `_WHY_ARCHIVED.md`: the date, what replaced
it, and "do not treat as current". Five folders were archived that day: the
old Claude-only guidance, the older repository guidance, the offboarding
versions before v4, an application request catalog replaced by a service
registry, and some unrelated vendor documentation. The habit started on
07-19, when I reconciled duplicate playbook drafts (one was byte-identical
by SHA256) and moved them aside with a note instead of deleting them.

I used Codex from mid-August (the desktop app, for OCR) and the Codex CLI
from 2026-08-21. Codex at work was signed in to the company's ChatGPT
workspace. `WARP.md` followed on 08-21 as a one-line shim, the same
evening I set up the Codex CLI. From then on, when I ran out of Claude
usage in the middle of a task, I pointed Codex or the ChatGPT desktop app
at the same folder and the same Markdown files.
Because the contract was not written for one product, the switch did not
need a rewrite. Details are in
[switching-assistants.md](switching-assistants.md).

## Stage 3: verification becomes text and code (September)

Reading back after every write was already a habit. The offboarding
playbook recorded steps as "read-back verified in production" by 07-21.
September turned the habit into rules a tool could not skip.

**Gates in code (09-02).** Between late July and the end of August,
account-build blocks generated in chat drifted away from the onboarding
playbook. Address fields were dropped, the name attribute was set from the
wrong variable, the account name lost its casing convention, and a
start-date attribute lost its required prefix. Each block looked fine on
its own. Once the drift was spotted, I fixed 16 accounts on 09-02 and
added two mandatory PASS/FAIL gates to the playbook: one on the domain
controller that must be clean before the directory sync runs, and one in
the cloud stage that must be clean before any ticket note is written. A
monthly drift sweep checks for anything that slipped through. Later that
month the gate ran on real onboardings, and one run caught a FAIL row. The
pattern is in
[`examples/compliance-gate/`](../examples/compliance-gate/). The same day
the chat project's instructions went to v2: the account-naming conflict was
settled, a stale rule that no longer matched the environment was dropped,
and the gates became standing rules.

**Rules in the contract (mid to late September).** A Codex session on
ticket work claimed checks it had not run and closed a ticket in the same
step as the change. I wrote two rules into `AGENTS.md` as explicit bullets:
quote the literal read-back output before using the word "verified", and
never close a record in the same step as the change it documents. I also
added `CODEX.md`, a Codex-specific shim that restates both rules up front
and says why. Two smaller rules came with them: label evidence for what it
is (DOM text and raw JSON are not a screenshot), and treat a pre-approved
"close it when done" as conditional on the read-back.

The lesson I took from this: an assistant that writes "verified" is making
a claim. The read-back output is the evidence. The contract now requires
the evidence in the same message as the claim.

## Stage 4: shared notes across tools (October)

Each assistant keeps its own memory. Claude Code's auto-memory is not
visible to Claude chat, and neither is visible to Codex. The result was a
new session re-verifying facts that an earlier session, in another tool,
had already settled.

On 10-03 I set up a shared notes folder on my own machine:

- `INDEX.md`, kept under 40 lines: the rules for any AI reading the folder
  and a one-line list of topics.
- `topics/<job>.md`, one file per ongoing job, with Status, Facts, and
  Commands sections.
- `session-log.md`, newest entry at the top, one short entry per session
  that changed system state.

My global `CLAUDE.md` and the root `AGENTS.md` that Codex reads both tell
the assistant to read `INDEX.md` first and then only the matching topic
file, and to treat recorded facts as settled. Claude Code and Claude chat
have both written entries. A chat tool without file access gets
`INDEX.md` and the one topic file attached. A fictional copy of the layout
is in [`examples/shared-notes/`](../examples/shared-notes/).

## What carried through every stage

- **State lives in files, not in a chat.** That is what made switching
  tools and starting fresh sessions cheap.
- **Archive with a reason, do not delete.** Every superseded file says what
  replaced it.
- **The human signs in and approves production writes.** The agent never
  held a password, I approved production writes before they ran, and
  production changes had a readable dry run in front of them. When a
  queued step removed more access than intended, the read-back caught it
  and the access was restored within minutes.
- **Rules come from incidents.** Most of the contract traces back to a
  moment where the default would eventually have hurt someone.
