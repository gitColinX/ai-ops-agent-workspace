<#
.SYNOPSIS
    PASS/FAIL compliance gate for a newly built account, evaluated against a
    JSON snapshot of the account and the expected values from the intake.

.DESCRIPTION
    Read-only. This script never connects to a directory. You collect the
    snapshot with your own read-only command after the build's read-back.
    For an on-premises account, in Windows PowerShell 5.1 on a domain
    controller or an RSAT host:

        Get-ADUser -Identity <sam> -Properties * |
            Select-Object Name, SamAccountName, UserPrincipalName, DisplayName,
                GivenName, Surname, StreetAddress, City, State, PostalCode,
                Country, Department, Title, Manager, extensionAttribute10,
                Enabled, DistinguishedName,
                @{ n = 'MemberOf'; e = { $_.MemberOf | ForEach-Object { ($_ -split ',')[0] -replace '^CN=' } } } |
            ConvertTo-Json | Set-Content snapshot.json -Encoding utf8

    Use the attribute your runbook keeps the start date in, and name it in
    expected.json (StartDateAttribute). Always write the snapshot as UTF-8:
    Windows PowerShell 5.1 writes ANSI by default, which breaks accented
    names. This script reads both files as UTF-8, with or without a BOM.

    Every runbook rule becomes one PASS or FAIL row. The point is that the
    same rules are checked the same way every time, no matter which
    assistant generated the build.

    Exit codes: 0 when every row passes, 1 when any row fails, 2 when the
    input cannot be read.

.PARAMETER SnapshotPath
    JSON file with the account as built.

.PARAMETER ExpectedPath
    JSON file with the expected values (see fixtures/expected.json).

.PARAMETER OutFile
    Optional path for a plain-text copy of the report.

.PARAMETER PassThru
    Also return the result rows as objects (useful in tests).

.EXAMPLE
    pwsh -File ./Test-AccountGate.ps1 -SnapshotPath fixtures/snapshot-pass.json -ExpectedPath fixtures/expected.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SnapshotPath,

    [Parameter(Mandatory)]
    [string]$ExpectedPath,

    [string]$OutFile,

    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-JsonFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File not found: $Path"
    }
    # Explicit UTF-8, so Windows PowerShell 5.1 and PowerShell 7 read the
    # same characters. A BOM, if present, is handled either way.
    Get-Content -LiteralPath $Path -Raw -Encoding utf8 | ConvertFrom-Json
}

function Get-Prop {
    # Returns the property value, or $null when the property does not exist.
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -eq $p) { return $null }
    return $p.Value
}

function Test-Equal {
    # Ordinal, case-sensitive comparison. Casing drift is one of the things
    # this gate exists to catch.
    param($Actual, $Expected)
    return [string]::Equals([string]$Actual, [string]$Expected, [System.StringComparison]::Ordinal)
}

function Test-EqualIgnoreCase {
    # For distinguished names, which the directory compares without case.
    param($Actual, $Expected)
    return [string]::Equals([string]$Actual, [string]$Expected, [System.StringComparison]::OrdinalIgnoreCase)
}

function ConvertTo-AsciiName {
    # Reduces accented letters to their base letter (an e with an acute
    # accent becomes e), then drops anything that is not a letter or digit.
    # Without this step an accented first name loses the letter entirely.
    # Letters with no ASCII base are dropped; handle those in your
    # runbook's naming rule.
    param([string]$Text)
    $decomposed = $Text.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = [System.Text.StringBuilder]::new()
    foreach ($ch in $decomposed.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($ch)
        }
    }
    return ($sb.ToString() -replace '[^A-Za-z0-9]', '')
}

try {
    $snap = Read-JsonFile -Path $SnapshotPath
    $exp = Read-JsonFile -Path $ExpectedPath
}
catch {
    Write-Error "Gate input error: $($_.Exception.Message)" -ErrorAction Continue
    exit 2
}

$given = Get-Prop $exp 'GivenName'
$surname = Get-Prop $exp 'Surname'
$suffix = [string](Get-Prop $exp 'DisplayNameSuffix')
$expectedDisplay = "$given $surname$suffix"
$expectedLocal = ConvertTo-AsciiName "$given$surname"
$expectedUpn = "$expectedLocal@$(Get-Prop $exp 'UpnDomain')"

$stampAttribute = [string](Get-Prop $exp 'StartDateAttribute')
if (-not $stampAttribute) { $stampAttribute = 'extensionAttribute10' }
$stampPrefix = [string](Get-Prop $exp 'StartDatePrefix')
$expectedStamp = $stampPrefix + (Get-Prop $exp 'StartDate')

