@echo off

REM Define paths to the PowerShell scripts
set SCRIPT1=.\windows_11_installer.ps1
set SCRIPT2=.\windows_11_open_jdk_25_installer\install_open_jdk_25.ps1
set SCRIPT3=.\..\verify_integrity\verify_integrity.ps1
set SCRIPT4=.\util_scripts\shortcut.ps1

REM Unblock PowerShell scripts
powershell -Command "Unblock-File -Path '%SCRIPT1%'"
powershell -Command "Unblock-File -Path '%SCRIPT2%'"
powershell -Command "Unblock-File -Path '%SCRIPT3%'"
powershell -Command "Unblock-File -Path '%SCRIPT4%'"

REM Run Install on Windows 11 PowerShell scripts
powershell -ExecutionPolicy Bypass -File "%SCRIPT1%"

echo Script executed successfully.
pause