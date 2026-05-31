#Requires -Version 5.1
# ╔══════════════════════════════════════════════════════════════════╗
# ║          EXE FILE HUNTER  —  ex-finder.ps1                  ║
# ║  Recursively finds, displays, and optionally deletes .exe files ║
# ╚══════════════════════════════════════════════════════════════════╝

[CmdletBinding()]
param(
    [string] $Path     = ".",
    [switch] $ShowDate,
    [switch] $SortSize,
    [switch] $NoRecurse,
    [switch] $Help
)

# ─── UTF-8 so Unicode symbols render correctly ─────────────────────
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# ─── Terminal width ────────────────────────────────────────────────
function Get-TermWidth {
    try   { $Host.UI.RawUI.WindowSize.Width }
    catch { 80 }
}

# ─── Print helpers ────────────────────────────────────────────────
function Write-Centered {
    param([string]$Text, [ConsoleColor]$Color = 'White')
    $width = Get-TermWidth
    $pad   = [Math]::Max(0, [Math]::Floor(($width - $Text.Length) / 2))
    Write-Host (" " * $pad + $Text) -ForegroundColor $Color
}

function Write-Line {
    param([string]$Char = "-", [ConsoleColor]$Color = 'DarkGray')
    $width = Get-TermWidth
    Write-Host ($Char * $width) -ForegroundColor $Color
}

function Write-DoubleLine {
    param([ConsoleColor]$Color = 'Cyan')
    $width = Get-TermWidth
    Write-Host ("=" * $width) -ForegroundColor $Color
}

# ─── Human-readable size ───────────────────────────────────────────
function Format-FileSize {
    param([long]$Bytes)
    if     ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    elseif ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    else                    { return "$Bytes  B" }
}

# ─── Size colour ──────────────────────────────────────────────────
function Get-SizeColor {
    param([long]$Bytes)
    if     ($Bytes -ge 100MB) { return 'Red'         }
    elseif ($Bytes -ge  10MB) { return 'DarkYellow'  }
    elseif ($Bytes -ge   1MB) { return 'Yellow'      }
    else                      { return 'Green'        }
}

# ─── Banner ───────────────────────────────────────────────────────
function Show-Banner {
    Write-Host ""
    Write-DoubleLine Cyan
    Write-Host ""
    Write-Centered "*** EXE FILE HUNTER ***" Cyan
    Write-Centered "Recursively locates Windows executables on your system" DarkGray
    Write-Host ""
    Write-DoubleLine Cyan
    Write-Host ""
}

