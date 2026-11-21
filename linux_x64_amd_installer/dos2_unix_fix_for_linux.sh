#!/bin/bash

set -e

echo "[INFO] Checking dos2unix installation..."

# --- INSTALL DOS2UNIX IF NEEDED ---
if ! command -v dos2unix >/dev/null 2>&1; then
    echo "[INFO] dos2unix not found. Installing..."

    sudo apt update
    sudo apt install -y dos2unix
else
    echo "[INFO] dos2unix is already installed."
fi

# --- FILES TO CONVERT ---
FILES=(
    "linux_amd_install"
    "psql_files/postgresql.conf"
    "psql_files/psql/pass/avocado"
    "setup_enviroment/integrity_hash_enviroment"
    "../file_integrity_scanner_app/linux/start_integrity_hash"
)

# --- CONVERT FILES ---
echo "[INFO] Converting files to Unix line endings..."

for FILE in "${FILES[@]}"; do
    if [[ -f "$FILE" ]]; then
        echo "[INFO] Converting: $FILE"
        dos2unix "$FILE"
    else
        echo "[WARNING] File not found: $FILE"
    fi
done

echo "[INFO] dos2unix conversion completed."
