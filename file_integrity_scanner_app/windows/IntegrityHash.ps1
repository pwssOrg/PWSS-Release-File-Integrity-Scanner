# Version: 1.6
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

$fileIntegrityScannerJar = "$scriptDirectory\..\local_backend\File-Integrity-Scanner-1.9.jar"
$expectedSha256FileIntegrityScannerJar = "6680617E08B280CE3912F5FFA6929693CB120956F78263F6438C5BC9C2A8E5C8"

if (Verify-SHA256 -FilePath $fileIntegrityScannerJar -ExpectedHash $expectedSha256FileIntegrityScannerJar) {
    # Write-Host -ForegroundColor Green "The file (File-Integrity-Scanner-1.9.jar) hash matches the expected SHA256."
} else {
    Write-Host -ForegroundColor Red "The file (File-Integrity-Scanner-1.9.jar) hash does NOT match the expected SHA256."
    Contact-Message
    exit

}

$integrityHashJar = "$scriptDirectory\..\frontend\integrity_hash-1.2.3.jar"
$expectedSha256IntegrityHashJar = "E04CA51DDE652CC70DB6CDB96E0BACA591E3BDC76DAFD117CB21804A23C9E5D8"

if (Verify-SHA256 -FilePath $integrityHashJar -ExpectedHash $expectedSha256IntegrityHashJar) {
    # Write-Host -ForegroundColor Green "The file (integrity_hash-1.2.3.jar) hash matches the expected SHA256."
} else {
    Write-Host -ForegroundColor Red "The file (integrity_hash-1.2.3.jar) hash does NOT match the expected SHA256."
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

    
    Start-Process -FilePath "java" -ArgumentList "-jar", ".\..\local_backend\File-Integrity-Scanner-1.9.jar" -NoNewWindow
    # Write-Host "File-Integrity-Scanner started."
    
    Start-Process -FilePath "java" `
    -ArgumentList "-jar `".\integrity_hash-1.2.3.jar`"" `
    -NoNewWindow `
    -Wait
    Stop-Process -Id $pid
} else {
   # Write-Host "File-Integrity-Scanner is already running on port 15400."
   Start-Process -FilePath "java" `
    -ArgumentList "-jar `".\integrity_hash-1.2.3.jar`"" `
    -NoNewWindow `
    -Wait
   Stop-Process -Id $pid 
}

# SIG # Begin signature block
# MIIcAgYJKoZIhvcNAQcCoIIb8zCCG+8CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCBGETSJ4vUsAev
# sszGocYSBQN3+IiaBo8tSZ/32zPxnKCCFkowggMMMIIB9KADAgECAhBeZW/A4sNK
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
# zKGq9hjlQFqab/533KpTTefaa5eFkUkMWWoCt1iMet5yLZiHqeFqqbdEMIIFjTCC
# BHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0Ew
# HhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZ
# wuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4V
# pX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAd
# YyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3
# T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjU
# N6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNda
# SaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtm
# mnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyV
# w4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3
# AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYi
# Cd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmp
# sh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7Nfj
# gtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNt
# yA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUG
# A1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3
# DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+Ica
# aVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096ww
# epqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcD
# x4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsg
# jTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37Y
# OtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIGtDCCBJygAwIBAgIQDcesVwX/
# IZkuQEMiDDpJhjANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYD
# VQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjUwNTA3MDAwMDAwWhcN
# MzgwMTE0MjM1OTU5WjBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5n
# IFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAtHgx0wqYQXK+PEbAHKx126NGaHS0URedTa2NDZS1mZaDLFTtQ2oR
# jzUXMmxCqvkbsDpz4aH+qbxeLho8I6jY3xL1IusLopuW2qftJYJaDNs1+JH7Z+Qd
# SKWM06qchUP+AbdJgMQB3h2DZ0Mal5kYp77jYMVQXSZH++0trj6Ao+xh/AS7sQRu
# QL37QXbDhAktVJMQbzIBHYJBYgzWIjk8eDrYhXDEpKk7RdoX0M980EpLtlrNyHw0
# Xm+nt5pnYJU3Gmq6bNMI1I7Gb5IBZK4ivbVCiZv7PNBYqHEpNVWC2ZQ8BbfnFRQV
# ESYOszFI2Wv82wnJRfN20VRS3hpLgIR4hjzL0hpoYGk81coWJ+KdPvMvaB0WkE/2
# qHxJ0ucS638ZxqU14lDnki7CcoKCz6eum5A19WZQHkqUJfdkDjHkccpL6uoG8pbF
# 0LJAQQZxst7VvwDDjAmSFTUms+wV/FbWBqi7fTJnjq3hj0XbQcd8hjj/q8d6ylgx
# CZSKi17yVp2NL+cnT6Toy+rN+nM8M7LnLqCrO2JP3oW//1sfuZDKiDEb1AQ8es9X
# r/u6bDTnYCTKIsDq1BtmXUqEG1NqzJKS4kOmxkYp2WyODi7vQTCBZtVFJfVZ3j7O
# gWmnhFr4yUozZtqgPrHRVHhGNKlYzyjlroPxul+bgIspzOwbtmsgY1MCAwEAAaOC
# AV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFO9vU0rp5AZ8esri
# kFb2L9RJ7MtOMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1Ud
# DwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcw
# AoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJv
# b3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwB
# BAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQAXzvsWgBz+Bz0RdnEw
# vb4LyLU0pn/N0IfFiBowf0/Dm1wGc/Do7oVMY2mhXZXjDNJQa8j00DNqhCT3t+s8
# G0iP5kvN2n7Jd2E4/iEIUBO41P5F448rSYJ59Ib61eoalhnd6ywFLerycvZTAz40
# y8S4F3/a+Z1jEMK/DMm/axFSgoR8n6c3nuZB9BfBwAQYK9FHaoq2e26MHvVY9gCD
# A/JYsq7pGdogP8HRtrYfctSLANEBfHU16r3J05qX3kId+ZOczgj5kjatVB+NdADV
# ZKON/gnZruMvNYY2o1f4MXRJDMdTSlOLh0HCn2cQLwQCqjFbqrXuvTPSegOOzr4E
# Wj7PtspIHBldNE2K9i697cvaiIo2p61Ed2p8xMJb82Yosn0z4y25xUbI7GIN/TpV
# fHIqQ6Ku/qjTY6hc3hsXMrS+U0yy+GWqAXam4ToWd2UQ1KYT70kZjE4YtL8Pbzg0
# c1ugMZyZZd/BdHLiRu7hAWE6bTEm4XYRkA6Tl4KSFLFk43esaUeqGkH/wyW4N7Oi
# gizwJWeukcyIPbAvjSabnf7+Pu0VrFgoiovRDiyx3zEdmcif/sYQsfch28bZeUz2
# rtY/9TCA6TD8dC3JE3rYkrhLULy7Dc90G6e8BlqmyIjlgp2+VqsS9/wQD7yFylIz
# 0scmbKvFoW2jNrbM1pD2T7m3XDCCBu0wggTVoAMCAQICEAqA7xhLjfEFgtHEdqeV
# dGgwDQYJKoZIhvcNAQELBQAwaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lD
# ZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFt
# cGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMTAeFw0yNTA2MDQwMDAwMDBaFw0z
# NjA5MDMyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgU0hBMjU2IFJTQTQwOTYgVGltZXN0YW1w
# IFJlc3BvbmRlciAyMDI1IDEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQDQRqwtEsae0OquYFazK1e6b1H/hnAKAd/KN8wZQjBjMqiZ3xTWcfsLwOvRxUwX
# cGx8AUjni6bz52fGTfr6PHRNv6T7zsf1Y/E3IU8kgNkeECqVQ+3bzWYesFtkepEr
# vUSbf+EIYLkrLKd6qJnuzK8Vcn0DvbDMemQFoxQ2Dsw4vEjoT1FpS54dNApZfKY6
# 1HAldytxNM89PZXUP/5wWWURK+IfxiOg8W9lKMqzdIo7VA1R0V3Zp3DjjANwqAf4
# lEkTlCDQ0/fKJLKLkzGBTpx6EYevvOi7XOc4zyh1uSqgr6UnbksIcFJqLbkIXIPb
# cNmA98Oskkkrvt6lPAw/p4oDSRZreiwB7x9ykrjS6GS3NR39iTTFS+ENTqW8m6TH
# uOmHHjQNC3zbJ6nJ6SXiLSvw4Smz8U07hqF+8CTXaETkVWz0dVVZw7knh1WZXOLH
# gDvundrAtuvz0D3T+dYaNcwafsVCGZKUhQPL1naFKBy1p6llN3QgshRta6Eq4B40
# h5avMcpi54wm0i2ePZD5pPIssoszQyF4//3DoK2O65Uck5Wggn8O2klETsJ7u8xE
# ehGifgJYi+6I03UuT1j7FnrqVrOzaQoVJOeeStPeldYRNMmSF3voIgMFtNGh86w3
# ISHNm0IaadCKCkUe2LnwJKa8TIlwCUNVwppwn4D3/Pt5pwIDAQABo4IBlTCCAZEw
# DAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU5Dv88jHt/f3X85FxYxlQQ89hjOgwHwYD
# VR0jBBgwFoAU729TSunkBnx6yuKQVvYv1Ensy04wDgYDVR0PAQH/BAQDAgeAMBYG
# A1UdJQEB/wQMMAoGCCsGAQUFBwMIMIGVBggrBgEFBQcBAQSBiDCBhTAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMF0GCCsGAQUFBzAChlFodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3Rh
# bXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcnQwXwYDVR0fBFgwVjBUoFKgUIZO
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0
# YW1waW5nUlNBNDA5NlNIQTI1NjIwMjVDQTEuY3JsMCAGA1UdIAQZMBcwCAYGZ4EM
# AQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAgEAZSqt8RwnBLmuYEHs
# 0QhEnmNAciH45PYiT9s1i6UKtW+FERp8FgXRGQ/YAavXzWjZhY+hIfP2JkQ38U+w
# tJPBVBajYfrbIYG+Dui4I4PCvHpQuPqFgqp1PzC/ZRX4pvP/ciZmUnthfAEP1HSh
# TrY+2DE5qjzvZs7JIIgt0GCFD9ktx0LxxtRQ7vllKluHWiKk6FxRPyUPxAAYH2Vy
# 1lNM4kzekd8oEARzFAWgeW3az2xejEWLNN4eKGxDJ8WDl/FQUSntbjZ80FU3i54t
# px5F/0Kr15zW/mJAxZMVBrTE2oi0fcI8VMbtoRAmaaslNXdCG1+lqvP4FbrQ6IwS
# BXkZagHLhFU9HCrG/syTRLLhAezu/3Lr00GrJzPQFnCEH1Y58678IgmfORBPC1JK
# kYaEt2OdDh4GmO0/5cHelAK2/gTlQJINqDr6JfwyYHXSd+V08X1JUPvB4ILfJdmL
# +66Gp3CSBXG6IwXMZUXBhtCyIaehr0XkBoDIGMUG1dUtwq1qmcwbdUfcSYCn+Own
# cVUXf53VJUNOaMWMts0VlRYxe5nK+At+DI96HAlXHAL5SlfYxJ7La54i71McVWRP
# 66bW+yERNpbJCjyCYG2j+bdpxo/1Cy4uPcU3AWVPGrbn5PhDBf3Froguzzhk++am
# i+r3Qrx5bIbY3TVzgiFI7Gq3zWcxggUOMIIFCgIBATAyMB4xHDAaBgNVBAMME1BX
# U1MgSW50ZWdyaXR5IEhhc2gCEF5lb8Diw0qjRIAwR6wwgYUwDQYJYIZIAWUDBAIB
# BQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG
# 9w0BCQQxIgQgJPidMX2anePMlTyIzyGj0WZ7DgGJp3Eu/mz4/LrzBTwwDQYJKoZI
# hvcNAQEBBQAEggEAPGvUDgNrev81+jWC9kGM6eQYXin3OKCNltIPW/IxDD5Rghhr
# W+vZGVUNkq9wuJna8MZiyB86FUIcnA2DByE6bdUzkXU014fa2w+46eiitRcF/+BD
# H+fMVzwUPwflaP8o66z2Ve211LWgYlkxf/tTjBnVsAjR+K75TGIQccg+l5XAA5ZU
# Ao3LkFMlnD7qPUDIZhvb0B8+6y9IaCo3V+C6mT9T4hZ1BqMVyzksudMD3Xb6rfDs
# X/DbbBBdW7hwRMJjYWV0ZtnGcVuERoQ8A2H+jHCfKATpUQR72lesXLZR3k/hqPDH
# vxZuD3ppSBMawwKH29SB2X7gjNuKbKtyl2jz8qGCAyYwggMiBgkqhkiG9w0BCQYx
# ggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcg
# UlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZI
# AWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJ
# BTEPFw0yNjA1MjQxNDUyMTdaMC8GCSqGSIb3DQEJBDEiBCDwYM66dOCSfzNoPWgf
# OwtrPvaADqo1BSYYq0eZXFcG1TANBgkqhkiG9w0BAQEFAASCAgBCQ153c8fCxilz
# ae7E0V8ecP4GxdkqIiM3jihGzAhIuK6EXtZKGPbt9e3Wn6+u8f0W3DKYcUL/Pk2E
# tDNAsnE2o1YyJApEEM+tfQCpKEPKLfyw37udVciEdcYJWZ3j/R7RIye68D8RrPE6
# oymhVmV9aJ+XxEhpY28jsy/Mm09U5LchWiSC7OZOJ1vwPdvwZ+RaXJv+hFBM/xBg
# XB+qNaxPqRxmGB20JOmnwTW6MraXOHEiXW8y07lqd159SSPZkL+xfpS4QlnOpW/8
# tClKNporcE663mbP9fZFXKkcP7DqyPi9GhgJyz45QwEu9GaQTtECHEoxOMUItCFi
# J/uTju4xHP5fXHvtMNJnIV6vFoC29AYcz79Qk/FJI6YADDE2+N7GF6RrBoPLXB4i
# b9HP8pQt6vOY8bEs6Bxyzxvic25MYKxcl1B4oPsVfnKb4zNLWVGoAyoMBicbRTTQ
# zNTEEa2+I70hKBsPxh5jhq8a4fHipi8lMkewan1gyxMZ1/aEPYdWxmvkNHmQ13T/
# kqVNOV50AzpHItjxUVd1WS4ryd/ZLpZIGMstURGu8sNw5RXO2lpjUwzVF2IyyUa7
# +/piy0pH/JGu8nU6XWBVU/XF5nbz/skYj4YB4QAeio+7VjXCioeqDOF2yuStofYU
# /6p/brDdFeRRRPiO/MKI3LimUY0Tdg==
# SIG # End signature block
