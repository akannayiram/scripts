@REM ######################################################
@REM   Al Kannayiram, ConEdison 1/12/2017
@REM  
@REM ######################################################
@REM   CacheClearSingleDomain.cmd 
@REM      - To clear cache of App, Prcs, and Web
@REM      - Requires 1 parameter: Properties file containing Domain details
@REM   Usage:
@REM      CacheClearSingleDomain.cmd <domain.properties>
@REM ######################################################
@REM
@Echo off
setLocal EnableDelayedExpansion
SET script=%~n0

@REM =================================
@REM Look for input parameter
@REM =================================
if "%~1"=="" (
   echo [%date% %time%] - ERROR. Missing input parameter
   echo [%date% %time%] - ERROR. Execute the script with an input parameter
   echo [%date% %time%] - ERROR. Aborting the script [%0]
   goto :eof
)
if not exist %1 (
   echo [%date% %time%] - ERROR. Input file [%1] does not exist
   echo [%date% %time%] - ERROR. Check the Command Line and pass a valid input file parameter
   echo [%date% %time%] - ERROR. Aborting the script [%0]
   goto :eof
)

@REM =================================
@REM Read properties file and Set environment variables
@REM =================================
SET propfile=%~n1
for /f "eol=; delims=" %%A in (%1) do set %%A

if not exist %LOGDIR%\NUL (
   echo [%date% %time%] - ERROR. Log directory [%LOGDIR%] does not exist
   echo [%date% %time%] - ERROR. Aborting the script [%0]
   goto :eof
)

@REM =================================
@REM Suffix Log filename with YYYY_MM_DD
@REM =================================
set LOGFILE=%LOGDIR%\%propfile%_%date:~-4,4%_%date:~4,2%_%date:~7,2%.log
set ERRFILE=%LOGDIR%\%propfile%_Error.txt
if exist %ERRFILE% del /q %ERRFILE%

