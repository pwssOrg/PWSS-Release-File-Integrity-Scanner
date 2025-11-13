# Version: 0.4
# Date: November 13, 2025
# Description: 
# 1. Ask the User if the need to install OpenJDK 25
# 2. Downloading and extracting the PostgreSQL installer.
# 3. Initializing the database cluster.
# 4. Starting the PostgreSQL service on a specified port.
# 5. Creating a new user with their password and granting all privileges.
# Author:  © PWSS Org


$hashVerifyIntegrity = (Get-FileHash -Algorithm "SHA256" .\..\verify_integrity\verify_integrity.ps1).Hash
if ($hashVerifyIntegrity -eq "FEF0BEE337EA4658699F62C69BF536DCBF22415F9688F0E11B6A4F3DC1110BD1") {

    Write-Host -ForegroundColor Green "The file (verify_integrity.ps1) hash matches the expected SHA256."

}

else {
    Write-Host -ForegroundColor Red "The file (verify_integrity.ps1) hash does NOT match the expected SHA256."
    exit
}


. .\..\verify_integrity\verify_integrity.ps1

$installOpenJdk25Script = ".\windows_11_open_jdk_25_installer\install_open_jdk_25.ps1"
$expectedSha256InstallOpenJdk25Script = "87B083078DE111990C944605AA07A739504E9EBF2303E7ACE5FF1CAC97EBEB47"

if (Verify-SHA256 -FilePath $installOpenJdk25Script -ExpectedHash $expectedSha256InstallOpenJdk25Script) {
    Write-Host -ForegroundColor Green "The file (install_open_jdk_25.ps1) hash matches the expected SHA256."
}
else {
    Write-Host -ForegroundColor Red "The file (install_open_jdk_25.ps1) hash does NOT match the expected SHA256."
    Contact-Message
    exit
}

$insertTablesScript = ".\tables\insert_tables.ps1"
$expectedSha256InsertTablesScript = "9EB2483447C54D30F3201C40BF3FFC2D125779DFD88D8EF3043472BBB165ED3A"

if (Verify-SHA256 -FilePath $insertTablesScript -ExpectedHash $expectedSha256InsertTablesScript) {
    Write-Host -ForegroundColor Green "The file (insert_tables.ps1) hash matches the expected SHA256."
}
else {
    Write-Host -ForegroundColor Red "The file (insert_tables.ps1) hash does NOT match the expected SHA256."
    Contact-Message
    exit
}



# Ask the user if they need to install OPEN JDK 25
$installOpenJDK = Read-Host "Do you need to install OpenJDK 25? ( JDK or JRE >= 21 is needed for File-Integrity-Scanner to work (Y/N)"

if ($installOpenJDK -eq 'Y') {
    # Define path to the installation script
    $installScriptPath = "windows_11_open_jdk_25_installer\install_open_jdk_25.ps1"

    if (Test-Path $installScriptPath) {
        Write-Output "Starting Open JDK 25 installation..."
        & powershell -NoProfile -ExecutionPolicy Bypass -File $installScriptPath
        Write-Output "Open JDK 25 installation completed."
    }
    else {
        Write-Error "Installation script not found at $installScriptPath"
    }
}
else {
    Write-Output "Skipping Open JDK 25 installation."
}

# Continue with the rest of your main script
Write-Output "Continuing with the main install script..."


# Define variables for the installation
$pgVersion = "17.6"
$installerUrl = "https://sbp.enterprisedb.com/getfile.jsp?fileid=1259681"
$downloadPath = "$env:TEMP\postgresql-$pgVersion-latest-windows-x64-binaries.zip"
$psqlTempPath = "$env:TEMP\PostgreSQL"
$psqlFinalPath = "C:\Fis_PostgreSQL"
$psqlBinPath = "C:\Fis_PostgreSQL\$pgVersion\pgsql\bin"
$psqlDataPath = "C:\Fis_PostgreSQL\$pgVersion\pgsql\data"


