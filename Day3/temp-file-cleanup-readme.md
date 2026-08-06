# Temp File Cleanup Script

This script is designed for DWP engineers to safely clean up temporary files on Windows endpoints.

## Script

`temp-file-cleanup.ps1`

## What it does

- Scans temp locations and targets files older than the configured age.
- Supports a dry run mode that prints the files that would be deleted.
- Moves deleted files into a quarantine area so they can be restored later.
- Logs every action to a timestamped log file.
- Skips locked or access-restricted files without stopping the run.
- Prints a summary at the end of each run.

## Parameters

### `-DaysOld`
Controls how old a file must be before it is eligible for cleanup.

- Default: `0`
- Example: `-DaysOld 7`

### `-Path`
One or more target paths to scan.

- Default values:
  - `%TEMP%`
  - `%WINDIR%\Temp`

### `-DryRun`
Lists the files that would be removed, but does not delete or quarantine anything.

Example:

```powershell
.\temp-file-cleanup.ps1 -DryRun
```

### `-Rollback`
Restores files from the latest rollback manifest created by a cleanup run.

Example:

```powershell
.\temp-file-cleanup.ps1 -Rollback
```

### `-RollbackPath`
Optional path to a specific rollback manifest file.

Use this if you want to restore from a specific cleanup run instead of the latest one.

### `-LogDirectory`
Optional folder for logs and rollback state.

If not specified, the script creates a `TempCleanupLogs` folder next to the script.

## Logging

Each run creates a timestamped log file such as:

```text
TempCleanup_20260805_153012123.log
```

The rollback manifest is stored in the same log state area under a timestamped `State` folder.

## Rollback behavior

Cleanup does not permanently remove files right away. It moves them into a quarantine folder first.
That makes rollback possible and keeps the script safer for endpoint use.

Rollback is idempotent:

- If a file was already restored, the script skips it.
- If the backup file is missing, the script logs the issue and continues.
- If the source file already exists, the script leaves it alone.

## Safety notes

- The default age cutoff is `0`, which means files older than the current time are eligible.
- Test with `-DryRun` first before running cleanup in production.
- Use a higher `-DaysOld` value if you want a narrower cleanup scope.
