@REM ######################################################
@REM   Al Kannayiram, ConEdison 1/12/2017
@REM ######################################################
@REM   - To clear cache of App, Prcs, and Web Domains of RCT92DEV
@REM   Usage:
@REM      RCT92DEVClearCache.cmd 
@REM ######################################################
@REM
@Echo off
setLocal EnableDelayedExpansion 
@REM =================================
@REM Begin - Domain specific environmental variables
@REM =================================
set PS_APP_HOME=D:\PeopleSoft\RCTDEV\RCTDEV_APPHOME
set PS_CFG_HOME=D:\PeopleSoft\RCTDEV\RCTDEV_CFGHOME
set PS_HOME=D:\PeopleSoft\RCTDEV\RCTDEV_PSHOME
set PS_CUST_HOME=D:\PeopleSoft\RCTDEV\RCTDEV_CUSTHOME
@REM =================================
@REM Windows Services
@REM =================================
PS_SERVICE=PeopleSoft_D__PeopleSoft_RCTDEV_RCTDEV_CFGHOME
PIA_SERVICE=RCTDEV-PIA
PIA_SERVICE_EXT=RCTDEVEXT-PIA
@REM =================================
@REM WebLogic: Domains and Sites
@REM =================================
APPDOM=RCTDEV
APPDOM_EXT=RCTDEVEXT
PRCSDOM=RCTDEV
PIADOM=RCTDEV
PIASITE=RCTDEV
PIADOM_EXT=RCTDEVEXT
PIASITE_EXT=RCTDEVEXT
@REM =================================
@REM JOLT and PIA Ports
@REM =================================
JOLTPORT=9320
JOLTPORT_EXT=9380
PIAPORT=8320
PIAPORT_EXT=8330
@REM =================================
@REM End - Domain specific environmental variables
@REM =================================

SET script=%~n0
@REM =================================
@REM Suffix Log filename with YYYY_MM_DD
@REM =================================
LOGDIR=C:\PS
if not exist %LOGDIR%\NUL (
   echo [%date% %time%] - ERROR. Log directory [%LOGDIR%] does not exist
   echo [%date% %time%] - ERROR. Aborting the script [%0]
   goto :eof
)
set LOGFILE=%LOGDIR%\%script%_%date:~-4,4%_%date:~4,2%_%date:~7,2%.log
set ERRFILE=%LOGDIR%\%script%_Error.txt
if exist %ERRFILE% del /q %ERRFILE%

