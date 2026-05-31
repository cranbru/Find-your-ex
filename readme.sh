# find-your-ex

A command-line tool that recursively scans a directory for `.exe` files, displays them in a colourful, well-formatted table, and lets you delete them — all at once or selectively.

Two versions are included:

| File | Platform | Requirements |
|------|----------|--------------|
| `ex-finder.ps1` | Windows | PowerShell 5.1+ (built into Windows 10/11) |
| `find_exe.sh` | Linux / macOS / WSL | Bash 4+ |

---

## Features

- Recursive scan of any directory you choose
- Colour-coded file sizes (green → yellow → orange → red by size tier)
- Alternating row shading for easy reading
- Optional last-modified date column
- Optional sort by size, largest first
- Summary footer: total file count, combined size, skipped directories
- Interactive delete menu — delete all, pick specific files by number, or exit safely
- Double-confirmation (`DELETE`) required before any file is removed
- Graceful handling of permission errors, empty results, and invalid input

---

## Quick Start (Windows)

1. Download `ex-finder.ps1`
2. Open **PowerShell** or **Windows Terminal**
3. Navigate to the folder where you saved the script:
   ```powershell
   cd C:\Users\YourName\Desktop
   ```
4. Run it:
   ```powershell
   .\ex-finder.ps1 -Path C:\Users\YourName
   ```

> **Note:** If you see a permissions warning when running for the first time, run this once in PowerShell:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
> ```
> If your policy is already set to `Bypass`, you can skip this — the script will run fine.

---

## Quick Start (Linux / macOS / WSL)

1. Download `find_exe.sh`
2. Make it executable:
   ```bash
   chmod +x find_exe.sh
   ```
3. Run it:
   ```bash
   ./find_exe.sh /home/yourname
   ```

---

## Usage

### PowerShell (Windows)

```
.\ex-finder.ps1 [-Path <directory>] [-ShowDate] [-SortSize] [-Help]
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-Path` | Directory to scan | Current directory (`.`) |
| `-ShowDate` | Add a last-modified date column | Off |
| `-SortSize` | Sort results by file size, largest first | Off (sorted by path) |
| `-Help` | Show usage information and exit | — |

**Examples:**
```powershell
# Scan your user folder
.\ex-finder.ps1 -Path C:\Users\YourName

# Scan the full C: drive, sorted by size
.\ex-finder.ps1 -Path C:\ -SortSize

# Scan with dates and size sort
.\ex-finder.ps1 -Path C:\Games -ShowDate -SortSize

# Show help
.\ex-finder.ps1 -Help
```

---

### Bash (Linux / macOS / WSL)

```
./find_exe.sh [-d] [-s] [-h] [directory]
```

| Flag | Description | Default |
|------|-------------|---------|
| `-d` | Show last-modified date column | Off |
| `-s` | Sort by file size, largest first | Off (sorted by path) |
| `-h` | Show help and exit | — |
| (positional) | Directory to scan | Current directory (`.`) |

**Examples:**
```bash
# Scan a specific folder
./find_exe.sh /home/yourname

# With dates, sorted by size
./find_exe.sh -d -s /opt

# Scan the whole system (may be slow)
./find_exe.sh /

# On WSL — scan your Windows C: drive
./find_exe.sh /mnt/c/Users/YourName
```

---

## Output

### File Table

Each result row shows:

```
   #         SIZE   [MODIFIED]          PATH
------------------------------------------------------------
   1     12.00 MB   2024-11-03 10:22:01   C:\Games\doom.exe
   2      3.00 MB   2024-09-18 08:14:55   C:\Games\quake3.exe
   3    512.00 KB   2025-01-07 16:03:44   C:\Tools\notepad++.exe
```

### Size Colour Key

| Colour | Size range |
|--------|------------|
| Green | Less than 1 MB |
| Yellow | 1 MB – 10 MB |
| Orange / DarkYellow | 10 MB – 100 MB |
| Red | 100 MB or larger |

### Summary Footer

After the table, a summary is printed:

```
  Summary
  *  Files found  : 6
  *  Total size   : 16.69 MB
  *  Search root  : C:\Users\YourName
  !  Skipped dirs : 3 (permission denied)
```

---

## Delete Options

After the scan, you are presented with three choices:

```
  [A]  Delete ALL 6 files  (16.69 MB)
  [S]  Select specific files by number
  [N]  Do nothing and exit
```

### A — Delete All

Deletes every file found. You must type `DELETE` (all caps) to confirm. Anything else cancels safely.

### S — Select Specific

Enter a list of row numbers, separated by spaces or commas:

```
  Numbers: 1 3 5
  Numbers: 2,4,7
```

A preview of the selected files and their combined size is shown before you confirm. Again, type `DELETE` to proceed or anything else to cancel.

### N — Exit

Closes the script without touching any files.

---

## Edge Cases

| Situation | Behaviour |
|-----------|-----------|
| Directory does not exist | Error message printed, script exits |
| No `.exe` files found | Friendly notice, script exits cleanly |
| Permission denied on a subdirectory | Skipped silently; count shown in summary |
| A file cannot be deleted (locked/read-only) | Reported as `[FAIL]`, script continues with remaining files |
| Invalid number entered in select mode | Warned and ignored; valid entries still processed |

---

## Requirements

### PowerShell version (`ex-finder.ps1`)
- Windows 10 or Windows 11
- Windows PowerShell 5.1 (pre-installed) **or** PowerShell 7+
- No third-party modules required

### Bash version (`find_exe.sh`)
- Bash 4.0 or later
- Standard Unix utilities: `find`, `stat`, `sort`, `wc`, `mktemp`
- Available on Linux, macOS, and WSL (Windows Subsystem for Linux)

---

## File Structure

```
find-your-ex/
├── ex-finder.ps1       # Windows PowerShell script
├── find_exe.sh         # Linux / macOS / WSL Bash script
└── README.md           # This file
```

---

## Tips

- **Run as Administrator** (Windows) or with `sudo` (Linux) if you want to scan system directories that are normally restricted.
- Scanning the root of a large drive (`C:\` or `/`) can take a minute or two depending on the number of files.
- The `-SortSize` flag is useful for quickly identifying the largest executables to free up the most disk space.
- Deleted files **do not go to the Recycle Bin** — they are permanently removed. Use the select option (`S`) if you want to review before deleting.

---

## License

MIT — free to use, modify, and distribute.