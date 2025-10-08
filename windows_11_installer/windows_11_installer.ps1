# This script accomplishes:
# 1. Ask the User if the need to install OpenJDK 25
# 2. Downloading and extracting the PostgreSQL installer.
# 3. Initializing the database cluster.
# 4. Starting the PostgreSQL service on a specified port.
# 5. Creating a new user with their password and granting all privileges.

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
$extractPath = "$env:ProgramFiles\PostgreSQL"

# Define your custom table creation SQL commands
$createTablesSql = @"
CREATE TABLE IF NOT EXISTS "time"(
id BIGSERIAL PRIMARY KEY,
created TIMESTAMPTZ NOT NULL,
updated TIMESTAMPTZ NOT NULL
);
CREATE TABLE note (
id BIGSERIAL PRIMARY KEY,
notes TEXT,
prev_notes TEXT,
prev_prev_notes TEXT,
time_id bigint NOT NULL REFERENCES time(id));
CREATE TABLE file (
    id BIGSERIAL PRIMARY KEY,
    path TEXT NOT NULL UNIQUE,
    basename TEXT NOT NULL,
    directory TEXT NOT NULL,
    size bigint NOT NULL,
    mtime TIMESTAMPTZ NOT NULL
);
CREATE TABLE file (
    id BIGSERIAL PRIMARY KEY,
    path TEXT NOT NULL UNIQUE,
    basename TEXT NOT NULL,
    directory TEXT NOT NULL,
    size bigint NOT NULL,
    mtime TIMESTAMPTZ NOT NULL
);
CREATE TABLE checksum (
    id BIGSERIAL PRIMARY KEY,
    file_id bigint NOT NULL REFERENCES file(id),
    checksum_sha256 TEXT NOT NULL,
    checksum_sha3 TEXT NOT NULL,
    checksum_blake_2b TEXT NOT NULL
);
CREATE TABLE monitored_directory (
    id SERIAL PRIMARY KEY,
    path TEXT NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    time_id bigint NOT NULL REFERENCES time(id),
    last_scanned TIMESTAMPTZ,
    note_id bigint NOT NULL REFERENCES note(id),
    baseline_established BOOLEAN NOT NULL DEFAULT FALSE,
    include_subdirectories BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE scan (
    id SERIAL PRIMARY KEY,
    scan_time_id bigint NOT NULL REFERENCES time(id),
    status TEXT NOT NULL,
    note_id bigint NOT NULL REFERENCES note(id),
    monitored_directory_id INTEGER NOT NULL REFERENCES monitored_directory(id),
    is_baseline_scan BOOLEAN NOT NULL
);
CREATE TABLE scan_summary (
    id BIGSERIAL PRIMARY KEY,
    scan_id INTEGER NOT NULL REFERENCES scan(id),
    file_id bigint NOT NULL REFERENCES file(id),
    checksum_id bigint NOT NULL REFERENCES checksum(id)
);
CREATE TABLE diff (
id BIGSERIAL PRIMARY KEY,
baseline_id bigint NOT NULL REFERENCES scan_summary(id),
integrity_fail_id bigint NOT NULL REFERENCES scan_summary(id),
time_id bigint NOT NULL REFERENCES time(id)
);
CREATE TABLE IF NOT EXISTS auth(
id SERIAL PRIMARY KEY,
hash TEXT NOT NULL,
auth_time bigint REFERENCES "time"(id) NOT NULL
);
CREATE TABLE IF NOT EXISTS "user_"(
id SERIAL PRIMARY KEY,
username TEXT UNIQUE NOT NULL,
auth_id int REFERENCES auth(id) NOT NULL,
user_time bigint REFERENCES "time"(id) NOT NULL
);
"@

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
    Expand-Archive -LiteralPath $downloadPath -DestinationPath "$extractPath\$pgVersion"

    # Change directory to PostgreSQL binaries path
    cd "$extractPath\$pgVersion\bin"

    # Initialize the database cluster with custom data directory and port
    .\initdb.exe -D "C:\postgresql\$pgVersion\data" -U $username

    # Start the PostgreSQL service on custom port
    .\pg_ctl.exe run -D "C:\postgresql\$pgVersion\data" -l "C:\postgresql\$pgVersion\server.log" -w -p $port

    # Create a new user and set password
    .\psql.exe -U postgres -c "CREATE USER $username WITH PASSWORD '$password';"

    # Grant all privileges to the newly created user on database
    .\psql.exe -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE postgres TO $username;"

    Write-Output "PostgreSQL installed successfully!"
}

# Prompt user for input
$username = Read-Host -Prompt "Enter PostgreSQL username"
$password = Read-Host -AsSecureString -Prompt "Enter PostgreSQL password"
$port = Read-Host -Prompt "Enter PostgreSQL port (default for File-Integrity Scanner is 15400). Dont change this unless instructued to do so by PWSS officials"

if ([string]::IsNullOrEmpty($port)) {
    $port = 15400
}

# Install PostgreSQL with the user input
Install-PostgreSQL -username $username -password $password -port $port

# Send SQL commands to create tables (must be run after database initialization)
.\psql.exe -U $username -d postgres -a -f $createTablesSql


# Before running this script:
# 1. Make sure PowerShell is running as an administrator.
# 2. You may need to install any required dependencies or make additional adjustments based on your environment and
# needs.