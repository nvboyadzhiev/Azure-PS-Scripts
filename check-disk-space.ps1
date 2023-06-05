$serverList = Get-Content -Path "C:\TEMP\SAPDEV.txt" | Where-Object { $_.Trim() -ne "" }  # Path to the text file containing server names
$threshold = 85  # Disk usage threshold percentage

$exceededServers = @()

foreach ($server in $serverList) {
    Write-Host "Checking disk space on $server"

    try {
        $pingResult = Test-Connection -ComputerName $server -Count 1 -Quiet
        if ($pingResult) {
            $disk = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $server -Filter "DeviceID='C:'" -ErrorAction Stop
            $freeSpaceBytes = $disk.FreeSpace
            $totalSpaceBytes = $disk.Size

            $usedSpacePercent = [math]::Round(($totalSpaceBytes - $freeSpaceBytes) / $totalSpaceBytes * 100, 2)

            if ($usedSpacePercent -gt $threshold) {
                $exceededServers += $server
            }
        } else {
            Write-Host "Unable to reach server: $server"
        }
    } catch {
        Write-Host "Error occurred while checking disk space on $server - $($error[0].Exception.Message)"
    }
}

Write-Host "`nServers exceeding the threshold:"
$exceededServers