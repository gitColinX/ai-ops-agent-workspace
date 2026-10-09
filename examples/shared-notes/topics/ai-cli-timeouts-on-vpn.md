# AI command-line tools time out on the VPN

> Fictional example topic file, adapted from my own machine with the details changed.

**Status:** Resolved 2026-01-09. Custom DNS set, mesh feature off.

## Facts (settled, do not re-verify)

- Symptom: AI command-line tools fail in bursts with connection refused or
  timeout errors while the VPN is connected. Fine with the VPN off.
- Only name resolution through the VPN client's forced DNS path fails.
  Other sites keep working on the same tunnel because their records are
  cached longer.
- The AI service's API hostname has a short DNS time-to-live, so it is the
  first name to fail when the resolver path drops.
- Root cause is the resolver path, not the VPN's threat protection feature
  (that feature is off).

## Fix

- VPN client: Custom DNS set to the office resolvers.
- VPN client: mesh feature off (it re-negotiated every few minutes).

## Commands

```powershell
# Read-only probe: one lookup every 5 seconds, logged with UTC and local time
1..360 | ForEach-Object {
    $t = Get-Date
    $ok = [bool](Resolve-DnsName api.example.com -Type A -DnsOnly -ErrorAction SilentlyContinue)
    [pscustomobject]@{ Utc = $t.ToUniversalTime().ToString('o'); Local = $t.ToString('s'); Resolved = $ok }
    Start-Sleep -Seconds 5
} | Export-Csv C:\Temp\dns-probe.csv -NoTypeInformation
```

## Undo

- Set the VPN client's DNS back to automatic and turn the mesh feature on.
