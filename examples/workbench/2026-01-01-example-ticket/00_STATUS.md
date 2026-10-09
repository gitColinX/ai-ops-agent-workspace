# TASK-0001: temporary calendar access for a covering assistant

> Fictional example. Every name, address, ticket number, and line of output
> in this folder is made up to show the format. Nothing here came from a
> real tenant.

| | |
|---|---|
| Ticket | TASK-0001 (fictional) |
| Mailbox | `exec.a@contoso.com` (Executive A) |
| Covering assistant | `ea.cover@contoso.com` (EA Cover) |
| Window | 2026-01-05 to 2026-01-16 |
| Approval | Executive A's chief of staff, in the ticket's approval record |
| Status | Applied and read back. Close pending as a separate step. Removal scheduled. |
| Last updated | 2026-01-02 14:10 MT |

## Gates

- [x] 1. Read-only recon: identities, mailbox type, calendar folder name, existing permissions
- [x] 2. Plan and dry run shown
- [x] 3. Approval in this session ("approved, apply")
- [x] 4. Apply
- [x] 5. Read-back quoted (FINDINGS.md, A3)
- [ ] 6. Close TASK-0001 as a separate step, read-back quoted in the close note
- [x] 7. Removal scheduled: future-dated task TASK-0002 for 2026-01-16 17:00 MT, plus a calendar reminder
- [ ] 8. On 2026-01-16: remove, read back, close TASK-0002

## Next gated step

Close TASK-0001 with the read-back from FINDINGS.md A3 in the close note.
Nothing else changes until 2026-01-16.

## Blocked

Nothing. One open question for the chief of staff is in FINDINGS.md D. It
does not block the close.

## Timeline (Mountain time; raw log timestamps are UTC)

| Time | Step | Evidence |
|---|---|---|
| 2026-01-02 13:20 | Device-code sign-in to Exchange Online, recon | FINDINGS.md A1, A2 |
| 13:41 | Dry run shown | `plan.txt` |
| 13:52 | Approval given in session | session transcript |
| 13:55 | Apply | FINDINGS.md A3 |
| 13:56 | Read-back | FINDINGS.md A3 |
