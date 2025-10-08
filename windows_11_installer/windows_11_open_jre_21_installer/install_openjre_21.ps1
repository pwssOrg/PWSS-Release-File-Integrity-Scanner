### Instructions

# 1. Open PowerShell with administrative privileges.
# 2. Copy and paste the above script into a new file, e.g., `Install-OpenJRE.ps1`.
# 3. Run the script by executing: .\Install-OpenJRE.ps1
  

### What the Script Does:

# 1.Downloads OpenJRE 21 zip from GitHub.
# 2. Extracts it to a specified installation path (default is C:\Program Files\Java\OpenJRE-21).
# 3. Sets he JAVA_HOME environment variable for user scope.

### Note:
# The script uses `Invoke-WebRequest`, which requires an internet connection.
# Ensure that the download URL and paths are correct based on the latest OpenJRE release available at the time of use.
# The installation path ($installationPath) can be modified as needed.


# Define constants
$jreVersion = "21"
$downloadUrl =
"https://github.com/ojdkbuild/ojdkbuild/releases/download/ojdk-21.0.2+7/ojdk-21_windows-x64_bin.zip"
$installationPa"https://github.com/ojdkbuild/ojdkbuild/releases/download/ojdk-21.0.2+7/ojdk-21_windows-x64_bin.zip"$installationPath = "$env:ProgramFiles\Java\OpenJRE-$jreVersion"

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
    } catch {
        Write-Error "Failed to download file from $url: $_"
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
        Write-Error "Failed to extract zip file from $zipPath: $_"
        exit 1
    }
}

# Main script execution

# Create installation directory if it doesn't exist
if (-not (Test-Path -Path $installationPath)) {
    New-Item -ItemType Directory -Force -Path $installationPath
}

# Download the OpenJRE zip file
$downloadZipPath = "$env:TEMP\OpenJRE-$jreVersion.zip"
Download-File -url $downloadUrl -outputPath $downloadZipPath

# Extract the downloaded zip to the installation directory
Extract-Zip -zipPath $downloadZipPath -extractToPath $installationPath

# Clean up downloaded file
Remove-Item -Force -Path $downloadZipPath
Write-Output "Cleanup: Removed downloaded zip file from $downloadZipPath"

# Set JAVA_HOME environment variable (user scope)
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "$installationPath",
[System.EnvironmentVariableTarget]::User)

Write-Output "Installation completed successfully."
Write-Output "OpenJRE installed at: $installationPath"