<#
.SYNOPSIS
    Pre-publish scan of a folder for secrets, identifiers, ticket numbers,
    real-looking addresses, typography, and your own deny-listed words. It
    never prints the matched text.

.DESCRIPTION
    Read-only. Walks the text files under -Path and reports every hit as
    file, line, detector, and a 12-character keyed hash of the matched text.
    The key is random for each run and is never printed, so the hash only
    tells you whether two hits in the same report are the same value. It
    cannot be reversed by guessing, even for short values such as a ticket
    number or a private IP address, and it changes on the next run.

    Detectors:
      dash          em dash or en dash (house style)
      guid          any GUID that is not on the allow list (tenant IDs,
                    object IDs, app IDs)
      email         an address outside the placeholder domains
      ipv4          an IPv4 address outside RFC 5737 documentation ranges
                    and loopback
      tenant        a Microsoft 365 tenant host name (the initial
                    onmicrosoft domain or a SharePoint Online host) that
                    is not a placeholder (contoso, fabrikam, example)
      hostname      an internal-looking host name ending in .local, .corp,
                    .lan or .internal (settings.local and CLAUDE.local are
                    allowed)
      phone         a North American phone number outside the fictional
                    555-01xx range
      awsacct       a 12-digit number on its own, the shape of an AWS
                    account ID (all zeros and the AWS documentation
                    example are allowed)
      secret        private keys, cloud access keys, JWTs, common token
                    prefixes, Entra client secrets, storage SAS signatures
                    and account keys, and password or secret assignments
      ticket        ServiceNow-style record numbers (INC, RITM, SCTASK, KB...)
      denylist      any term from -DenyListPath (company names, hostnames,
                    people). Keep that file OUTSIDE the repository.

    Binary files (images, PDFs, Office files) and files over 5 MB are not
    scanned. They are listed at the end so a person can check them.

    Exit code 0 when nothing is found, 1 when anything is found.

.PARAMETER Path
    Folder to scan. Defaults to the current directory.

.PARAMETER DenyListPath
    Optional text file, one term per line, matched case-insensitively.
    Lines starting with # are ignored.

.PARAMETER AllowGuid
    Extra GUIDs to allow (for example a public sample ID you reference on
    purpose).

.EXAMPLE
    pwsh -File tools/Test-PublishReady.ps1 -Path . -DenyListPath ~/private/denylist.txt
