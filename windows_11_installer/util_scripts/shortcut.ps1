# Version: 1.1
# Date: November 21, 2025
# Author:  © PWSS Org

$scriptDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)

function Create-Shortcut {

$exePath = "$scriptDirectory\..\..\file_integrity_scanner_app\windows\integrity.exe"
$shortcutPath = [Environment]::GetFolderPath("Desktop") + "\Integrity.lnk"

# Check if the executable exists
if (Test-Path $exePath) {
    # Create a WScript.Shell object
    $WshShell = New-Object -ComObject WScript.Shell

    # Create shortcut
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $exePath
    $Shortcut.IconLocation = $exePath  # Optionally set icon from the executable
    $Shortcut.Save()
    Write-Output "Shortcut created successfully at $shortcutPath"
} else {
    Write-Error "Executable not found at $exePath"
}

}