$upn = [string](Get-Prop $snap 'UserPrincipalName')
$upnLocal = ($upn -split '@')[0]

# Each entry: check name, expected value, actual value, pass/fail.
$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row {
    param([string]$Check, $Expected, $Actual, [bool]$Pass)
    $rows.Add([pscustomobject]@{
            Result   = $(if ($Pass) { 'PASS' } else { 'FAIL' })
            Check    = $Check
            Expected = [string]$Expected
            Actual   = $(if ($null -eq $Actual -or [string]$Actual -eq '') { '<empty>' } else { [string]$Actual })
        })
}

Add-Row 'UPN follows FirstLast@domain' $expectedUpn $upn (Test-Equal $upn $expectedUpn)
Add-Row 'SamAccountName equals UPN local part (case-sensitive)' $upnLocal (Get-Prop $snap 'SamAccountName') (Test-Equal (Get-Prop $snap 'SamAccountName') $upnLocal)
Add-Row 'DisplayName matches intake (suffix included)' $expectedDisplay (Get-Prop $snap 'DisplayName') (Test-Equal (Get-Prop $snap 'DisplayName') $expectedDisplay)
Add-Row 'Name (CN) equals DisplayName' $expectedDisplay (Get-Prop $snap 'Name') (Test-Equal (Get-Prop $snap 'Name') $expectedDisplay)
Add-Row 'GivenName' $given (Get-Prop $snap 'GivenName') (Test-Equal (Get-Prop $snap 'GivenName') $given)
Add-Row 'Surname' $surname (Get-Prop $snap 'Surname') (Test-Equal (Get-Prop $snap 'Surname') $surname)

$office = Get-Prop $exp 'Office'
foreach ($field in 'StreetAddress', 'City', 'State', 'PostalCode', 'Country') {
    $want = Get-Prop $office $field
    $have = Get-Prop $snap $field
    Add-Row "Office address: $field" $want $have (Test-Equal $have $want)
}

$stamp = Get-Prop $snap $stampAttribute
$stampShape = '^' + [regex]::Escape($stampPrefix) + '\d{4}-\d{2}-\d{2}$'
Add-Row "Start-date stamp has prefix and matches intake ($stampAttribute)" $expectedStamp $stamp (([string]$stamp -match $stampShape) -and (Test-Equal $stamp $expectedStamp))

foreach ($field in 'Department', 'Title') {
    $want = Get-Prop $exp $field
    $have = Get-Prop $snap $field
    Add-Row $field $want $have (Test-Equal $have $want)
}
$wantManager = Get-Prop $exp 'Manager'
$haveManager = Get-Prop $snap 'Manager'
Add-Row 'Manager (DN, any case)' $wantManager $haveManager (Test-EqualIgnoreCase $haveManager $wantManager)

$wantEnabled = [bool](Get-Prop $exp 'Enabled')
$haveEnabled = Get-Prop $snap 'Enabled'
Add-Row 'Enabled state' $wantEnabled $haveEnabled (($null -ne $haveEnabled) -and ([bool]$haveEnabled -eq $wantEnabled))

$ou = [string](Get-Prop $exp 'OrganizationalUnit')
$dn = [string](Get-Prop $snap 'DistinguishedName')
Add-Row 'Created in the right OU' $ou $dn ($ou -ne '' -and $dn.EndsWith(",$ou", [System.StringComparison]::OrdinalIgnoreCase))

$memberOf = @(Get-Prop $snap 'MemberOf')
foreach ($group in @(Get-Prop $exp 'RequiredGroups')) {
    if ($null -eq $group) { continue }
    $isMember = @($memberOf | Where-Object { Test-EqualIgnoreCase $_ $group }).Count -gt 0
    Add-Row "Member of $group" 'member' $(if ($isMember) { 'member' } else { 'not a member' }) $isMember
}

$fails = @($rows | Where-Object Result -EQ 'FAIL')
$summary = "GATE for ${upn}: $($rows.Count - $fails.Count) PASS / $($fails.Count) FAIL"
$table = $rows | Format-Table -AutoSize -Wrap | Out-String -Width 200

Write-Output $summary
Write-Output $table

if ($OutFile) {
    $report = @($summary, $table) -join [Environment]::NewLine
    Set-Content -LiteralPath $OutFile -Value $report -Encoding utf8
    Write-Output "Report written to $OutFile"
}

if ($fails.Count -eq 0) {
    Write-Output 'GATE CLEAN. The next stage may run.'
}
else {
    Write-Output 'GATE FAILED. Do not run the next stage. Fix the FAIL rows and rerun the gate.'
}

if ($PassThru) { $rows }

if ($fails.Count -eq 0) { exit 0 } else { exit 1 }
