# Author:  © PWSS Org
# Date: November 12, 2025
# Version: 1.1


function insert-tables {
    param (

	[Parameter(Mandatory=$true)]
        [string]$psqlBinPath,
	
	[Parameter(Mandatory=$true)]
        [string]$dbUser,

        [Parameter(Mandatory=$true)]
        [string]$password

    )

$dbName = "integrity_hash"


# SQL script to create tables
$createTablesSql = @"
CREATE TABLE "time"(
id BIGSERIAL PRIMARY KEY,
created TIMESTAMPTZ NOT NULL,
updated TIMESTAMPTZ NOT NULL
);
CREATE TABLE note (
id BIGSERIAL PRIMARY KEY,
notes TEXT,
prev_notes TEXT,
prev_prev_notes TEXT,
time_id bigint NOT NULL REFERENCES "time"(id)
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
    time_id bigint NOT NULL REFERENCES "time"(id),
    last_scanned TIMESTAMPTZ,
    note_id bigint NOT NULL REFERENCES note(id),
    baseline_established BOOLEAN NOT NULL DEFAULT FALSE,
    include_subdirectories BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE scan (
    id SERIAL PRIMARY KEY,
    scan_time_id bigint NOT NULL REFERENCES "time"(id),
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
time_id bigint NOT NULL REFERENCES "time"(id)
);
CREATE TABLE auth(
id SERIAL PRIMARY KEY,
hash TEXT NOT NULL,
auth_time bigint REFERENCES "time"(id) NOT NULL
);
CREATE TABLE "user_"(
id SERIAL PRIMARY KEY,
username TEXT UNIQUE NOT NULL,
auth_id int REFERENCES auth(id) NOT NULL,
user_time bigint REFERENCES "time"(id) NOT NULL
);
CREATE TABLE license(
id INT PRIMARY KEY,
license_data TEXT);
INSERT INTO license (id,license_data) VALUES
(1,'331cd7b3ce491feda6e855dcbf5de4dec5d5211e7776c8e7da4a91026ddab7b7'),
(2,'71b16c484b415c32e6139f95d7276ea351228fbef0af5f7dcbd8bff0484b59b5');
"@

# Write the SQL script to a temporary file
$tempFilePath = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tempFilePath -Value $createTablesSql

try {
    # Create environment variables with PGPASSWORD set for psql command
    $envVars = @{
        "PGPASSWORD" = $password
    }

    # Create the command string
    $commandArgs = " -U $dbUser -d $dbName -f $tempFilePath -p 26556"

    Start-Process -NoNewWindow -FilePath $psqlBinPath `
        -ArgumentList $commandArgs `
        -Environment $envVars `
        -Wait

} finally {
    # Clean up the temporary file
    Remove-Item -Path $tempFilePath
}

# Clear PGPASSWORD environment variable after the command execution is done
$env:PGPASSWORD = ""

}