echo[    >> %LOGFILE%
echo[    >> %LOGFILE%
set msg=##########################################################################
echo %msg% >> %LOGFILE%
set msg=[%date% %time%] - Begin [%0]
echo %msg% >> %LOGFILE%

@REM =================================
@REM Validate values from properties file
@REM =================================
set msg=[%date% %time%] - Validating values from properties file [%1]
echo %msg% >> %LOGFILE%
if not exist %PS_HOME%\NUL (
   set msg=[%date% %time%] - ERROR. PS_HOME [%PS_HOME%] does not exist and Aborting the script [%0]
   echo !msg! >> %LOGFILE%
   echo !msg! >> %ERRFILE%
   goto :fin
)
if not exist %PS_CFG_HOME%\NUL (
   set msg=[%date% %time%] - ERROR. PS_HOME [%PS_CFG_HOME%] does not exist and Aborting the script [%0]
   echo !msg! >> %LOGFILE%
   echo !msg! >> %ERRFILE%
   goto :fin
)
if not exist %PS_CFG_HOME%\appserv\%APPDOM%\NUL (
   set msg=[%date% %time%] - ERROR. App Server [%APPDOM%] does not exist and Aborting the script [%0]
   echo !msg! >> %LOGFILE%
   echo !msg! >> %ERRFILE%
   goto :fin
)
if not exist %PS_CFG_HOME%\appserv\prcs\%PRCSDOM%\NUL (
   set msg=[%date% %time%] - ERROR. Process Scheduler [%PRCSDOM%] does not exist and Aborting the script [%0]
   echo !msg! >> %LOGFILE%
   echo !msg! >> %ERRFILE%
   goto :fin
)
if not exist %PS_CFG_HOME%\webserv\%PIADOM%\NUL (
   set msg=[%date% %time%] - ERROR. PIA Domain [%PIADOM%] does not exist and Aborting the script [%0]
   echo !msg! >> %LOGFILE%
   echo !msg! >> %ERRFILE%
   goto :fin
)
if not exist %PS_CFG_HOME%\webserv\%PIADOM%\applications\peoplesoft\PORTAL.war\%PIASITE%\NUL (
   set msg=[%date% %time%] - ERROR. PIA Site [%PIADOM% - %PIASITE%] does not exist and Aborting the script [%0]
   echo !msg! >> %LOGFILE%
   echo !msg! >> %ERRFILE%
   goto :fin
)
sc query state= all|findstr /C:"SERVICE_NAME: %PS_SERVICE%"
if [%ERRORLEVEL%] NEQ [0] (
   set msg=[%date% %time%] - ERROR. App/Prcs Service [%PS_SERVICE%] does not exist and Aborting the script [%0]
   echo !msg! >> %LOGFILE%
   echo !msg! >> %ERRFILE%
   goto :fin
)
sc query state= all|findstr /C:"SERVICE_NAME: %PIA_SERVICE%"
if [%ERRORLEVEL%] NEQ [0] (
   set msg=[%date% %time%] - ERROR. PIA Service [%PIA_SERVICE%] does not exist and Aborting the script [%0]
   echo !msg! >> %LOGFILE%
   echo !msg! >> %ERRFILE%
   goto :fin
)
set msg=[%date% %time%] - Successful Validation of values from Properties file [%1]
echo %msg% >> %LOGFILE%

@REM =================================
@REM Stop PeopleSoft App/Prcs Service
@REM =================================
set msg=[%date% %time%] - Stopping App/Prcs Service [%PS_SERVICE%]
echo %msg% >> %LOGFILE%
set /a counter=1
:PSServiceStopLoop
for /f "tokens=4" %%i in ('sc query "%PS_SERVICE%"^|findstr STATE') do set sts=%%i
set msg=[%date% %time%] - [%PS_SERVICE%] Service Status (Loop !counter!): %sts%
echo %msg% >> %LOGFILE%
if "%sts%" == "STOPPED" (
   set msg=[%date% %time%] - Stopped App/Prcs Service [%PS_SERVICE%]
   echo !msg! >> %LOGFILE%
   goto :PIAServiceStop
)
if "%sts%" == "RUNNING" (
   net stop "%PS_SERVICE%"
@REM Wait for 2 minutes after stopping PS service
   set msg=[%date% %time%] - Waiting for 2 minutes after stopping PS service [%PS_SERVICE%]
   echo !msg! >> %LOGFILE%
   timeout /t 120 /nobreak
)
set /a counter=!counter!+1
if %counter% geq 10 goto :PSServiceStopWarn
timeout /t 15 /nobreak
goto :PSServiceStopLoop
:PSServiceStopWarn
set msg=[%date% %time%] - WARNING. [%PS_SERVICE%] Service didn't come down yet. Please check. 
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Stop PIA Service
@REM =================================
:PIAServiceStop
set msg=[%date% %time%] - Stopping PIA Service [%PIA_SERVICE%]
echo %msg% >> %LOGFILE%
set /a counter=1
:PIAServiceStopLoop
for /f "tokens=4" %%i in ('sc query "%PIA_SERVICE%"^|findstr STATE') do set sts=%%i
set msg=[%date% %time%] - [%PIA_SERVICE%] Service Status (Loop !counter!): %sts%
echo %msg% >> %LOGFILE%
if "%sts%" == "STOPPED" (
   set msg=[%date% %time%] - Stopped PIA Service [%PIA_SERVICE%]
   echo !msg! >> %LOGFILE%
   goto :AppPrcsClean
)
if "%sts%" == "RUNNING" (
   net stop "%PIA_SERVICE%"
@REM Wait for 10 seconds after stopping PIA service
   set msg=[%date% %time%] - Waiting for 10 seconds after stopping PIA service [%PIA_SERVICE%]
   echo !msg! >> %LOGFILE%
   timeout /t 10 /nobreak
)   
set /a counter=!counter!+1
if %counter% geq 3 goto :PIAServiceStopWarn
timeout /t 10 /nobreak
goto :PIAServiceStopLoop
:PIAServiceStopWarn
set msg=[%date% %time%] - WARNING. [%PIA_SERVICE%] Service didn't come down yet. Please check. 
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Clean IPC and Clear Cache
@REM =================================
:AppPrcsClean
set msg=[%date% %time%] - Starting Clean IPC and Clear Cache
echo %msg% >> %LOGFILE%
cd /d %PS_HOME%\appserv
@REM App - Force shutdown and then Clean IPC
psadmin -c shutdown! -d %APPDOM%
psadmin -c cleanipc  -d %APPDOM%
@REM Prcs - Kill and then Clean IPC
psadmin -p kill      -d %PRCSDOM%
psadmin -p cleanipc  -d %PRCSDOM%
@REM Delete App CACHE
if exist %PS_CFG_HOME%\appserv\%APPDOM%\CACHE (
   rd /s /q %PS_CFG_HOME%\appserv\%APPDOM%\CACHE
   mkdir    %PS_CFG_HOME%\appserv\%APPDOM%\CACHE
)
@REM Delete Prcs Cache
if exist %PS_CFG_HOME%\appserv\prcs\%PRCSDOM%\CACHE (
   rd /s /q %PS_CFG_HOME%\appserv\prcs\%PRCSDOM%\CACHE
   mkdir    %PS_CFG_HOME%\appserv\prcs\%PRCSDOM%\CACHE
)
set msg=[%date% %time%] - Completed - Clean IPC and Clear Cache
echo %msg% >> %LOGFILE%

@REM =================================
@REM PIA Cache Clean
@REM =================================
set msg=[%date% %time%] - Starting PIA Cache Clean
echo %msg% >> %LOGFILE%
@REM if psftcache folder exists, delete its contents
if exist %PS_CFG_HOME%\webserv\%PIADOM%\applications\peoplesoft\PORTAL.war\psftcache (
   rd /s /q %PS_CFG_HOME%\webserv\%PIADOM%\applications\peoplesoft\PORTAL.war\psftcache
   mkdir    %PS_CFG_HOME%\webserv\%PIADOM%\applications\peoplesoft\PORTAL.war\psftcache
)
if exist %PS_CFG_HOME%\webserv\%PIADOM%\applications\peoplesoft\PORTAL.war\%PIASITE%\cache (
   rd /s /q %PS_CFG_HOME%\webserv\%PIADOM%\applications\peoplesoft\PORTAL.war\%PIASITE%\cache
   mkdir    %PS_CFG_HOME%\webserv\%PIADOM%\applications\peoplesoft\PORTAL.war\%PIASITE%\cache
)
set msg=[%date% %time%] - Completed - PIA Cache Clean
echo %msg% >> %LOGFILE%

@REM =================================
@REM Start App/Prcs Service
@REM =================================
set msg=[%date% %time%] - Starting App/Prcs Service [%PS_SERVICE%]
echo %msg% >> %LOGFILE%
net start "%PS_SERVICE%"
@REM Wait for 2 minutes after starting PS service
set msg=[%date% %time%] - Waiting for 2 minutes after starting PS service [%PS_SERVICE%]
echo !msg! >> %LOGFILE%
timeout /t 120 /nobreak
set /a counter=1
:PSServiceStartLoop
for /f "tokens=4" %%i in ('sc query "%PS_SERVICE%"^|findstr STATE') do set sts=%%i
set msg=[%date% %time%] - [%PS_SERVICE%] Service Status (Loop !counter!): %sts%
echo %msg% >> %LOGFILE%
if "%sts%" == "RUNNING" (
   set msg=[%date% %time%] - Started App/Prcs Service [%PS_SERVICE%]
   echo !msg! >> %LOGFILE%
   goto :PIAServiceStart
)
set /a counter=!counter!+1
if %counter% geq 10 goto :PSServiceStartWarn
timeout /t 15 /nobreak
goto :PSServiceStartLoop
:PSServiceStartWarn
set msg=[%date% %time%] - WARNING. [%PS_SERVICE%] Service didn't come up yet. Please check. 
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Start PIA Service
@REM =================================
:PIAServiceStart
set msg=[%date% %time%] - Starting PIA Service [%PIA_SERVICE%]
echo %msg% >> %LOGFILE%
net start "%PIA_SERVICE%"
@REM Wait for 10 seconds after starting PIA service
set msg=[%date% %time%] - Waiting for 10 seconds after starting PIA service [%PIA_SERVICE%]
echo %msg% >> %LOGFILE%
timeout /t 10 /nobreak
set /a counter=1
:PIAServiceStartLoop
for /f "tokens=4" %%i in ('sc query "%PIA_SERVICE%"^|findstr STATE') do set sts=%%i
set msg=[%date% %time%] - [%PIA_SERVICE%] Service Status (Loop !counter!): %sts%
echo %msg% >> %LOGFILE%
if "%sts%" == "RUNNING" (
   set msg=[%date% %time%] - Started PIA Service [%PIA_SERVICE%]
   echo !msg! >> %LOGFILE%
   goto :JoltPortCheck
)
set /a counter=!counter!+1
if %counter% geq 10 goto :PIAServiceStartWarn
timeout /t 10 /nobreak
goto :PIAServiceStartLoop
:PIAServiceStartWarn
set msg=[%date% %time%] - WARNING. [%PIA_SERVICE%] Service didn't come up yet. Please check. 
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Check if JOLT port is alive
@REM =================================
:JoltPortCheck
set msg=[%date% %time%] - Checking JOLT port [%JOLTPORT%]
echo %msg% >> %LOGFILE%
set /a counter=1
:JoltPortLoop
netstat -an|find "LISTENING"|find "  TCP"|find ":%JOLTPORT%"
if [%ERRORLEVEL%] EQU [0] (
   set msg=[%date% %time%] - Successful. JOLT Port [%JOLTPORT%] is Active.
   echo !msg! >> %LOGFILE%   
   goto :PIAPortCheck
)
set /a counter=!counter!+1
if %counter% geq 10 goto :JoltPortWarn
timeout /t 10 /nobreak
goto :JoltPortLoop
:JoltPortWarn
set msg=[%date% %time%] - WARNING. App Server [%APPDOM%] JOLT Port [%JOLTPORT%] is not active. Please check.
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Check if PIA port is alive
@REM =================================
:PIAPortCheck
set msg=[%date% %time%] - Checking PIA port [%PIAPORT%]
echo %msg% >> %LOGFILE%
set /a counter=1
:PIAPortLoop
netstat -an|find "LISTENING"|find "  TCP"|find ":%PIAPORT%"
if [%ERRORLEVEL%] EQU [0] (
   set msg=[%date% %time%] - Successful. PIA Port [%PIAPORT%] is Active.
   echo !msg! >> %LOGFILE%   
   goto :AppPrcsStauses
)
set /a counter=!counter!+1
if %counter% geq 5 goto :PIAPortWarn
timeout /t 10 /nobreak
goto :PIAPortLoop
:PIAPortWarn
set msg=[%date% %time%] - WARNING. PIA Server [%PIADOM% - %PIASITE%] Port [%PIAPORT%] is not active. Please check.
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Dump App/Prcs statuses using psadmin
@REM =================================
:AppPrcsStauses
set msg=[%date% %time%] - Dumping App/Prcs statuses using psadmin
echo %msg% >> %LOGFILE%
cd /d %PS_HOME%\appserv
@REM App Domain
psadmin -c sstatus  -d %APPDOM% >> %LOGFILE% 2>&1
@REM Prcs Domain
psadmin -p sstatus  -d %PRCSDOM% >> %LOGFILE% 2>&1

@REM =================================
@REM PIA status
@REM =================================
set msg=[%date% %time%] - PIA status
echo %msg% >> %LOGFILE%
cd /d %PS_CFG_HOME%\webserv\%PIADOM%\bin
call singleserverStatus.cmd >> %LOGFILE% 2>&1

:fin
set msg=[%date% %time%] - Finished [%0]
echo %msg% >> %LOGFILE%
set msg=##########################################################################
echo %msg% >> %LOGFILE%