echo[    >> %LOGFILE%
echo[    >> %LOGFILE%
set msg=##########################################################################
echo %msg% >> %LOGFILE%
set msg=[%date% %time%] - Begin [%0]
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
   goto :PIA1ServiceStop
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
@REM Stop PIA Service#1
@REM =================================
:PIA1ServiceStop
set msg=[%date% %time%] - Stopping PIA Service [%PIA_SERVICE%]
echo %msg% >> %LOGFILE%
set /a counter=1
:PIA1ServiceStopLoop
for /f "tokens=4" %%i in ('sc query "%PIA_SERVICE%"^|findstr STATE') do set sts=%%i
set msg=[%date% %time%] - [%PIA_SERVICE%] Service Status (Loop !counter!): %sts%
echo %msg% >> %LOGFILE%
if "%sts%" == "STOPPED" (
   set msg=[%date% %time%] - Stopped PIA Service [%PIA_SERVICE%]
   echo !msg! >> %LOGFILE%
   goto :PIA2ServiceStop
)
if "%sts%" == "RUNNING" (
   net stop "%PIA_SERVICE%"
@REM Wait for 10 seconds after stopping PIA service
   set msg=[%date% %time%] - Waiting for 10 seconds after stopping PIA service [%PIA_SERVICE%]
   echo !msg! >> %LOGFILE%
   timeout /t 10 /nobreak
)   
set /a counter=!counter!+1
if %counter% geq 3 goto :PIA1ServiceStopWarn
timeout /t 10 /nobreak
goto :PIA1ServiceStopLoop
:PIA1ServiceStopWarn
set msg=[%date% %time%] - WARNING. [%PIA_SERVICE%] Service didn't come down yet. Please check. 
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Stop PIA Service#2
@REM =================================
:PIA2ServiceStop
set msg=[%date% %time%] - Stopping PIA Service [%PIA_SERVICE_EXT%]
echo %msg% >> %LOGFILE%
set /a counter=1
:PIA2ServiceStopLoop
for /f "tokens=4" %%i in ('sc query "%PIA_SERVICE_EXT%"^|findstr STATE') do set sts=%%i
set msg=[%date% %time%] - [%PIA_SERVICE_EXT%] Service Status (Loop !counter!): %sts%
echo %msg% >> %LOGFILE%
if "%sts%" == "STOPPED" (
   set msg=[%date% %time%] - Stopped PIA Service [%PIA_SERVICE_EXT%]
   echo !msg! >> %LOGFILE%
   goto :AppDomainClearCache
)
if "%sts%" == "RUNNING" (
   net stop "%PIA_SERVICE_EXT%"
@REM Wait for 10 seconds after stopping PIA service
   set msg=[%date% %time%] - Waiting for 10 seconds after stopping PIA service [%PIA_SERVICE_EXT%]
   echo !msg! >> %LOGFILE%
   timeout /t 10 /nobreak
)   
set /a counter=!counter!+1
if %counter% geq 3 goto :PIA2ServiceStopWarn
timeout /t 10 /nobreak
goto :PIA2ServiceStopLoop
:PIA2ServiceStopWarn
set msg=[%date% %time%] - WARNING. [%PIA_SERVICE_EXT%] Service didn't come down yet. Please check. 
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM App Domain(s): Force Shutdown and Clean IPC
@REM =================================
:AppDomainClearCache
set msg=[%date% %time%] - Starting Clean IPC and Clear Cache
echo %msg% >> %LOGFILE%
cd /d %PS_HOME%\appserv
@REM App Server Domain#1
psadmin -c shutdown! -d %APPDOM%
psadmin -c cleanipc  -d %APPDOM%
@REM App Server Domain#2
psadmin -c shutdown! -d %APPDOM_EXT%
psadmin -c cleanipc  -d %APPDOM_EXT%

@REM =================================
@REM Prcs Domain(s): Kill and then Clean IPC
@REM =================================
psadmin -p kill      -d %PRCSDOM%
psadmin -p cleanipc  -d %PRCSDOM%

set msg=[%date% %time%] - Completed - Clean IPC of App and Prcs Domains
echo %msg% >> %LOGFILE%

@REM =================================
@REM App Domain(s): Clear Cache
@REM =================================
if exist %PS_CFG_HOME%\appserv\%APPDOM%\CACHE (
   rd /s /q %PS_CFG_HOME%\appserv\%APPDOM%\CACHE
   mkdir    %PS_CFG_HOME%\appserv\%APPDOM%\CACHE
)
if exist %PS_CFG_HOME%\appserv\%APPDOM_EXT%\CACHE (
   rd /s /q %PS_CFG_HOME%\appserv\%APPDOM_EXT%\CACHE
   mkdir    %PS_CFG_HOME%\appserv\%APPDOM_EXT%\CACHE
)

@REM =================================
@REM Prcs Domain(s): Clear Cache
@REM =================================
if exist %PS_CFG_HOME%\appserv\prcs\%PRCSDOM%\CACHE (
   rd /s /q %PS_CFG_HOME%\appserv\prcs\%PRCSDOM%\CACHE
   mkdir    %PS_CFG_HOME%\appserv\prcs\%PRCSDOM%\CACHE
)
set msg=[%date% %time%] - Completed - Clear Cache of App and Prcs Domains
echo %msg% >> %LOGFILE%

@REM =================================
@REM PIA Domains: Clear Cache
@REM =================================
set msg=[%date% %time%] - Starting PIA Clear Cache
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
@REM if psftcache folder exists, delete its contents
if exist %PS_CFG_HOME%\webserv\%PIADOM_EXT%\applications\peoplesoft\PORTAL.war\psftcache (
   rd /s /q %PS_CFG_HOME%\webserv\%PIADOM_EXT%\applications\peoplesoft\PORTAL.war\psftcache
   mkdir    %PS_CFG_HOME%\webserv\%PIADOM_EXT%\applications\peoplesoft\PORTAL.war\psftcache
)
if exist %PS_CFG_HOME%\webserv\%PIADOM_EXT%\applications\peoplesoft\PORTAL.war\%PIASITE_EXT%\cache (
   rd /s /q %PS_CFG_HOME%\webserv\%PIADOM_EXT%\applications\peoplesoft\PORTAL.war\%PIASITE_EXT%\cache
   mkdir    %PS_CFG_HOME%\webserv\%PIADOM_EXT%\applications\peoplesoft\PORTAL.war\%PIASITE_EXT%\cache
)
set msg=[%date% %time%] - Completed - PIA Clear Cache
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
   goto :PIA1ServiceStart
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
@REM Start PIA Service#1
@REM =================================
:PIA1ServiceStart
set msg=[%date% %time%] - Starting PIA Service [%PIA_SERVICE%]
echo %msg% >> %LOGFILE%
net start "%PIA_SERVICE%"
@REM Wait for 10 seconds after starting PIA service
set msg=[%date% %time%] - Waiting for 10 seconds after starting PIA service [%PIA_SERVICE%]
echo %msg% >> %LOGFILE%
timeout /t 10 /nobreak
set /a counter=1
:PIA1ServiceStartLoop
for /f "tokens=4" %%i in ('sc query "%PIA_SERVICE%"^|findstr STATE') do set sts=%%i
set msg=[%date% %time%] - [%PIA_SERVICE%] Service Status (Loop !counter!): %sts%
echo %msg% >> %LOGFILE%
if "%sts%" == "RUNNING" (
   set msg=[%date% %time%] - Started PIA Service [%PIA_SERVICE%]
   echo !msg! >> %LOGFILE%
   goto :PIA2ServiceStart
)
set /a counter=!counter!+1
if %counter% geq 10 goto :PIA1ServiceStartWarn
timeout /t 10 /nobreak
goto :PIA1ServiceStartLoop
:PIA1ServiceStartWarn
set msg=[%date% %time%] - WARNING. [%PIA_SERVICE%] Service didn't come up yet. Please check. 
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Start PIA Service#2
@REM =================================
:PIA2ServiceStart
set msg=[%date% %time%] - Starting PIA Service [%PIA_SERVICE_EXT%]
echo %msg% >> %LOGFILE%
net start "%PIA_SERVICE_EXT%"
@REM Wait for 10 seconds after starting PIA service
set msg=[%date% %time%] - Waiting for 10 seconds after starting PIA service [%PIA_SERVICE_EXT%]
echo %msg% >> %LOGFILE%
timeout /t 10 /nobreak
set /a counter=1
:PIA2ServiceStartLoop
for /f "tokens=4" %%i in ('sc query "%PIA_SERVICE_EXT%"^|findstr STATE') do set sts=%%i
set msg=[%date% %time%] - [%PIA_SERVICE_EXT%] Service Status (Loop !counter!): %sts%
echo %msg% >> %LOGFILE%
if "%sts%" == "RUNNING" (
   set msg=[%date% %time%] - Started PIA Service [%PIA_SERVICE_EXT%]
   echo !msg! >> %LOGFILE%
   goto :JoltPort1Check
)
set /a counter=!counter!+1
if %counter% geq 10 goto :PIA2ServiceStartWarn
timeout /t 10 /nobreak
goto :PIA2ServiceStartLoop
:PIA2ServiceStartWarn
set msg=[%date% %time%] - WARNING. [%PIA_SERVICE_EXT%] Service didn't come up yet. Please check. 
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Check if JOLT port#1 is alive
@REM =================================
:JoltPort1Check
set msg=[%date% %time%] - Checking if JOLT port [%JOLTPORT%] is alive
echo %msg% >> %LOGFILE%
set /a counter=1
:JoltPort1Loop
netstat -an|find "LISTENING"|find "  TCP"|find ":%JOLTPORT%"
if [%ERRORLEVEL%] EQU [0] (
   set msg=[%date% %time%] - Successful. JOLT Port [%JOLTPORT%] is Active.
   echo !msg! >> %LOGFILE%   
   goto :JoltPort2Check
)
set /a counter=!counter!+1
if %counter% geq 10 goto :JoltPort1Warn
timeout /t 10 /nobreak
goto :JoltPort1Loop
:JoltPort1Warn
set msg=[%date% %time%] - WARNING. App Server [%APPDOM%] JOLT Port [%JOLTPORT%] is not active. Please check.
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Check if JOLT port#2 is alive
@REM =================================
:JoltPort2Check
set msg=[%date% %time%] - Checking if JOLT port [%JOLTPORT_EXT%] is alive
echo %msg% >> %LOGFILE%
set /a counter=1
:JoltPort2Loop
netstat -an|find "LISTENING"|find "  TCP"|find ":%JOLTPORT_EXT%"
if [%ERRORLEVEL%] EQU [0] (
   set msg=[%date% %time%] - Successful. JOLT Port [%JOLTPORT_EXT%] is Active.
   echo !msg! >> %LOGFILE%   
   goto :PIAPort1Check
)
set /a counter=!counter!+1
if %counter% geq 10 goto :JoltPort2Warn
timeout /t 10 /nobreak
goto :JoltPort2Loop
:JoltPort2Warn
set msg=[%date% %time%] - WARNING. App Server [%APPDOM_EXT%] JOLT Port [%JOLTPORT_EXT%] is not active. Please check.
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Check if PIA port#1 is alive
@REM =================================
:PIAPort1Check
set msg=[%date% %time%] - Checking if PIA port [%PIAPORT%] is alive
echo %msg% >> %LOGFILE%
set /a counter=1
:PIAPort1Loop
netstat -an|find "LISTENING"|find "  TCP"|find ":%PIAPORT%"
if [%ERRORLEVEL%] EQU [0] (
   set msg=[%date% %time%] - Successful. PIA Port [%PIAPORT%] is Active.
   echo !msg! >> %LOGFILE%   
   goto :PIAPort2Check
)
set /a counter=!counter!+1
if %counter% geq 5 goto :PIAPort1Warn
timeout /t 10 /nobreak
goto :PIAPort1Loop
:PIAPort1Warn
set msg=[%date% %time%] - WARNING. PIA Domain [%PIADOM%] Port [%PIAPORT%] is not active. Please check.
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Check if PIA port#2 is alive
@REM =================================
:PIAPort2Check
set msg=[%date% %time%] - Checking if PIA port [%PIAPORT_EXT%] is alive
echo %msg% >> %LOGFILE%
set /a counter=1
:PIAPort2Loop
netstat -an|find "LISTENING"|find "  TCP"|find ":%PIAPORT_EXT%"
if [%ERRORLEVEL%] EQU [0] (
   set msg=[%date% %time%] - Successful. PIA Port [%PIAPORT_EXT%] is Active.
   echo !msg! >> %LOGFILE%   
   goto :AppPrcsStauses
)
set /a counter=!counter!+1
if %counter% geq 5 goto :PIAPort2Warn
timeout /t 10 /nobreak
goto :PIAPort2Loop
:PIAPort2Warn
set msg=[%date% %time%] - WARNING. PIA Domain [%PIADOM_EXT%] Port [%PIAPORT_EXT%] is not active. Please check.
echo %msg% >> %LOGFILE%
echo %msg% >> %ERRFILE%

@REM =================================
@REM Dump App/Prcs statuses using psadmin
@REM =================================
:AppPrcsStauses
set msg=[%date% %time%] - Dumping App/Prcs statuses using psadmin
echo %msg% >> %LOGFILE%
cd /d %PS_HOME%\appserv
@REM App Domains
psadmin -c sstatus  -d %APPDOM% >> %LOGFILE% 2>&1
psadmin -c sstatus  -d %APPDOM_EXT% >> %LOGFILE% 2>&1
@REM Prcs Domain
psadmin -p sstatus  -d %PRCSDOM% >> %LOGFILE% 2>&1

@REM =================================
@REM PIA statuses
@REM =================================
set msg=[%date% %time%] - PIA status
echo %msg% >> %LOGFILE%
cd /d %PS_CFG_HOME%\webserv\%PIADOM%\bin
call singleserverStatus.cmd >> %LOGFILE% 2>&1
cd /d %PS_CFG_HOME%\webserv\%PIADOM_EXT%\bin
call singleserverStatus.cmd >> %LOGFILE% 2>&1

:fin
set msg=[%date% %time%] - Finished [%0]
echo %msg% >> %LOGFILE%
set msg=##########################################################################
echo %msg% >> %LOGFILE%
