# Author: PWSS ORG
# Created: 2025-11-11
# Version: 1

& "$destinationBinPath\pg_ctl.exe" start -D $destinationDataFolder -l "$destinationDataFolder\logfile.txt" -o "-p 26556"