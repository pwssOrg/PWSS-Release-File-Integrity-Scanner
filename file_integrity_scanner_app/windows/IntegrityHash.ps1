# Version: 1.7
# Date: May 24, 2026
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

$hashVerifyIntegrity = (Get-FileHash -Algorithm "SHA256" "$scriptDirectory\..\..\verify_integrity\verify_integrity.ps1").Hash
if($hashVerifyIntegrity -eq "FEF0BEE337EA4658699F62C69BF536DCBF22415F9688F0E11B6A4F3DC1110BD1"){

# Write-Host -ForegroundColor Green "The file (verify_integrity.ps1) hash matches the expected SHA256."

}

else {
    Write-Host -ForegroundColor Red "The file (verify_integrity.ps1) hash does NOT match the expected SHA256."
    exit
}


. "$scriptDirectory\..\..\verify_integrity\verify_integrity.ps1"

$fileIntegrityScannerJar = "$scriptDirectory\..\local_backend\File-Integrity-Scanner-1.9.1.jar"
$expectedSha256FileIntegrityScannerJar = "7B4E109D70C30732D3C3E174CE8002A1F539439A4E808510272EDE8006E7981B"

if (Verify-SHA256 -FilePath $fileIntegrityScannerJar -ExpectedHash $expectedSha256FileIntegrityScannerJar) {
    # Write-Host -ForegroundColor Green "The file (File-Integrity-Scanner-1.9.1.jar) hash matches the expected SHA256."
} else {
    Write-Host -ForegroundColor Red "The file (File-Integrity-Scanner-1.9.1.jar) hash does NOT match the expected SHA256."
    Contact-Message
    exit

}

$integrityHashJar = "$scriptDirectory\..\frontend\integrity_hash-1.2.4.jar"
$expectedSha256IntegrityHashJar = "5D26977B0280D4B22F1B43AE3CF4FA774B8BE97496FB4CA6CC7ECC0E80E909E0"

if (Verify-SHA256 -FilePath $integrityHashJar -ExpectedHash $expectedSha256IntegrityHashJar) {
    # Write-Host -ForegroundColor Green "The file (integrity_hash-1.2.4.jar) hash matches the expected SHA256."
} else {
    Write-Host -ForegroundColor Red "The file (integrity_hash-1.2.4.jar) hash does NOT match the expected SHA256."
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
cd "$scriptDirectory\..\frontend"


if ($null -eq $portInUse) {
    # Write-Host "Nothing is running on port 15400. Starting the process..."

    
    Start-Process -FilePath "java" -ArgumentList "-jar", ".\..\local_backend\File-Integrity-Scanner-1.9.1.jar" -NoNewWindow
    # Write-Host "File-Integrity-Scanner started."
    
    Start-Process -FilePath "java" `
    -ArgumentList "-jar `".\integrity_hash-1.2.4.jar`"" `
    -NoNewWindow `
    -Wait
    Stop-Process -Id $pid
} else {
   # Write-Host "File-Integrity-Scanner is already running on port 15400."
   Start-Process -FilePath "java" `
    -ArgumentList "-jar `".\integrity_hash-1.2.4.jar`"" `
    -NoNewWindow `
    -Wait
   Stop-Process -Id $pid 
}

# SIG # Begin signature block
# MIIFngYJKoZIhvcNAQcCoIIFjzCCBYsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDNQiTzJTLiE4B/
# 6fziURa+RyNDf6+rh47y3SHI0MV+iqCCAxAwggMMMIIB9KADAgECAhBeZW/A4sNK
# o0SAMEesMIGFMA0GCSqGSIb3DQEBCwUAMB4xHDAaBgNVBAMME1BXU1MgSW50ZWdy
# aXR5IEhhc2gwHhcNMjYwNTEwMTMyMjIxWhcNMjcwNTEwMTM0MjIxWjAeMRwwGgYD
# VQQDDBNQV1NTIEludGVncml0eSBIYXNoMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEA2pSzNsVgdNkPKvyOWADNRyLoSqoLXbFQkpy4iXLDW1eyzDvOFyFk
# 9L9V2k6OokgNDWirW2tWloO4HT8FfWvQjgUrneU9X6ezwY/TqbfIL28hqxuyoGXT
# fMYChA/HqV2O5MVgKd2Mk9INIFHZfvpiDITEkheaphmytr8KghcYu58mWrME59CF
# iPeSzTHLNjZr6qJMOtr7WrNL2h0+E3s+5Owy37v5yYbYFhAbEbiGjVlCFVd0Hkpw
# nnVPNPIb8HVIVbX8INVtG1cZXAX+QPOLdS83WM+6MhtMkG+VjAlnrsbGJLkaTK2Y
# 2b0jQc+RVIdUDKeNOPxywFBs0QDKQ52h6QIDAQABo0YwRDAOBgNVHQ8BAf8EBAMC
# B4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFDQ00Do6hqex0I/1nila
# aYOh3e+zMA0GCSqGSIb3DQEBCwUAA4IBAQDGFzFYPJnXD6/HSI/plDdAdUd7Bken
# ewOoyE7nxHROumZ1ZcALEY9Pbit8kDizeXjUrbQeemuffd3FtBqvypHqgOVsw0S0
# oOmB9XkaEqphFVO/q7SWXEqTpFyIVQnWUTxnoMI7EsxQ4I5L6R/LhJeY76kDfSl3
# oK2B7sQMkDXEnde0Mo42B+YU2ccEqIXtitnnRDKS8WOanFT7ue8gxpcZ21HiUH24
# 7xrpEF59u+FjfOPm6AvUmbz6ezeD4G3PxXr8rddsw6iOHNesW4qbdshvRQuz4fEU
# zKGq9hjlQFqab/533KpTTefaa5eFkUkMWWoCt1iMet5yLZiHqeFqqbdEMYIB5DCC
# AeACAQEwMjAeMRwwGgYDVQQDDBNQV1NTIEludGVncml0eSBIYXNoAhBeZW/A4sNK
# o0SAMEesMIGFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJf7COBh4euG9OjcojV94tGn
# gicmQKGCdHOg7D33zjgZMA0GCSqGSIb3DQEBAQUABIIBALxA8YpN3/nIHmeBnJHD
# CmbVz1ibnYYT02DGqbh6kCXrdND6KQtzVECNT1pB2zCwT8uY7anV8jKB3u67qM8J
# ytueYZdK1ULxPUN+tPrqrKchfYQQCL0xM+yyZdhwjNgkjtIRXnsuzJq5IAsyM5Sf
# dzGReL3dxRv0NxEQajQMKs4+dhZa6bgc4H9GCn6IB3gIDfDZNpdlf82OzEX99D4q
# 4a6GAblmFfLCLX957SArd1EUh/vDLZ4eRrUx3J7hnlb4+2yRhiimbWvG3ueIdw0M
# NmjOys9GY03FBGOBDgE0bZ6GjgGKtoBt0Sj8qVc2yhci2HbK/A6q45BqXQ02eY4Q
# kRM=
# SIG # End signature block
