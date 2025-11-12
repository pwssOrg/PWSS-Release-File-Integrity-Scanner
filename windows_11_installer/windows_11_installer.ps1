# Version: 0.3
# Date: November 12, 2025
# Description: 
# 1. Ask the User if the need to install OpenJDK 25
# 2. Downloading and extracting the PostgreSQL installer.
# 3. Initializing the database cluster.
# 4. Starting the PostgreSQL service on a specified port.
# 5. Creating a new user with their password and granting all privileges.
# Author:  © PWSS Org



# Ask the user if they need to install OPEN JDK 25
$installOpenJDK = Read-Host "Do you need to install OpenJDK 25? ( JDK or JRE >= 21 is needed for File-Integrity-Scanner to work (Y/N)"

if ($installOpenJDK -eq 'Y') {
    # Define path to the installation script
    $installScriptPath = "windows_11_open_jdk_25_installer\install_open_jdk_25.ps1"

    if (Test-Path $installScriptPath) {
        Write-Output "Starting Open JDK 25 installation..."
        & powershell -NoProfile -ExecutionPolicy Bypass -File $installScriptPath
        Write-Output "Open JDK 25 installation completed."
    } else {
        Write-Error "Installation script not found at $installScriptPath"
    }
} else {
    Write-Output "Skipping Open JDK 25 installation."
}

# Continue with the rest of your main script
Write-Output "Continuing with the main install script..."


# Define variables for the installation
$pgVersion = "17.6"
$installerUrl = "https://sbp.enterprisedb.com/getfile.jsp?fileid=1259681"
$downloadPath = "$env:TEMP\postgresql-$pgVersion-latest-windows-x64-binaries.zip"
$psqlTempPath = "$env:TEMP\PostgreSQL"
$psqlFinalPath = "$env:ProgramFiles\PostgreSQL"
$psqlBinPath = "C:\Program Files\PostgreSQL\$pgVersion\pgsql\bin"


# Function to download and extract installer
function Install-PostgreSQL {
    param (
        [string]$username,
        [string]$password,
        [int]$port
    )

    # Download the PostgreSQL zip file from official website
    Invoke-WebRequest -Uri $installerUrl -OutFile $downloadPath

    # Unzip the downloaded file to ProgramFiles\PostgreSQL
    Expand-Archive -LiteralPath $downloadPath -DestinationPath "$psqlTempPath\$pgVersion"

    # Define destination of psql folder relative
    $sourcePsqlFolder = "psql_files\psql"

    # Define destination paths based on environment variables and provided values
    $destinationDataFolder = "$psqlTempPath\$pgVersion\pgsql\data"

    # Define the destination path for the psql folder on C: drive
    $destinationPsqlFolder = "C:\psql"

    # Copy the entire psql folder to the root of C: drive, overwrite if it exists
    Copy-Item -Path $sourcePsqlFolder -Destination $destinationPsqlFolder -Recurse -Force

    Write-Host "psql folder copied successfully."

    # Define destination of bin path (temporary before move)
    $destinationBinPathTemp = "$psqlTempPath\$pgVersion\pgsql\bin"

    # Define destination of bin path (final, after move to program files)
    $destinationBinPath = "$psqlFinalPath\$pgVersion\pgsql\bin"

    # Initialize the database cluster with custom data directory and port
    & "$destinationBinPathTemp\initdb.exe" -D $destinationDataFolder -U $username

    # Define the source paths for the file and folder
    $sourceConfFile = "psql_files\postgresql.conf"
    $sourcePsqlFolder = "psql_files\psql"

    # Ensure the destination folder for the configuration file exists
    if (-not (Test-Path -Path $destinationDataFolder)) {
        New-Item -ItemType Directory -Force -Path $destinationDataFolder
    }

    # Copy the postgresql.conf file and overwrite if it exists
    Copy-Item -Path $sourceConfFile -Destination "$destinationDataFolder\postgresql.conf" -Force

    Write-Host "postgresql.conf copied successfully."

    # Move temp location of PostgreSQL to Program files
    Copy-Item -Path $psqlTempPath -Destination $psqlFinalPath -Recurse -Force

    # Start the PostgreSQL service on custom port
    & "$destinationBinPath\pg_ctl.exe" start -D $destinationDataFolder -l "$destinationDataFolder\logfile.txt" -o "-p $port"

    # Create database for file integrity hash
    & "$destinationBinPath\psql.exe" -p $port -U $username -d postgres -c "CREATE DATABASE integrity_hash;"

    # Grant all privileges to the newly created user on database
    & "$destinationBinPath\psql.exe" -p $port -U $username -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE integrity_hash TO $username;"

    Write-Output "PostgreSQL installed successfully!"
}

