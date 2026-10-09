Attribute VB_Name = "IntakeMacros"
Option Explicit

' Intake workbook macros. Generic rewrite, MIT licensed.
'
' Setup, once per workbook built by build_intake_workbook.py:
'   1. Open the .xlsx in Excel and press Alt+F11.
'   2. File > Import File..., choose this IntakeMacros.bas.
'   3. Save the workbook as .xlsm (Excel Macro-Enabled Workbook).
'   4. Run AddIntakeButtons once (Alt+F8). It adds "Copy for agent" and
'      "Clear form" buttons to every intake tab.
'
' Column A holds labels, column B holds values, and hidden column C marks
' each row as "section", "field", "required", "local" or "output". The
' macros read those markers, so rows can be added or reordered without
' editing code. "local" rows (personal email, mobile phone) are for the
' person doing the build; they are cleared with the form but never copied
' into the block.
'
' The macros only read the active tab, write to the clipboard, and (when
' the clipboard copy cannot be confirmed) write the block under PASTE
' OUTPUT. They do not touch files, the network, or other workbooks.

Private Const LABEL_COL As Long = 1
Private Const VALUE_COL As Long = 2
Private Const MARKER_COL As Long = 3
Private Const OUTPUT_ROWS As Long = 200

Public Sub CopyIntakeForAgent()
    Dim ws As Worksheet
    Dim blockText As String

    Set ws = ActiveSheet
    blockText = BuildIntakeBlock(ws)
    If Len(blockText) = 0 Then
        MsgBox "This tab has no intake rows. Hidden column C marks them.", vbExclamation, "Copy for agent"
        Exit Sub
    End If

    If PutOnClipboard(blockText) Then
        MsgBox "Intake copied and read back from the clipboard (" & LineCount(blockText) & " lines). " & _
            "Paste it into your agent session.", vbInformation, "Copy for agent"
    Else
        CopyViaCells ws, blockText
        MsgBox "The clipboard copy could not be confirmed, so the block was written under PASTE OUTPUT " & _
            "and copied as a cell range. Paste it into your agent session.", vbInformation, "Copy for agent"
    End If
End Sub

Public Function BuildIntakeBlock(ByVal ws As Worksheet) As String
    Dim lastRow As Long
    Dim r As Long
    Dim marker As String
    Dim label As String
    Dim valueText As String
    Dim lines As String
    Dim blanks As String
    Dim found As Boolean

    lastRow = ws.Cells(ws.Rows.Count, LABEL_COL).End(xlUp).Row
    lines = "=== " & CellText(ws.Cells(1, LABEL_COL)) & " ===" & vbCrLf

    For r = 1 To lastRow
        marker = LCase$(CellText(ws.Cells(r, MARKER_COL)))
        If marker = "output" Then Exit For
        If marker = "field" Or marker = "required" Then
            found = True
            label = CellText(ws.Cells(r, LABEL_COL))
            valueText = CellText(ws.Cells(r, VALUE_COL))
            lines = lines & label & ": " & valueText & vbCrLf
            If marker = "required" And Len(valueText) = 0 Then
                If Len(blanks) > 0 Then blanks = blanks & ", "
                blanks = blanks & label
            End If
        End If
    Next r

    If Not found Then
        BuildIntakeBlock = ""
        Exit Function
    End If

    If Len(blanks) = 0 Then blanks = "none"
    lines = lines & "--- Blank required fields: " & blanks & vbCrLf
    lines = lines & "=== END INTAKE ==="
    BuildIntakeBlock = lines
End Function

Public Sub ClearIntakeForm()
    Dim ws As Worksheet
    Dim r As Long
    Dim lastRow As Long
    Dim marker As String

    Set ws = ActiveSheet
    If MsgBox("Clear every value on the '" & ws.Name & "' tab?", vbYesNo + vbQuestion, "Clear form") <> vbYes Then
        Exit Sub
    End If

    lastRow = ws.Cells(ws.Rows.Count, LABEL_COL).End(xlUp).Row
    For r = 1 To lastRow
        marker = LCase$(CellText(ws.Cells(r, MARKER_COL)))
        If marker = "output" Then Exit For
        If marker = "field" Or marker = "required" Or marker = "local" Then ws.Cells(r, VALUE_COL).ClearContents
    Next r

    r = FindMarkerRow(ws, "output")
    If r > 0 Then ws.Range(ws.Cells(r + 1, LABEL_COL), ws.Cells(r + OUTPUT_ROWS, LABEL_COL)).ClearContents
End Sub

