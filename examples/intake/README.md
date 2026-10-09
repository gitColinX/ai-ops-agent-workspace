# Intake workbook with a "Copy for agent" button

Pattern [built, ran on real tickets]. This generator and macro are a
generic rewrite [built, tested on synthetic data].

## Why

Requests arrived as web forms. Pasting screenshots of them into an AI
assistant was slow, cost a lot of context, put personal data into images
in a chat history, and still produced misread fields. So I built a
workbook: two entry tabs (new employee, and contractor or consultant), a
reference tab, shaded input cells with guidance on hover, drop-downs where
the form has fixed choices, and a button that copies a labeled text block
to the clipboard. The onboarding runbook took that block as its input, and
"no screenshots" became the rule.

The first version was scaffolded with openpyxl from a chat assistant in
early July and finished by hand in Excel within the week. The version here
is written from scratch with no company fields.

## What is here

| File | What it does |
|---|---|
| `build_intake_workbook.py` | Writes a blank `Intake_Template.xlsx`. Refuses to overwrite unless `--overwrite`. |
| `IntakeMacros.bas` | VBA module: `CopyIntakeForAgent`, `ClearIntakeForm`, `AddIntakeButtons` (run once). |
| `intake_paste_block.py` | Prints the same block from a filled workbook, for anyone who would rather not enable macros. |
| `tests/test_intake.py` | Builds, fills, and reads workbooks in a temp folder. Synthetic data only. |

## Setup

```powershell
# Local PowerShell 7 or any shell with Python 3.10+ and openpyxl
python -I build_intake_workbook.py --out Intake_Template.xlsx
```

Then in Excel:

1. Open `Intake_Template.xlsx`, press Alt+F11.
2. File > Import File..., choose `IntakeMacros.bas`. Read it first; it is
   short. It only reads the active tab, writes to the clipboard, and writes
   under PASTE OUTPUT when it cannot confirm the clipboard copy.
3. Save as `.xlsm` (Excel Macro-Enabled Workbook).
4. Alt+F8, run `AddIntakeButtons` once.

Without macros:

```powershell
python -I intake_paste_block.py Filled_Intake.xlsx --sheet "New Employee"
```

## How it works

Every entry tab uses the same three columns: label in A, value in B, and a
hidden marker in C (`section`, `field`, `required`, `local`, or `output`).
The macro and the Python reader both walk column C, so you can add, remove,
or reorder rows in Excel without touching code. Required fields that are
still blank are listed at the bottom of the block, which turns a silent
guess into a question from the assistant.

Rows marked `local` (personal email and mobile phone) are for the person
doing the build. They are cleared with the form but never copied into the
block. The block still carries the person's legal name, start date and
manager, so paste it only into the organization's managed AI tenant, not a
personal account.

The clipboard uses the MSForms DataObject through late binding. On some
Windows versions that object fails outright, and on others it reports
success but leaves `??` on the clipboard. So the macro reads the clipboard
back and compares it with the block. If the copy fails or does not match,
it writes the block under PASTE OUTPUT and copies it as a cell range
instead. Each line is written with a leading apostrophe so `=== INTAKE ...`
is stored as text, not parsed as a formula.

The macro has not been run as part of this repo's tests. Import it once and
click both buttons before you rely on it.

## Tests

```powershell
python -I examples/intake/tests/test_intake.py
```
