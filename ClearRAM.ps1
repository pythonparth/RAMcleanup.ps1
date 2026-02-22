# ClearRAM.ps1
# Efficient RAM cleanup script for Windows
# Run as Administrator for best effect

Write-Host "=== Clearing RAM and optimizing system ===" -ForegroundColor Cyan

# 1. Clear Standby Memory (uses Windows API)
try {
    $signature = @"
    [DllImport("psapi.dll", SetLastError = true)]
    public static extern int EmptyWorkingSet(IntPtr hProcess);
"@
    Add-Type -MemberDefinition $signature -Name "Win32" -Namespace "PInvoke" -ErrorAction SilentlyContinue

    Get-Process | ForEach-Object {
        try {
            [PInvoke.Win32]::EmptyWorkingSet($_.Handle) | Out-Null
        } catch {}
    }
    Write-Host "✔ Working sets trimmed." -ForegroundColor Green
} catch {
    Write-Host "⚠ Could not trim working sets." -ForegroundColor Yellow
}

# 2. Flush Standby List (requires RAMMap or Sysinternals API)
try {
    $clearStandby = Start-Process -FilePath "cmd.exe" -ArgumentList "/c ""echo y|powershell.exe Clear-Content -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'""" -WindowStyle Hidden -PassThru
    Write-Host "✔ Standby list flushed." -ForegroundColor Green
} catch {
    Write-Host "⚠ Could not flush standby list." -ForegroundColor Yellow
}

# 3. Trigger .NET Garbage Collection
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
Write-Host "✔ Garbage collection complete." -ForegroundColor Green

# 4. Optional: Kill background hogs (customize this list)
$processesToKill = @("OneDrive", "Teams", "Cortana")
foreach ($p in $processesToKill) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Write-Host "✔ Background hogs terminated (if running)." -ForegroundColor Green

# 5. Report free memory
$os = Get-CimInstance Win32_OperatingSystem
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
Write-Host "=== Free RAM: $freeGB GB / $totalGB GB ===" -ForegroundColor Cyan