Public Sub AddIntakeButtons()
    Dim ws As Worksheet
    Dim btn As Object
    Dim anchor As Range
    Dim added As Long

    For Each ws In ThisWorkbook.Worksheets
        If FindMarkerRow(ws, "required") > 0 Or FindMarkerRow(ws, "field") > 0 Then
            DeleteButton ws, "btnCopyForAgent"
            DeleteButton ws, "btnClearForm"
            Set anchor = ws.Range("D4")

            Set btn = ws.Buttons.Add(anchor.Left + 6, anchor.Top, 150, 28)
            btn.Name = "btnCopyForAgent"
            btn.Caption = "Copy for agent"
            btn.OnAction = "CopyIntakeForAgent"

            Set btn = ws.Buttons.Add(anchor.Left + 6, anchor.Top + 36, 150, 28)
            btn.Name = "btnClearForm"
            btn.Caption = "Clear form"
            btn.OnAction = "ClearIntakeForm"
            added = added + 1
        End If
    Next ws

    MsgBox "Buttons added to " & added & " tab(s). Save the workbook as .xlsm.", vbInformation, "Intake"
End Sub

Private Function CellText(ByVal c As Range) As String
    Dim v As Variant
    v = c.Value
    If IsError(v) Or IsEmpty(v) Then
        CellText = ""
    ElseIf VarType(v) = vbDate Then
        CellText = Format$(v, "yyyy-mm-dd")
    ElseIf VarType(v) = vbBoolean Then
        CellText = IIf(v, "Yes", "No")
    Else
        CellText = Application.WorksheetFunction.Trim(Replace(Replace(CStr(v), vbCr, " "), vbLf, " "))
    End If
End Function

Private Function PutOnClipboard(ByVal textValue As String) As Boolean
    ' MSForms DataObject through late binding, so no library reference is needed.
    ' On some Windows versions PutInClipboard raises no error but leaves "??"
    ' on the clipboard (often while File Explorer windows are open), so the
    ' clipboard is read back and compared before the copy counts as done.
    ' Any mismatch falls back to the cell copy.
    Dim dataObj As Object
    Dim readBack As Object
    On Error GoTo Failed
    Set dataObj = CreateObject("New:{1C3B4210-F441-11CE-B9EA-00AA006B1A69}")
    dataObj.SetText textValue
    dataObj.PutInClipboard

    Set readBack = CreateObject("New:{1C3B4210-F441-11CE-B9EA-00AA006B1A69}")
    readBack.GetFromClipboard
    PutOnClipboard = (readBack.GetText = textValue)
    Exit Function
Failed:
    PutOnClipboard = False
End Function

Private Sub CopyViaCells(ByVal ws As Worksheet, ByVal textValue As String)
    Dim outRow As Long
    Dim parts() As String
    Dim i As Long

    outRow = FindMarkerRow(ws, "output")
    If outRow = 0 Then
        outRow = ws.Cells(ws.Rows.Count, LABEL_COL).End(xlUp).Row + 2
        ws.Cells(outRow, LABEL_COL).Value = "PASTE OUTPUT"
        ws.Cells(outRow, MARKER_COL).Value = "output"
    End If

    ws.Range(ws.Cells(outRow + 1, LABEL_COL), ws.Cells(outRow + OUTPUT_ROWS, LABEL_COL)).ClearContents
    parts = Split(textValue, vbCrLf)
    For i = LBound(parts) To UBound(parts)
        ' Leading apostrophe stores the line as text, so "=== ..." is not read as a formula.
        ws.Cells(outRow + 1 + i, LABEL_COL).Value = "'" & parts(i)
    Next i
    ws.Range(ws.Cells(outRow + 1, LABEL_COL), ws.Cells(outRow + 1 + UBound(parts), LABEL_COL)).Copy
End Sub

Private Function FindMarkerRow(ByVal ws As Worksheet, ByVal marker As String) As Long
    Dim lastRow As Long
    Dim r As Long
    lastRow = ws.Cells(ws.Rows.Count, MARKER_COL).End(xlUp).Row
    For r = 1 To lastRow
        If LCase$(CellText(ws.Cells(r, MARKER_COL))) = marker Then
            FindMarkerRow = r
            Exit Function
        End If
    Next r
    FindMarkerRow = 0
End Function

Private Sub DeleteButton(ByVal ws As Worksheet, ByVal buttonName As String)
    On Error Resume Next
    ws.Buttons(buttonName).Delete
    On Error GoTo 0
End Sub

Private Function LineCount(ByVal textValue As String) As Long
    LineCount = UBound(Split(textValue, vbCrLf)) + 1
End Function