# ─── Help ─────────────────────────────────────────────────────────
function Show-Help {
    Show-Banner
    Write-Host "  USAGE" -ForegroundColor White
    Write-Host "    .\Find-ExeFiles.ps1 [-Path <dir>] [-ShowDate] [-SortSize] [-NoRecurse] [-Help]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  PARAMETERS" -ForegroundColor White
    Write-Host "    -Path       Directory to scan (default: current directory)" -ForegroundColor Gray
    Write-Host "    -ShowDate   Show last-modified date column" -ForegroundColor Gray
    Write-Host "    -SortSize   Sort results by size, largest first" -ForegroundColor Gray
    Write-Host "    -NoRecurse  Only search the specified folder, do not search subfolders" -ForegroundColor Gray
    Write-Host "    -Help       Show this help message" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  EXAMPLES" -ForegroundColor White
    Write-Host "    .\ex-finder.ps1" -ForegroundColor DarkGray
    Write-Host "    .\ex-finder.ps1 -Path C:\Users\YourName -NoRecurse" -ForegroundColor DarkGray
    Write-Host "    .\ex-finder.ps1 -Path C:\ -ShowDate -SortSize" -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

# ══════════════════════════════════════════════════════════════════
#  ENTRY POINT
# ══════════════════════════════════════════════════════════════════

if ($Help) { Show-Help }

# ─── Validate directory ───────────────────────────────────────────
$resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
if (-not $resolvedPath) {
    Write-Host ""
    Write-Host "  [ERROR] Directory not found: $Path" -ForegroundColor Red
    Write-Host ""
    exit 1
}
$SearchDir = $resolvedPath.Path

Show-Banner

Write-Host "  Root path : " -NoNewline -ForegroundColor DarkGray
Write-Host $SearchDir -ForegroundColor White

Write-Host "  Show dates: " -NoNewline -ForegroundColor DarkGray
if ($ShowDate) { Write-Host "yes" -ForegroundColor White }
else           { Write-Host "no"  -ForegroundColor White }


Write-Host "  Sort order: " -NoNewline -ForegroundColor DarkGray
if ($SortSize) { Write-Host "by size (largest first)" -ForegroundColor White }
else           { Write-Host "by path"                 -ForegroundColor White }

Write-Host "  Recursive  : " -NoNewline -ForegroundColor DarkGray
if ($NoRecurse) { Write-Host "no (only this folder)" -ForegroundColor White }
else            { Write-Host "yes (all subfolders)"  -ForegroundColor White }
Write-Host ""

# ─── Scan ─────────────────────────────────────────────────────────
Write-Host "  [SCANNING] Please wait, this may take a moment..." -ForegroundColor Cyan
Write-Host ""

$permErrors = 0
$files      = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

if ($NoRecurse) {
    Get-ChildItem -Path $SearchDir -Filter "*.exe" -File -ErrorAction SilentlyContinue -ErrorVariable scanErrors |
        ForEach-Object { $files.Add($_) }
} else {
    Get-ChildItem -Path $SearchDir -Filter "*.exe" -Recurse -File -ErrorAction SilentlyContinue -ErrorVariable scanErrors |
        ForEach-Object { $files.Add($_) }
}

$permErrors = $scanErrors.Count

# ─── Sort ─────────────────────────────────────────────────────────
if ($SortSize) {
    $files = @($files | Sort-Object Length -Descending)
} else {
    $files = @($files | Sort-Object FullName)
}

$total = $files.Count

# ─── No files found ───────────────────────────────────────────────
if ($total -eq 0) {
    Write-Line "-" DarkGray
    Write-Host ""
    Write-Centered "[!] No .exe files found under $SearchDir" Yellow
    if ($permErrors -gt 0) {
        if ($permErrors -eq 1) { $word = "directory" } else { $word = "directories" }
        Write-Centered "($permErrors $word skipped due to permission errors)" DarkGray
    }
    Write-Host ""
    Write-Line "-" DarkGray
    Write-Host ""
    exit 0
}

# ─── Table header ─────────────────────────────────────────────────
Write-Line "-" DarkGray
Write-Host ""

Write-Host ("  {0,-5}  {1,-13}" -f "#", "SIZE") -NoNewline -ForegroundColor Cyan
if ($ShowDate) {
    Write-Host ("{0,-21}" -f "MODIFIED") -NoNewline -ForegroundColor Cyan
}
Write-Host "PATH" -ForegroundColor Cyan
Write-Line "-" DarkGray

# ─── File rows ────────────────────────────────────────────────────
$totalBytes = [long]0
$idx        = 0

foreach ($file in $files) {
    $idx++
    $totalBytes += $file.Length

    $sizeStr  = Format-FileSize $file.Length
    $sizeCol  = Get-SizeColor   $file.Length
    $dir      = $file.DirectoryName
    $base     = $file.Name

    if ($idx % 2 -eq 0) { $rowColor = 'White' } else { $rowColor = 'Gray' }

    Write-Host ("  {0,4}  " -f $idx) -NoNewline -ForegroundColor DarkGray
    Write-Host ("{0,13}  " -f $sizeStr) -NoNewline -ForegroundColor $sizeCol

    if ($ShowDate) {
        $mtime = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host ("{0,-22}" -f $mtime) -NoNewline -ForegroundColor DarkGray
    }

    Write-Host "$dir\" -NoNewline -ForegroundColor $rowColor
    Write-Host $base -ForegroundColor DarkYellow
}

# ─── Summary ──────────────────────────────────────────────────────
Write-Line "-" DarkGray
Write-Host ""
Write-Host "  Summary" -ForegroundColor White
Write-Host "  *  Files found  : " -NoNewline -ForegroundColor DarkGray
Write-Host $total -ForegroundColor Cyan
Write-Host "  *  Total size   : " -NoNewline -ForegroundColor DarkGray
Write-Host (Format-FileSize $totalBytes) -ForegroundColor Yellow
Write-Host "  *  Search root  : " -NoNewline -ForegroundColor DarkGray
Write-Host $SearchDir -ForegroundColor DarkGray

if ($permErrors -gt 0) {
    Write-Host "  !  Skipped dirs : " -NoNewline -ForegroundColor DarkYellow
    Write-Host "$permErrors (permission denied)" -ForegroundColor DarkYellow
}

Write-Host ""
Write-Line "-" DarkGray

# ─── Legend ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Size colour key:  " -NoNewline -ForegroundColor DarkGray
Write-Host "[Green] < 1 MB   "    -NoNewline -ForegroundColor Green
Write-Host "[Yellow] 1-10 MB   "  -NoNewline -ForegroundColor Yellow
Write-Host "[Orange] 10-100 MB   " -NoNewline -ForegroundColor DarkYellow
Write-Host "[Red] >= 100 MB"       -ForegroundColor Red
Write-Host ""

# ─── Delete menu ──────────────────────────────────────────────────
Write-DoubleLine Magenta
Write-Host ""
Write-Host "  [DELETE OPTIONS]" -ForegroundColor Magenta
Write-Host ""
Write-Host "  [A]" -NoNewline -ForegroundColor Cyan
Write-Host "  Delete ALL $total files  " -NoNewline
Write-Host "($(Format-FileSize $totalBytes))" -ForegroundColor DarkGray
Write-Host "  [S]" -NoNewline -ForegroundColor Cyan
Write-Host "  Select specific files by number"
Write-Host "  [N]" -NoNewline -ForegroundColor Cyan
Write-Host "  Do nothing and exit"
Write-Host ""
$choice = (Read-Host "  Your choice").Trim().ToUpper()
Write-Host ""

# ─── Delete All ───────────────────────────────────────────────────
if ($choice -eq "A") {
    Write-Host ""
    Write-Host "  [WARNING] This will permanently delete ALL $total files!" -ForegroundColor Red
    Write-Host ""
    $confirm = Read-Host "  Type DELETE to confirm, or anything else to cancel"
    Write-Host ""

    if ($confirm -ceq "DELETE") {
        Write-Line "-" Red
        $deleted = 0
        $failed  = 0

        foreach ($file in $files) {
            $removed = $false
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                $removed = $true
            } catch {
                $removed = $false
            }
            if ($removed) {
                Write-Host "  [OK]    Deleted: " -NoNewline -ForegroundColor Green
                Write-Host $file.FullName -ForegroundColor DarkGray
                $deleted++
            } else {
                Write-Host "  [FAIL]  Failed : " -NoNewline -ForegroundColor Red
                Write-Host "$($file.FullName)  (access denied?)" -ForegroundColor DarkYellow
                $failed++
            }
        }

        Write-Line "-" Red
        Write-Host ""
        Write-Host "  [OK]  Deleted : $deleted file(s)" -ForegroundColor Green
        if ($failed -gt 0) {
            Write-Host "  [!!]  Failed  : $failed file(s)" -ForegroundColor Red
        }
        Write-Host ""

    } else {
        Write-Host "  [SAFE] Deletion cancelled. No files were removed." -ForegroundColor Green
        Write-Host ""
    }

# ─── Select Specific ──────────────────────────────────────────────
} elseif ($choice -eq "S") {
    Write-Host ""
    Write-Host "  Enter file numbers separated by spaces or commas." -ForegroundColor White
    Write-Host "  Example: 1 3 7  or  2,5,9" -ForegroundColor DarkGray
    Write-Host ""
    $rawInput = Read-Host "  Numbers"
    Write-Host ""

    $tokens   = ($rawInput -replace ",", " ") -split "\s+" | Where-Object { $_ -ne "" }
    $toDelete = [System.Collections.Generic.List[int]]::new()
    $bad      = [System.Collections.Generic.List[string]]::new()

    foreach ($token in $tokens) {
        $n = 0
        if ([int]::TryParse($token, [ref]$n) -and $n -ge 1 -and $n -le $total) {
            $toDelete.Add($n)
        } else {
            $bad.Add($token)
        }
    }

    if ($bad.Count -gt 0) {
        Write-Host "  [!] Ignored invalid entries: $($bad -join ', ')" -ForegroundColor DarkYellow
        Write-Host ""
    }

    if ($toDelete.Count -eq 0) {
        Write-Host "  [!] No valid file numbers entered. Exiting." -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "  Files selected for deletion:" -ForegroundColor White
        Write-Host ""
        $bytesSelected = [long]0

        foreach ($n in $toDelete) {
            $f = $files[$n - 1]
            $bytesSelected += $f.Length
            Write-Host "  >> " -NoNewline -ForegroundColor Red
            Write-Host ("{0,4}  " -f $n) -NoNewline -ForegroundColor Cyan
            Write-Host $f.FullName -ForegroundColor Gray
        }

        Write-Host ""
        Write-Host "  Total space to free: " -NoNewline -ForegroundColor DarkGray
        Write-Host (Format-FileSize $bytesSelected) -ForegroundColor Yellow
        Write-Host ""

        $confirm2 = Read-Host "  Type DELETE to confirm, or anything else to cancel"
        Write-Host ""

        if ($confirm2 -ceq "DELETE") {
            Write-Line "-" Red
            $deleted = 0
            $failed  = 0

            foreach ($n in $toDelete) {
                $f       = $files[$n - 1]
                $removed = $false
                try {
                    Remove-Item -Path $f.FullName -Force -ErrorAction Stop
                    $removed = $true
                } catch {
                    $removed = $false
                }
                if ($removed) {
                    Write-Host "  [OK]    Deleted: " -NoNewline -ForegroundColor Green
                    Write-Host $f.FullName -ForegroundColor DarkGray
                    $deleted++
                } else {
                    Write-Host "  [FAIL]  Failed : " -NoNewline -ForegroundColor Red
                    Write-Host "$($f.FullName)  (access denied?)" -ForegroundColor DarkYellow
                    $failed++
                }
            }

            Write-Line "-" Red
            Write-Host ""
            Write-Host "  [OK]  Deleted : $deleted file(s)" -ForegroundColor Green
            if ($failed -gt 0) {
                Write-Host "  [!!]  Failed  : $failed file(s)" -ForegroundColor Red
            }
            Write-Host ""

        } else {
            Write-Host "  [SAFE] Deletion cancelled. No files were removed." -ForegroundColor Green
            Write-Host ""
        }
    }

# ─── Exit ─────────────────────────────────────────────────────────
} elseif ($choice -eq "N" -or $choice -eq "") {
    Write-Host "  [SAFE] No files deleted. Goodbye!" -ForegroundColor Green
    Write-Host ""

} else {
    Write-Host "  [!] Unrecognised option '$choice'. No files deleted." -ForegroundColor DarkYellow
    Write-Host ""
}

Write-DoubleLine Cyan
Write-Host ""