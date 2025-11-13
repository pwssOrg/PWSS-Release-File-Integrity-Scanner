# Version: 0.4
# Date: November 12, 2025
# Description: Downloads OpenJDK 25 zip from java.net
# Author:  © PWSS Org

### Note:
# The script uses `Invoke-WebRequest`, which requires an internet connection.
# Ensure that the download URL and paths are correct based on the OpenJDK 25 release


. .\..\verify_integrity\verify_integrity.ps1

# Define constants
$jdkVersion = "25"
$downloadUrl =
"https://download.java.net/java/GA/jdk25/bd75d5f9689641da8e1daabeccb5528b/36/GPL/openjdk-25_windows-x64_bin.zip"

$installationPath = "$HOME\Java"

# Function to download a file
function Download-File {
    param (
        [string]$url,
        [string]$outputPath
    )

    if (Test-Path $outputPath) {
        Write-Output "File already exists at $outputPath. Skipping download."
        return
    }

    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath -UseBasicParsing
        Write-Output "Downloaded: $url"

	

$expectedSha256OpenJdk25="85BCC178461E2CB3C549AB9CA9DFA73AFD54C09A175D6510D0884071867137D3"
$openjdk25FileName = "openjdk-25_windows-x64_bin.zip"

if (Verify-SHA256 -FilePath $outputPath -ExpectedHash $expectedSha256OpenJdk25) {
    Write-Host -ForegroundColor Green "The file ($openjdk25FileName) hash matches the expected SHA256."
} else {
    Write-Host -ForegroundColor Red "The file ($openjdk25FileName) hash does NOT match the expected SHA256."
    Remove-Item -Path $downloadPath -Force -Confirm:$false
    Contact-Message
    exit

}

    } catch {
        Write-Error "Failed to download file from ${url}: $_"
        exit 1
    }
}

# Function to extract a zip file
function Extract-Zip {
    param (
        [string]$zipPath,
        [string]$extractToPath
    )

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractToPath)
        Write-Output "Extracted: $zipPath to $extractToPath"
    } catch {
        Write-Error "Failed to extract zip file from ${zipPath}: $_"
        exit 1
    }
}

# Main script execution

# Create installation directory if it doesn't exist
if (-not (Test-Path -Path $installationPath)) {
    New-Item -ItemType Directory -Force -Path $installationPath
}

# Download the Open JDK zip file
$downloadZipPath = "$env:TEMP\jdk-$jdkVersion.zip"
Download-File -url $downloadUrl -outputPath $downloadZipPath

# Extract the downloaded zip to the installation directory
Extract-Zip -zipPath $downloadZipPath -extractToPath $installationPath

# Clean up downloaded file
Remove-Item -Force -Path $downloadZipPath
Write-Output "Cleanup: Removed downloaded zip file from $downloadZipPath"

# Set JAVA_HOME environment variable (user scope)
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "$installationPath\jdk-25",
[System.EnvironmentVariableTarget]::User)

# Add entry to PATH environment variable (user scope)

$newPath = "$installationPath\jdk-25\bin"
$escapedNewPath = [regex]::Escape($newPath)



# Check if the new path already exists in the PATH environment variable
if ($env:PATH -notmatch $escapedNewPath) {
    # Add the new path to the PATH environment variable for the current session
    $env:PATH += ";$newPath"

    # Write the updated PATH value to the user's environment variables (no admin rights required)
    [System.Environment]::SetEnvironmentVariable("PATH", $env:PATH, "User")
    Write-Host "New path added to PATH for current user."
} else {
    Write-Host "Path already exists in PATH."
}

Write-Output "Java installation completed successfully."
Write-Output "JDK 25 installed at: $installationPath"