function Validate-Password {
    param (
        [Parameter(Mandatory=$true)]
        [string]$password
    )

    # Check if password is at least 8 characters long
    if ($password.Length -lt 8) {
        return $false
    }

    # Check if password contains at least one digit
    if (-not ($password -match '\d')) {
        return $false
    }

    # Check if password contains at least one special character
    if (-not ($password -match '[^a-zA-Z0-9]')) {
        return $false
    }

    return $true
}

function Remove-TempFolder {
    param (
        [string]$folderName
    )
 
    # Define the path to the folder in AppData Local Temp
    $path = Join-Path -Path $env:LOCALAPPDATA\Temp -ChildPath $folderName
 
    # Delete the folder if it exists
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force
        Write-Host "Deleted folder: $path"
    } else {
        Write-Host "Folder does not exist: $path"
    }
}

# Prompt user for input
$username = Read-Host -Prompt "Enter PostgreSQL username"


$securePassword = ""
while ($true) {
    $plainPassword = Read-Host -AsSecureString -Prompt "Enter PostgreSQL password"
    # Convert secure string to plain text for validation
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($plainPassword)
    $plainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

    if (Validate-Password -password $plainTextPassword) {
        # Use the original secure string for further processing
        $securePassword = ConvertTo-SecureString $plainTextPassword -AsPlainText -Force
        break
    } else {
        Write-Host "Password must be at least 8 characters long, contain at least one digit, and include a special
character."
    }
}
Write-Host "Valid password provided!"


$port = Read-Host -Prompt "Enter PostgreSQL port (default for File-Integrity Scanner is 26556). Dont change this unless instructued to do so by PWSS officials"

# Persist emviroment variables across sessions
[System.Environment]::SetEnvironmentVariable("TRUSTSTORE_FIS_GUI", "truststore_placeholder", 
[System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable("ssl_file_integrity_scanner", "ssl_placeholder", 
[System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable("INTEGRITY_HASH_DB_PASSWORD", "$plainTextPassword", 
[System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable("INTEGRITY_HASH_DB_USER", "$username", 
[System.EnvironmentVariableTarget]::User)

if ([string]::IsNullOrEmpty($port)) {
    $port = 26556
}

# Install PostgreSQL with the user input
Install-PostgreSQL -username $username -password $plainTextPassword -port $port

# Send SQL commands to create tables (must be run after database initialization)
. .\tables\insert_tables.ps1
insert-tables -psqlBinPath "$psqlBinPath\psql.exe"


# Change the user's password using psql command
& "$psqlBinPath\psql.exe" -p $port -U $username -c "ALTER USER $username WITH PASSWORD $plainTextPassword;"
Write-Host "Password for user $username changed successfully."

# Cleanup temp folder
Remove-TempFolder -folderName "PostgreSQL"
Remove-TempFolder -folderName "postgresql-$pgVersion-latest-windows-x64-binaries.zip"

Write-Output "Postgres started on port $port and the temporary installation files are cleaned up"

# Before running this script:
# 1. Make sure PowerShell is running as an administrator.
# 2. You may need to install any required dependencies or make additional adjustments based on your environment and
# needs.
