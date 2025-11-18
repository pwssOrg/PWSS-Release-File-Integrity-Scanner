# Version: 1.7
# Date: November 18, 2025
# Author:  © PWSS Org


if ($MyInvocation.MyCommand.Path) {
    $scriptDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
} else {
    $scriptDirectory = [System.AppContext]::BaseDirectory
}


# Change the working directory to scriptDirectory so that all relative paths work
Set-Location $scriptDirectory


Get-ChildItem -Path "$scriptDirectory\*.ps1" -File | Unblock-File

function Start-DB-If-Not-Running {
    $portInUse = netstat -ano | Select-String ":26556"

    if ($null -eq $portInUse) {
       # Write-Host "Nothing is running on port 26556. Starting the process..."
        # Start the PostgreSQL service on custom port
        & "$env:FIS_PSQL" start `
        -D "`"$env:FIS_DATA`"" `
        -l "`"$env:FIS_DATA\logfile.txt`"" `
        -o "-p 26556" `
        -w
    }
}

try{

$hashVerifyIntegrity = (Get-FileHash -Algorithm "SHA256" "$scriptDirectory\..\verify_integrity\verify_integrity.ps1").Hash
if($hashVerifyIntegrity -eq "FEF0BEE337EA4658699F62C69BF536DCBF22415F9688F0E11B6A4F3DC1110BD1"){

# Write-Host -ForegroundColor Green "The file (verify_integrity.ps1) hash matches the expected SHA256."

}

else {
    Write-Host -ForegroundColor Red "The file (verify_integrity.ps1) hash does NOT match the expected SHA256."
    exit
}


. "$scriptDirectory\..\verify_integrity\verify_integrity.ps1"

$fileIntegrityScannerJar = "$scriptDirectory\local_backend\File-Integrity-Scanner-1.8.1.jar"
$expectedSha256FileIntegrityScannerJar = "9D15F2A6F89CC1C37A31DB3FCCF404ED4CAF60FABB55BC9CAAB4D97B0267293D"

if (Verify-SHA256 -FilePath $fileIntegrityScannerJar -ExpectedHash $expectedSha256FileIntegrityScannerJar) {
    # Write-Host -ForegroundColor Green "The file (File-Integrity-Scanner-1.8.1.jar) hash matches the expected SHA256."
} else {
    Write-Host -ForegroundColor Red "The file (File-Integrity-Scanner-1.8.1.jar) hash does NOT match the expected SHA256."
    Contact-Message
    exit

}

$integrityHashJar = "$scriptDirectory\frontend\integrity_hash-1.1.jar"
$expectedSha256IntegrityHashJar = "74D77E5BE4BE475400A52884B5461E04FCB3FB732B982EFC1EA2D7D08A1F2CB3"

if (Verify-SHA256 -FilePath $integrityHashJar -ExpectedHash $expectedSha256IntegrityHashJar) {
    # Write-Host -ForegroundColor Green "The file (integrity_hash-1.1.jar) hash matches the expected SHA256."
} else {
    Write-Host -ForegroundColor Red "The file (integrity_hash-1.1.jar) hash does NOT match the expected SHA256."
    Contact-Message
    exit

}

} catch{


 Write-Host -ForegroundColor Red "The Integrity hash was unable to start due to an error. Extracting hashes from artifact files is not possible"
    exit

    }


Start-DB-If-Not-Running

# Write-Host "Checking if anything is running on port 15400..."

$portInUse = netstat -ano | Select-String ":15400"

# Set the working path to the frontend folder (Integrity Hash needs to point to the correct path for app settings and options folder)
cd "$scriptDirectory\frontend"


if ($null -eq $portInUse) {
    # Write-Host "Nothing is running on port 15400. Starting the process..."

    
    Start-Process -FilePath "java" -ArgumentList "-jar", ".\..\local_backend\File-Integrity-Scanner-1.7.jar" -NoNewWindow
    # Write-Host "File-Integrity-Scanner started."
    
    Start-Process -FilePath "java" `
    -ArgumentList "-jar `".\integrity_hash-1.1.jar`"" `
    -NoNewWindow `
    -Wait
    Stop-Process -Id $pid
} else {
   # Write-Host "File-Integrity-Scanner is already running on port 15400."
   Start-Process -FilePath "java" `
    -ArgumentList "-jar `".\integrity_hash-1.1.jar`"" `
    -NoNewWindow `
    -Wait
   Stop-Process -Id $pid 
}