#>
[CmdletBinding()]
param(
    [string]$Path = '.',

    [string]$DenyListPath,

    [string[]]$AllowGuid = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Microsoft first-party public client IDs are public, not secrets.
$allowedGuids = @(
    '14d82eec-204b-4c2f-b7e8-296a70dab67e'  # Microsoft Graph PowerShell (public client)
    'fb78d390-0c51-40cd-8e17-fdbfab77341b'  # Exchange Online PowerShell (public client)
    '1c3b4210-f441-11ce-b9ea-00aa006b1a69'  # MSForms DataObject COM class ID (public, used by the intake macro)
    '00000000-0000-0000-0000-000000000000'
) + $AllowGuid | ForEach-Object { $_.ToLowerInvariant() }

$allowedEmailDomains = @(
    'contoso.com', 'fabrikam.com', 'example.com', 'example.org', 'example.net',
    'users.noreply.github.com', 'anthropic.com'
)
$allowedTenantPrefixes = @('contoso', 'fabrikam', 'example')
$allowedHostLabels = @('settings', 'claude')
$allowedAwsAccounts = @('000000000000', '123456789012')

$textExtensions = @(
    '.md', '.txt', '.ps1', '.psm1', '.psd1', '.py', '.js', '.mjs', '.cjs', '.ts',
    '.json', '.jsonc', '.toml', '.yml', '.yaml', '.ini', '.cfg', '.xml', '.html',
    '.css', '.csv', '.bas', '.cls', '.vbs', '.cmd', '.bat', '.sh', '.gitignore',
    '.gitattributes', '.warpindexingignore', ''
)

$skipDirs = @('.git', 'node_modules', '.venv', '__pycache__', '.pytest_cache')

$dashPattern = '[' + [char]0x2013 + [char]0x2014 + ']'
$guidPattern = '\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b'
$emailPattern = '\b[A-Za-z0-9._%+\-]+@([A-Za-z0-9\-]+\.)+[A-Za-z]{2,}\b'
$ipv4Pattern = '\b(?:25[0-5]|2[0-4]\d|1?\d?\d)(?:\.(?:25[0-5]|2[0-4]\d|1?\d?\d)){3}\b'
$tenantPattern = '(?i)\b([A-Za-z0-9-]+)\.(?:onmicrosoft|sharepoint)\.com\b'
$hostPattern = '(?i)\b([A-Za-z0-9-]+)\.(?:local|corp|lan|internal)\b(?![\w-])'
$phonePattern = '(?<![\w-])(?:\+1[ .-]?)?\(?([2-9]\d{2})\)?[ .-]([2-9]\d{2})[ .-](\d{4})(?![\w-])'
$awsPattern = '(?<![\w.-])\d{12}(?![\w.-])'
$ticketPattern = '\b(?:INC|RITM|REQ|SCTASK|CHG|PRB|KB)\d{7}\b'
$secretPatterns = @(
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    '\bAKIA[0-9A-Z]{16}\b'
    '\beyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{5,}'
    '\b(?:ghp|gho|ghs|github_pat)_[A-Za-z0-9_]{20,}'
    '\bxox[abprs]-[A-Za-z0-9\-]{10,}'
    '\bsk-[A-Za-z0-9_\-]{20,}'
    '[A-Za-z0-9_\-.~]{3}\dQ~[A-Za-z0-9_\-.~]{30,}'                  # Entra ID client secret value
    '(?i)[?&]sig=[A-Za-z0-9%+/=]{20,}'                               # storage SAS signature
    '(?i)\bAccountKey=[A-Za-z0-9+/=]{20,}'                           # storage connection string key
    '(?i)\b(?:password|passwd|pwd|client_secret|secret|api_key|apikey)\s*[:=]\s*["'']?(?!<)[^\s"''<>{}$]{6,}'
)

# A random key for this run only. It is never printed or saved, so a hash in
# the report cannot be matched against a list of guesses.
$hmacKey = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($hmacKey) } finally { $rng.Dispose() }

function Get-ShortHash {
    param([string]$Text)
    $hmac = [System.Security.Cryptography.HMACSHA256]::new($hmacKey)
    try { $hash = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text)) } finally { $hmac.Dispose() }
    return ([System.BitConverter]::ToString($hash) -replace '-', '').Substring(0, 12).ToLowerInvariant()
}

function Test-DocIPv4 {
    # True for addresses that are fine to publish: RFC 5737 documentation
    # ranges, loopback, and the unspecified address.
    param([string]$Ip)
    return ($Ip -like '192.0.2.*' -or $Ip -like '198.51.100.*' -or $Ip -like '203.0.113.*' -or
        $Ip -like '127.*' -or $Ip -eq '0.0.0.0')
}

$root = (Resolve-Path -LiteralPath $Path).Path
$denyTerms = @()
if ($DenyListPath) {
    $denyTerms = @(Get-Content -LiteralPath $DenyListPath |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and -not $_.StartsWith('#') })
}

$allFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File -Force | Where-Object {
        $rel = $_.FullName.Substring($root.Length).TrimStart('\', '/')
        $parts = $rel -split '[\\/]'
        -not ($parts | Where-Object { $skipDirs -contains $_ })
    })
$files = @($allFiles | Where-Object {
        ($textExtensions -contains $_.Extension.ToLowerInvariant() -or $_.Name -eq 'LICENSE') -and $_.Length -lt 5MB
    })
$scannedNames = @($files | ForEach-Object { $_.FullName })
$notScanned = @($allFiles | Where-Object { $scannedNames -notcontains $_.FullName })

