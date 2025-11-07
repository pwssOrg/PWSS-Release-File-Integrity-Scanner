Write-Host "Checking if anything is running on port 15400..."

$portInUse = netstat -ano | Select-String ":15400"

if ($null -eq $portInUse) {
    Write-Host "Nothing is running on port 15400. Starting the process..."
    java -jar "local_be\File-Integrity-Scanner-1.4.jar" & 
    Write-Host "File-Integrity-Scanner started."
    java -jar file_integrity_gui-0.5.jar
    Stop-Process -Id $pid
} else {
    Write-Host "File-Integrity-Scanner is already running on port 15400."
    java -jar file_integrity_gui-0.5.jar
    Stop-Process -Id $pid 
}