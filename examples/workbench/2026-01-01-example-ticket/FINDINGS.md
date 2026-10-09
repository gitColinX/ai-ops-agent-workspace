# Findings: TASK-0001

> Fictional example. Names, addresses, article numbers, and output are made
> up to show the format.

Evidence labels used below:

- **[live read-back]** output captured in this task
- **[repo fact]** from a runbook or knowledge base article in this repository
- **[inference]** my reasoning, not proven
- **[not found]** searched for and absent

## Verdict

Executive A's calendar now grants EA Cover Editor rights with the delegate
flag, for a fixed window that ends 2026-01-16. The grant matches the plan
and the approval. Removal is scheduled as its own task.

## A. Verified facts

### A1. Identities and mailbox type [live read-back]

```powershell
# Local PowerShell 7. Read-only. Exchange Online, delegated device-code sign-in.
Connect-ExchangeOnline -Device
Get-EXOMailbox -Identity exec.a@contoso.com -Properties RecipientTypeDetails |
    Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails
Get-EXOMailbox -Identity ea.cover@contoso.com -Properties RecipientTypeDetails |
    Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails
```

```text
DisplayName  PrimarySmtpAddress     RecipientTypeDetails
-----------  ------------------     --------------------
Executive A  exec.a@contoso.com     UserMailbox
EA Cover     ea.cover@contoso.com   UserMailbox
```

### A2. Calendar folder and permissions before the change [live read-back]

The folder name is read, not assumed, because a mailbox set to another
language has a localized calendar name.

```powershell
Get-EXOMailboxFolderStatistics -Identity exec.a@contoso.com -FolderScope Calendar |
    Select-Object Name, FolderPath, FolderType
Get-EXOMailboxFolderPermission -Identity 'exec.a@contoso.com:\Calendar'
```

```text
Name      FolderPath  FolderType
----      ----------  ----------
Calendar  /Calendar   Calendar

FolderName User         AccessRights       SharingPermissionFlags
---------- ----         ------------       ----------------------
Calendar   Default      {AvailabilityOnly}
Calendar   Anonymous    {None}
Calendar   EA Primary   {Editor}           Delegate
```

### A3. After the change [live read-back]

Applied at 13:55 MT, after approval in the session:

```powershell
Add-MailboxFolderPermission -Identity 'exec.a@contoso.com:\Calendar' `
    -User ea.cover@contoso.com -AccessRights Editor -SharingPermissionFlags Delegate
```

Read back at 13:56 MT:

```powershell
Get-EXOMailboxFolderPermission -Identity 'exec.a@contoso.com:\Calendar' -User ea.cover@contoso.com
```

```text
FolderName User      AccessRights SharingPermissionFlags
---------- ----      ------------ ----------------------
Calendar   EA Cover  {Editor}     Delegate
```

## B. What the knowledge base says [repo fact]

KB-0123 (fictional), "Calendar delegation for executive assistants",
Published, last reviewed 2025-11-03: use Editor with the Delegate flag on
the Calendar folder for a covering assistant, never FullAccess on the whole
mailbox. Read the folder name first. Record an end date on the ticket.

## C. Inference

- With the Delegate flag, meeting requests go to both EA Primary and EA
  Cover during the window. [inference] Based on how delegate delivery
  works by default; not tested in this tenant.

## D. Open items (need a human)

- Should EA Primary keep receiving meeting requests while out? Asked the
  chief of staff in the ticket. Does not block the close.

## E. Not found

- [not found] No written maximum duration for temporary delegation.
  Searched the knowledge base and runbooks for "delegat", "temporary", and
  "calendar access". Suggest a standard: 30 days at most, always with a
  future-dated removal task.

## F. Draft close note (NOT posted)

```text
Granted EA Cover (ea.cover@contoso.com) Editor access with the delegate
flag on Executive A's calendar for 2026-01-05 to 2026-01-16, per the
approval on this ticket. Read-back at 13:56 MT shows: Calendar, EA Cover,
{Editor}, Delegate. Removal is scheduled as TASK-0002 for 2026-01-16.
```
