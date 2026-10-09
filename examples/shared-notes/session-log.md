# Session log (newest at top). Read only the top 3 entries unless asked.

> Fictional example entries, adapted from my own machine with the details changed.

### 2026-01-09 | Claude Code | VPN DNS fix applied and verified
- Did: set the VPN client's custom DNS to the office resolvers, turned off the mesh feature, reran the resolver probe for 30 minutes
- Why: topics/ai-cli-timeouts-on-vpn.md, fix was recorded but not yet applied
- Outcome: 0 failed lookups in 360 probes (was 41 in the previous run). Topic Status set to Resolved
- Files/commands: probe output in `C:\Temp\dns-probe-2026-01-09.csv`
```powershell
Resolve-DnsName api.example.com -Type A -DnsOnly
```

### 2026-01-08 | Claude Code | Root cause: AI CLI timeouts on VPN
- Did: ran a 5-minute DNS probe per resolver and a TCP probe in parallel while reproducing the timeout
- Why: AI command-line tools failing in bursts on the VPN, fine off it
- Outcome: only name resolution through the VPN's forced DNS path fails; TCP to the resolved address never starts. Fix recorded in the topic, not applied yet
- Files/commands: topics/ai-cli-timeouts-on-vpn.md

### 2026-01-06 | Claude chat | Spare laptop rebuilt
- Did: updated BIOS, wiped, installed Windows 11 from USB, enrolled in Intune as a test device
- Why: topics/laptop-rebuild.md
- Outcome: enrolled, compliant, apps installed. Topic Status set to Done
- Files/commands: none
