<#
.SYNOPSIS
    Runs every check in this repository against synthetic data.

.DESCRIPTION
    Read-only apart from temporary folders that it creates and removes.
    Contacts no tenant or service.

      1. Every .ps1 file parses with the PowerShell language parser.
      2. Every .json file is valid JSON.
      3. The compliance gate returns 0, 1 and 2 on the pass, drift and
         missing fixtures, with the expected FAIL rows, and passes an
         accented-name fixture read as UTF-8 (with and without a BOM, and
         under Windows PowerShell 5.1 when it is installed).
      4. The publish-readiness scanner finds each planted synthetic issue,
         never prints the planted text, uses a hash that changes on every
         run, lists files it could not scan, and passes a clean folder.
      5. The intake workbook tests (Python), when Python and openpyxl are
         installed. Otherwise they are reported as SKIP.

    Exit code 0 when nothing fails, 1 otherwise. SKIP does not fail the run.

.EXAMPLE
    pwsh -File tests/Invoke-Tests.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param([string]$Name, [bool]$Pass, [string]$Detail = '')
    $results.Add([pscustomobject]@{ Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Test = $Name; Detail = $Detail })
}

function Add-Skip {
    param([string]$Name, [string]$Reason)
    $results.Add([pscustomobject]@{ Result = 'SKIP'; Test = $Name; Detail = $Reason })
}

function New-TempFolder {
    param([string]$Prefix)
    $p = Join-Path ([System.IO.Path]::GetTempPath()) ($Prefix + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $p | Out-Null
    return $p
}

# 1. Parse every PowerShell file.
foreach ($file in Get-ChildItem -LiteralPath $repo -Recurse -File -Filter *.ps1) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    $rel = $file.FullName.Substring($repo.Length + 1)
    Add-Result "parse $rel" ($errors.Count -eq 0) ($errors | ForEach-Object { "line $($_.Extent.StartLineNumber): $($_.Message)" } | Out-String).Trim()
}

# 2. Valid JSON.
foreach ($file in Get-ChildItem -LiteralPath $repo -Recurse -File -Filter *.json) {
    $rel = $file.FullName.Substring($repo.Length + 1)
    try {
        $null = Get-Content -LiteralPath $file.FullName -Raw -Encoding utf8 | ConvertFrom-Json
        Add-Result "json $rel" $true
    }
    catch {
        Add-Result "json $rel" $false $_.Exception.Message
    }
}

# 3. Compliance gate.
$gateDir = Join-Path $repo 'examples/compliance-gate'
$gate = Join-Path $gateDir 'Test-AccountGate.ps1'
$expected = Join-Path $gateDir 'fixtures/expected.json'
$expectedAccented = Join-Path $gateDir 'fixtures/expected-accented.json'
$snapshotAccented = Join-Path $gateDir 'fixtures/snapshot-accented.json'

$out = & pwsh -NoProfile -File $gate -SnapshotPath (Join-Path $gateDir 'fixtures/snapshot-pass.json') -ExpectedPath $expected 2>&1 | Out-String
$code = $LASTEXITCODE
Add-Result 'gate: clean snapshot exits 0' ($code -eq 0) "exit $code"
Add-Result 'gate: clean snapshot reports 20 PASS / 0 FAIL' ($out -match '20 PASS / 0 FAIL')

$out = & pwsh -NoProfile -File $gate -SnapshotPath (Join-Path $gateDir 'fixtures/snapshot-drift.json') -ExpectedPath $expected 2>&1 | Out-String
$code = $LASTEXITCODE
Add-Result 'gate: drift snapshot exits 1' ($code -eq 1) "exit $code"
Add-Result 'gate: drift snapshot reports 13 PASS / 7 FAIL' ($out -match '13 PASS / 7 FAIL')
foreach ($check in 'SamAccountName equals UPN local part', 'Name \(CN\) equals DisplayName', 'Office address: StreetAddress',
    'Office address: State', 'Office address: PostalCode', 'Start-date stamp has prefix', 'Member of VPN Users') {
    Add-Result "gate: drift flags '$($check -replace '\\', '')'" ($out -match "FAIL\s+$check")
}

$null = & pwsh -NoProfile -File $gate -SnapshotPath (Join-Path $gateDir 'fixtures/does-not-exist.json') -ExpectedPath $expected 2>&1
$code = $LASTEXITCODE
Add-Result 'gate: missing input exits 2' ($code -eq 2) "exit $code"

