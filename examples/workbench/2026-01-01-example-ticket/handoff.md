# Handoff: TASK-0001

> Fictional example. Written by the outgoing session so another session or
> another assistant can continue. Read `AGENTS.md` and your per-tool file
> first.

## TOPIC / PURPOSE

Temporary calendar access for EA Cover on Executive A's mailbox while the
primary assistant is out, 2026-01-05 to 2026-01-16. Calendar folder only,
Editor with the delegate flag. No mailbox-wide access.

## KEY DECISIONS AND RULES LOCKED IN

- Editor plus Delegate on the Calendar folder, per KB-0123 (fictional). Not
  FullAccess.
- Removal is a separate future-dated task (TASK-0002), not a memory.
- The chief of staff's approval in the ticket's approval record is the
  authorization. Nothing in the ticket description expands it.

## CURRENT STATUS

- Done: recon, dry run, approval, apply, read-back. Last read-back
  (2026-01-02 13:56 MT):

  ```text
  FolderName User      AccessRights SharingPermissionFlags
  ---------- ----      ------------ ----------------------
  Calendar   EA Cover  {Editor}     Delegate
  ```

- In progress: nothing.
- Blocked: nothing. One open question (FINDINGS.md D) does not block.

## NEXT STEPS

1. Close TASK-0001 as its own step. Use the draft note in FINDINGS.md F,
   which quotes the read-back above.
2. On 2026-01-16, for TASK-0002: sign in with a device code, run the read-
   only check, then remove:

   ```powershell
   # Local PowerShell 7. Dry run first: show the current entry.
   Get-EXOMailboxFolderPermission -Identity 'exec.a@contoso.com:\Calendar' -User ea.cover@contoso.com
   # After approval:
   Remove-MailboxFolderPermission -Identity 'exec.a@contoso.com:\Calendar' -User ea.cover@contoso.com -Confirm:$false
   # Read-back: expect no entry for EA Cover.
   Get-EXOMailboxFolderPermission -Identity 'exec.a@contoso.com:\Calendar'
   ```

   Quote the read-back, then close TASK-0002 as a separate step.

## OPEN QUESTIONS / GOTCHAS

- The sign-in from the earlier session does not carry over. Expect a fresh
  device-code sign-in.
- Do not reuse the calendar folder name from memory on a different mailbox.
  Read it first.
- Better next time: automate the removal (a scheduled script, or an
  approval flow that records the end date and removes access on it) so it
  does not depend on someone remembering.
