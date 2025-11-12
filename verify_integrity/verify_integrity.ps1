# Version: 1
# Date: November 12, 2025
# Author:  © PWSS Org

$contactPWSSOrg="Contact support@pwss.dev for support!"

function Verify-SHA256 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [string]$ExpectedHash
    )

    $ExpectedHash =$ExpectedHash.ToLower()

    # Calculate the SHA256 hash of the file
    $sha256 = New-Object System.Security.Cryptography.SHA256CryptoServiceProvider
    $fileStream = [System.IO.File]::OpenRead($FilePath)
    $hashBytes = $sha256.ComputeHash($fileStream)
    $fileStream.Close()

    # Convert the hash to a hexadecimal string
    $calculatedHash = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()

    # Compare the calculated hash with the expected hash
    return $calculatedHash -eq $ExpectedHash
}


function Contact-Message {
Write-Host -ForegroundColor DarkCyan $contactPWSSOrg
}