$out = & pwsh -NoProfile -File $gate -SnapshotPath $snapshotAccented -ExpectedPath $expectedAccented 2>&1 | Out-String
$code = $LASTEXITCODE
Add-Result 'gate: accented name, UTF-8 without BOM, exits 0' ($code -eq 0) "exit $code"
Add-Result 'gate: accented name maps to an ASCII UPN' ($out -match 'ReneNunez@contoso\.com: 20 PASS / 0 FAIL')

$bomDir = New-TempFolder 'gate-bom-'
try {
    # The same snapshot as Windows PowerShell 5.1 writes it with -Encoding utf8: UTF-8 with a BOM.
    $bomSnapshot = Join-Path $bomDir 'snapshot.json'
    $text = [System.IO.File]::ReadAllText($snapshotAccented, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText($bomSnapshot, $text, [System.Text.UTF8Encoding]::new($true))
    $null = & pwsh -NoProfile -File $gate -SnapshotPath $bomSnapshot -ExpectedPath $expectedAccented 2>&1
    $code = $LASTEXITCODE
    Add-Result 'gate: accented name, UTF-8 with BOM, exits 0' ($code -eq 0) "exit $code"
}
finally {
    Remove-Item -LiteralPath $bomDir -Recurse -Force -ErrorAction SilentlyContinue
}

$ps51 = Get-Command powershell.exe -ErrorAction SilentlyContinue
if ($ps51) {
    $out = & $ps51.Source -NoProfile -File $gate -SnapshotPath $snapshotAccented -ExpectedPath $expectedAccented 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($out -match 'running scripts is disabled|cannot be loaded because') {
        Add-Skip 'gate (Windows PowerShell 5.1): accented name exits 0' 'execution policy blocks scripts in Windows PowerShell 5.1'
    }
    else {
        Add-Result 'gate (Windows PowerShell 5.1): accented name exits 0' ($code -eq 0) "exit $code"
    }
}
else {
    Add-Skip 'gate (Windows PowerShell 5.1): accented name exits 0' 'powershell.exe not found'
}

# 4. Publish-readiness scanner on planted synthetic issues. The planted
#    values are assembled at run time so this file stays clean itself.
$scanner = Join-Path $repo 'tools/Test-PublishReady.ps1'
$tmp = New-TempFolder 'publishready-test-'
$deny = Join-Path ([System.IO.Path]::GetTempPath()) ("denylist-" + [guid]::NewGuid().ToString('N') + '.txt')
try {
    $planted = [ordered]@{
        dash     = 'a' + [char]0x2014 + 'b'
        guid     = [guid]::NewGuid().ToString()
        email    = 'someone' + '@' + 'acme-corp.test'
        ipv4     = '10.' + '20.30.40'
        tenant   = 'acmecorp' + '.onmicrosoft' + '.com'
        hostname = 'srv01' + '.corp'
        phone    = '303-' + '444-' + '1234'
        awsacct  = '4821' + '93756104'
        secret   = 'pass' + 'word = ' + 'Plant3dValue!'
        ticket   = 'INC' + '0012345'
        denylist = 'Planted' + 'Corp'
    }
    $lines = @($planted.Values | ForEach-Object { "value: $_" })
    $lines += "again: $($planted.ticket)"   # a repeat, to check that repeats share a hash within one run
    Set-Content -LiteralPath (Join-Path $tmp 'notes.md') -Value $lines -Encoding utf8

    $moreSecrets = @(
        ('abc' + '8Q~' + ('x' * 34))              # Entra client secret shape
        ('sig=' + ('A' * 30))                     # storage SAS signature
        ('Account' + 'Key=' + ('B' * 40) + '==')  # storage account key
    )
    $moreLines = @(
        "entra: $($moreSecrets[0])"
        "sas: https://store.example.com/c?sv=1&$($moreSecrets[1])"
        "conn: $($moreSecrets[2])"
    )
    Set-Content -LiteralPath (Join-Path $tmp 'more.md') -Value $moreLines -Encoding utf8
    [System.IO.File]::WriteAllBytes((Join-Path $tmp 'photo.png'), [byte[]](0x89, 0x50, 0x4E, 0x47))
    Set-Content -LiteralPath $deny -Value @('# test deny list', $planted.denylist) -Encoding utf8

    $out = & pwsh -NoProfile -File $scanner -Path $tmp -DenyListPath $deny 2>&1 | Out-String
    $code = $LASTEXITCODE
    Add-Result 'scanner: planted issues exit 1' ($code -eq 1) "exit $code"
    foreach ($detector in $planted.Keys) {
        Add-Result "scanner: detects $detector" ($out -match "notes\.md\s+\d+\s+$detector\b")
    }
    $secretHits = [regex]::Matches($out, 'more\.md\s+\d+\s+secret\b').Count
    Add-Result 'scanner: detects Entra secret, SAS signature and account key' ($secretHits -eq 3) "$secretHits of 3"
    $allPlanted = @($planted.Values) + $moreSecrets
    $leaked = @($allPlanted | Where-Object { $out.Contains($_) })
    Add-Result 'scanner: never prints matched text' ($leaked.Count -eq 0) "$($leaked.Count) value(s) leaked"
    Add-Result 'scanner: lists files it could not scan' (($out -match 'not scanned') -and ($out -match 'photo\.png'))

    $hashesRun1 = @([regex]::Matches($out, 'notes\.md\s+\d+\s+ticket\s+([0-9a-f]{12})') | ForEach-Object { $_.Groups[1].Value })
    Add-Result 'scanner: a repeated value shares one hash within a run' (($hashesRun1.Count -eq 2) -and ($hashesRun1[0] -eq $hashesRun1[1])) "$($hashesRun1.Count) ticket hit(s)"
    $out2 = & pwsh -NoProfile -File $scanner -Path $tmp -DenyListPath $deny 2>&1 | Out-String
    $hashesRun2 = @([regex]::Matches($out2, 'notes\.md\s+\d+\s+ticket\s+([0-9a-f]{12})') | ForEach-Object { $_.Groups[1].Value })
    Add-Result 'scanner: the same value hashes differently on the next run' (($hashesRun1.Count -gt 0) -and ($hashesRun2.Count -gt 0) -and ($hashesRun1[0] -ne $hashesRun2[0]))

    Remove-Item -LiteralPath (Join-Path $tmp 'more.md'), (Join-Path $tmp 'photo.png') -Force
    $clean = 'Plain text with user@contoso.com, 192.0.2.10, contoso.onmicrosoft' + '.com, contoso-my.sharepoint' + '.com, ' +
        '.claude/settings.local.json, CLAUDE.local.md, (555) 555-0123 and account 123456789012.'
    Set-Content -LiteralPath (Join-Path $tmp 'notes.md') -Value @($clean) -Encoding utf8
    $out = & pwsh -NoProfile -File $scanner -Path $tmp 2>&1 | Out-String
    $code = $LASTEXITCODE
    Add-Result 'scanner: clean folder with placeholder values exits 0' ($code -eq 0) "exit $code"
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $deny -Force -ErrorAction SilentlyContinue
}

# 5. Intake workbook tests (Python).
$python = Get-Command python -ErrorAction SilentlyContinue
$skipReason = $null
if (-not $python) {
    $skipReason = 'python not found'
}
else {
    $null = & $python.Source -I -c 'import openpyxl' 2>&1
    if ($LASTEXITCODE -eq 9009) { $skipReason = 'python is the Windows app alias, not an installed Python' }
    elseif ($LASTEXITCODE -ne 0) { $skipReason = 'openpyxl is not installed (pip install openpyxl)' }
}
if ($skipReason) {
    Add-Skip 'intake: python tests' $skipReason
}
else {
    $intakeTests = Join-Path $repo 'examples/intake/tests/test_intake.py'
    $out = & $python.Source -I $intakeTests 2>&1 | Out-String
    $code = $LASTEXITCODE
    Add-Result 'intake: python tests' ($code -eq 0) (($out -split "`n" | Where-Object { $_ -cmatch '^(Ran|OK|FAILED)' }) -join ' ')
}

$results | Format-Table -AutoSize -Wrap | Out-String -Width 200 | Write-Output
$failed = @($results | Where-Object Result -EQ 'FAIL')
$skipped = @($results | Where-Object Result -EQ 'SKIP')
$passed = $results.Count - $failed.Count - $skipped.Count
Write-Output "$passed passed, $($failed.Count) failed, $($skipped.Count) skipped."
if ($failed.Count -gt 0) { exit 1 } else { exit 0 }