$findings = [System.Collections.Generic.List[object]]::new()
function Add-Finding {
    param([string]$File, [int]$Line, [string]$Detector, [string]$Match)
    $findings.Add([pscustomobject]@{
            File     = $File
            Line     = $Line
            Detector = $Detector
            Hash     = Get-ShortHash $Match
        })
}

foreach ($file in $files) {
    $rel = $file.FullName.Substring($root.Length).TrimStart('\', '/')
    $lineNo = 0
    foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
        $lineNo++
        foreach ($m in [regex]::Matches($line, $dashPattern)) { Add-Finding $rel $lineNo 'dash' $m.Value }
        foreach ($m in [regex]::Matches($line, $guidPattern)) {
            if ($allowedGuids -notcontains $m.Value.ToLowerInvariant()) { Add-Finding $rel $lineNo 'guid' $m.Value }
        }
        foreach ($m in [regex]::Matches($line, $emailPattern)) {
            $domain = ($m.Value -split '@')[1].ToLowerInvariant()
            $ok = $false
            foreach ($d in $allowedEmailDomains) { if ($domain -eq $d -or $domain.EndsWith(".$d")) { $ok = $true } }
            if (-not $ok) { Add-Finding $rel $lineNo 'email' $m.Value }
        }
        foreach ($m in [regex]::Matches($line, $ipv4Pattern)) {
            if (-not (Test-DocIPv4 $m.Value)) { Add-Finding $rel $lineNo 'ipv4' $m.Value }
        }
        foreach ($m in [regex]::Matches($line, $tenantPattern)) {
            $label = $m.Groups[1].Value.ToLowerInvariant() -replace '-my$', ''
            if ($allowedTenantPrefixes -notcontains $label) { Add-Finding $rel $lineNo 'tenant' $m.Value }
        }
        foreach ($m in [regex]::Matches($line, $hostPattern)) {
            if ($allowedHostLabels -notcontains $m.Groups[1].Value.ToLowerInvariant()) { Add-Finding $rel $lineNo 'hostname' $m.Value }
        }
        foreach ($m in [regex]::Matches($line, $phonePattern)) {
            $fictional = ($m.Groups[2].Value -eq '555' -and $m.Groups[3].Value -like '01??')
            if (-not $fictional) { Add-Finding $rel $lineNo 'phone' $m.Value }
        }
        foreach ($m in [regex]::Matches($line, $awsPattern)) {
            if ($allowedAwsAccounts -notcontains $m.Value) { Add-Finding $rel $lineNo 'awsacct' $m.Value }
        }
        foreach ($p in $secretPatterns) {
            foreach ($m in [regex]::Matches($line, $p)) { Add-Finding $rel $lineNo 'secret' $m.Value }
        }
        foreach ($m in [regex]::Matches($line, $ticketPattern)) { Add-Finding $rel $lineNo 'ticket' $m.Value }
        foreach ($term in $denyTerms) {
            $idx = $line.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase)
            if ($idx -ge 0) { Add-Finding $rel $lineNo 'denylist' $line.Substring($idx, $term.Length) }
        }
    }
}

Write-Output "Scanned $($files.Count) text files under $root"
if ($findings.Count -eq 0) {
    Write-Output 'No findings in the text files.'
}
else {
    $findings | Sort-Object File, Line | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
    $findings | Group-Object Detector | Sort-Object Name |
        ForEach-Object { "{0,-9} {1}" -f $_.Name, $_.Count } | Write-Output
    Write-Output "$($findings.Count) finding(s). Matched text is never printed. Hashes are keyed for this run only; use them to group repeats."
}

if ($notScanned.Count -gt 0) {
    Write-Output "$($notScanned.Count) file(s) not scanned (binary or over 5 MB). Check them by hand before publishing:"
    $notScanned | ForEach-Object { '  ' + $_.FullName.Substring($root.Length).TrimStart('\', '/') } | Write-Output
}

if ($findings.Count -eq 0) { exit 0 } else { exit 1 }
