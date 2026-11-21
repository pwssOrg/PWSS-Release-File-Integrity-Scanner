# Install

./linux_amd_install

# Fixing Line Ending Issues (CRLF)

If you encounter errors such as:

```text
/bin/bash^M: bad interpreter: No such file or directory
```

this usually means that one or more shell scripts have Windows-style line endings (CRLF) instead of Linux-style line endings (LF).

Follow these steps to fix the issue before starting the installation.

### Step 1 – Convert the line endings of the fix script

```bash
dos2unix dos2_unix_fix_for_linux.sh
```

### Step 2 – Make the script executable

```bash
chmod +x dos2_unix_fix_for_linux.sh
```

### Step 3 – Execute the fix script

```bash
./dos2_unix_fix_for_linux.sh
```

The script will convert the designated installation files to Unix-style line endings (LF).

### Step 4 – Continue with the installation

Once the conversion is complete, all designated files should have the correct Linux line endings.

You are now ready to proceed with the installation\!

**Note:** Make sure `dos2unix` is installed before performing Step 1. If it is not installed, install it using:

```bash
sudo apt update
sudo apt install -y dos2unix
```
