# Spare test laptop rebuild

> Fictional example topic file, adapted from my own machine with the details changed.

**Status:** Done 2026-01-06. Enrolled in Intune as a test device, compliant.

## Facts (settled, do not re-verify)

- Model: a 14-inch business laptop from 2023, 16 GB RAM, 512 GB SSD.
- BIOS updated to the vendor's latest release before the wipe. The older
  release could not boot the USB installer with Secure Boot on.
- Graphics: integrated only. No discrete GPU driver needed.
- Enrollment: Windows Autopilot hash already uploaded. Assigned to the
  test deployment profile, not the production one.
- Local admin: none. Admin tasks go through the device management tool.

## Commands

```powershell
# Confirm the BIOS version after the update (read-only)
Get-CimInstance Win32_BIOS | Select-Object SMBIOSBIOSVersion, ReleaseDate
```

## Do not

- Do not enroll it with a personal account.
- Do not assign it to a production deployment profile.