# Function to download and extract installer
function Install-PostgreSQL {
    param (
        [string]$username,
        [int]$port
    )

    # Download the PostgreSQL zip file from official website
    Invoke-WebRequest -Uri $installerUrl -OutFile $downloadPath

    $postgresqlZipFileName = "postgresql-17.6-1-windows-x64-binaries.zip"
    $expectedSha256PostgresqlZipFile = "D378882ABD001A186735ACD6F6BA716BCA6CCD192E800412D4FD15ED25376B3E"

    if (Verify-SHA256 -FilePath $downloadPath -ExpectedHash $expectedSha256PostgresqlZipFile) {
        Write-Host -ForegroundColor Green "The file ($postgresqlZipFileName) hash matches the expected SHA256."
    }
    else {
        Write-Host -ForegroundColor Red "The file ($postgresqlZipFileName) hash does NOT match the expected SHA256."
        Remove-Item -Path $downloadPath -Force -Confirm:$false
        Contact-Message
        exit
    }

    # Unzip the downloaded file to ProgramFiles\PostgreSQL
    Expand-Archive -LiteralPath $downloadPath -DestinationPath "$psqlTempPath\$pgVersion"

    # Move temp location of PostgreSQL to Program files
    Copy-Item -Path $psqlTempPath -Destination $psqlFinalPath -Recurse -Force

    # Define destination of psql folder relative
    $sourcePsqlFolder = "psql_files\psql"

    # Define the destination path for the psql folder on C: drive
    $destinationPsqlFolder = "C:\psql"

    # Copy the entire psql folder to the root of C: drive, overwrite if it exists
    Copy-Item -Path $sourcePsqlFolder -Destination $destinationPsqlFolder -Recurse -Force

    Write-Host "psql folder copied successfully."

    # Initialize the database cluster with custom data directory and port
    & "$psqlBinPath\initdb.exe" -D $psqlDataPath -U $username

    # Define the source paths for the file and folder
    $sourceConfFile = "psql_files\postgresql.conf"
    $sourcePsqlFolder = "psql_files\psql"

    # Ensure the destination folder for the configuration file exists
    if (-not (Test-Path -Path $psqlDataPath)) {
        New-Item -ItemType Directory -Force -Path $psqlDataPath
    }

    # Copy the postgresql.conf file and overwrite if it exists
    Copy-Item -Path $sourceConfFile -Destination "$psqlDataPath\postgresql.conf" -Force

    Write-Host "postgresql.conf copied successfully."

    # Start the PostgreSQL service on custom port
    & "$psqlBinPath\pg_ctl.exe" start `
        -D "`"$psqlDataPath`"" `
        -l "`"$psqlDataPath\logfile.txt`"" `
        -o "-p $port" `
        -w

    # Create database for file integrity hash
    & "$psqlBinPath\psql.exe" -p $port -U $username -d postgres -c "CREATE DATABASE integrity_hash;"

    # Grant all privileges to the newly created user on database
    & "$psqlBinPath\psql.exe" -p $port -U $username -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE integrity_hash TO $username;"

    Write-Output "PostgreSQL installed successfully!"
}

function Validate-Password {
    param (
        [Parameter(Mandatory = $true)]
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
    }
    else {
        Write-Host "Folder does not exist: $path"
    }
}

function Start-DB-If-Not-Running {
    $portInUse = netstat -ano | Select-String ":26556"

    if ($null -eq $portInUse) {
        Write-Host "Nothing is running on port 26556. Starting the process..."
        # Start the PostgreSQL service on custom port
        & "$psqlBinPath\pg_ctl.exe" start `
            -D "`"$psqlDataPath`"" `
            -l "`"$psqlDataPath\logfile.txt`"" `
            -o "-p $port" `
            -w
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
    }
    else {
        Write-Host "Password must be at least 8 characters long, contain at least one digit, and include a special
character."
    }
}
Write-Host "Valid password provided!"


Write-Host -ForegroundColor DarkCyan "The PostgreSQL port for Integrity Hash database is 26556. If you need to change this, contact PWSS officials at support@pwss.dev!"
$port = 26556


# Persist environment variables across sessions
[System.Environment]::SetEnvironmentVariable("TRUSTSTORE_FIS_GUI", "placeholder_truststore_fis_gui", 
    [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable("ssl_file_integrity_scanner", "placeholder_ssl_fis", 
    [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable("INTEGRITY_HASH_DB_PASSWORD", "$plainTextPassword", 
    [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable("INTEGRITY_HASH_DB_USER", "$username", 
    [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable("FIS_PSQL", "$psqlBinPath\pg_ctl.exe", 
    [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable("FIS_DATA", $psqlDataPath, 
    [System.EnvironmentVariableTarget]::User)


# Install PostgreSQL with the user input
Install-PostgreSQL -username $username -port $port

# Change the user's password using psql command
$escapedPassword = $plainTextPassword -replace "'", "''"
$sql = "ALTER USER $username WITH PASSWORD '$escapedPassword';"
& "$psqlBinPath\psql.exe" -p $port -U $username -d postgres -c $sql
Write-Host "Password for user $username changed successfully."

Start-DB-If-Not-Running

# Send SQL commands to create tables (must be run after database initialization)

. .\tables\insert_tables.ps1
insert-tables -psqlBinPath "$psqlBinPath\psql.exe" -dbUser $username -password $escapedPassword

# Cleanup temp folder
Remove-TempFolder -folderName "PostgreSQL"
Remove-TempFolder -folderName "postgresql-$pgVersion-latest-windows-x64-binaries.zip"

Write-Output "Postgres started on port $port and the temporary installation files are cleaned up"

# Before running this script:
# 1. Make sure PowerShell is running as an administrator.
# 2. You may need to install any required dependencies or make additional adjustments based on your environment and
# needs.