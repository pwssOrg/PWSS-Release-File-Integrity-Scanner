param (
    [int]$port = 26556
)
 
Write-Host "Checking if anything is running on port $port..."
 
$processInfo = netstat -ano | Select-String ":$port"
 
if ($null -ne $processInfo) {
    # Extract the PID from the output
    $pid1 = ($processInfo -split '\s+')[5]
 
    Write-Host "Process with PID $pid is running on port $port. Killing the process..."
 
    Stop-Process -Id $pid1 -Force
 
    if (Get-Process -Id $pid1 -ErrorAction SilentlyContinue) {
        Write-Host "Failed to kill process with PID $pid1."
    } else {
        Write-Host "Successfully killed process with PID $pid1."
    }
} else {
    Write-Host "Nothing is running on port $port."
}