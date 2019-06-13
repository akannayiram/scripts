setlocal enabledelayedexpansion
set msg=test
if not exist C:\PS\NUL (
set msg=[Thu 01/19/2017 12:21:28.92] - ERROR. PS_HOME [C:\PS] does not exist and Aborting the script [ClearCachePSDomains.cmd]
 echo !msg!  1>>C:\PS\HR92DEVdomain_2017_01_19.log
 echo !msg!  1>>C:\PS\HR92DEVdomain_Error.txt
 goto :fin
)