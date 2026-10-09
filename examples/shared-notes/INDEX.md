# Shared notes: read this first

> Fictional example of a notes folder written for any AI tool to read.
> Claude Code and Claude chat write to mine; Codex is pointed at it. The
> layout is real. The topics are adapted from my own machine, with the
> details changed.

This file is small on purpose. Only open a topic file if the current task
is about that topic.

## Layout

- `INDEX.md`: this file. Rules and the topic list. Keep it under 40 lines.
- `session-log.md`: dated log of work done, newest entry at the top. Read
  only the top 3 entries unless asked.
- `topics/*.md`: one file per ongoing job, with Status, Facts, and
  Commands. Read only the one that matches the task.

## Rules for any AI reading this folder

1. Start of session: read this file, then only the matching topic file.
2. Facts in a topic file are settled. Do not re-verify or re-ask unless the
   user says something changed.
3. End of session, if system state changed (software installed or removed,
   config changed, a problem fixed): add ONE entry to the top of
   `session-log.md` and update the Status line of the matching topic.
4. Keep entries short. Commands go in fenced code blocks. No narrative.
5. Never store secrets, license keys, passwords, tokens, or device codes.

## session-log.md entry format

```text
### YYYY-MM-DD | <tool used> | <one-line title>
- Did: ...
- Why: ...
- Outcome: ...
- Files/commands: ...
```

## Topics

- `topics/laptop-rebuild.md`: rebuild of the spare test laptop, driver and BIOS notes
- `topics/ai-cli-timeouts-on-vpn.md`: AI command-line tools time out on the VPN; cause and fix
