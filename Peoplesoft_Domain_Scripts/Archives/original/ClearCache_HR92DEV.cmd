::New script to clear cache using invalidate 8_7_13 For use only in DEV
:M.Simon update to remove PIA Cache clear 6/19/14

@echo off
set ServerName=HR92DEV
setLocal EnableDelayedExpansion
set PS_CFG_HOME=D:\peoplesoft\%Servername%
Title=ApplicationServer %ServerName%- Clear Cache

::Set environment parameters
FOR /F "TOKENS=1,2 DELIMS=/ " %%A IN ('DATE /T') DO SET mm=%%B
FOR /F "TOKENS=2,3 DELIMS=/ " %%A IN ('DATE /T') DO SET dd=%%B

set Pdate=%mm%%dd%
set PS_HOME=D:\peoplesoft\%ServerName%
set AppCache=D:\PeopleSoft\%ServerName%\appserv\%ServerName%\CACHE
set PrcsCache=D:\PeopleSoft\%ServerName%\appserv\prcs\%ServerName%\CACHE\CACHE
set PIACache=D:\PeopleSoft\%ServerName%\webserv\peoplesoft\applications\peoplesoft\PORTAL.war\%ServerName%\cache
set log1=D:\utils\logs\%ServerName%_AppSrvCC_%pdate%.txt
set log2=D:\utils\logs\%ServerName%_PRCSCC_%pdate%.txt
set log3=D:\utils\logs\%ServerName%_PIACC_%pdate%.txt
set CCount=D:\temp\cachecount.txt
set PIAH=D:\PeopleSoft\%ServerName%\webserv\peoplesoft\bin


echo ****************%Date%****************** >> %log1%

:AppCache
@cd /d %PS_HOME%\appserv
@psadmin -c purge -d %servername% -noarch -log %log1%
echo -Cache Successfully Cleared- %date% %time% >> %log1%
echo. >> %log1%
echo. >> %log1%
Goto Count


:Count
echo. >> %log1%
@psadmin -c qstatus -d %ServerName% >> %log1%
echo. >> %log1%
echo ****************End %Date%*************** >> %log1%
echo. >> %log1%
echo. >> %log1%
goto PRCSCLR



:PRCSCLR
Title=Process Scheduler %ServerName%- Clear Cache
echo ****************%Date%*************** >> %log2%
@psadmin -p stop -d %ServerName%
IF /i [%ERRORLEVEL%]==[0] (
echo -Process Scheduler for %ServerName% Shutdown- %date% %time% >> %log2%
)ELSE (
echo -PRCS Scheduler already shut down- %date% %time% >> %log2%
)
@psadmin -p cleanipc -d %ServerName%
IF /i [%ERRORLEVEL%]==[0] (
echo -IPC successfully cleared %ServerName%- %date% %time% >> %log2%
)ELSE (
echo -Error Clearing IPC on Domain %ServerName%- %date% %time% >> %log2%
)

IF Exist %PrcsCache%\psa* (
   goto ClearPRCSCache
)ELSE (
echo No Appsrv cache folders found >> %log2%
goto PRCSSCHLR
)

pause 

:ClearPRCSCache
RD /s/q %PrcsCache%
::del /q %PrcsCache%\*.*
MKDIR %PrcsCache%

if not exist %PrcsCache%\psa* (
echo -Cache Successfully Cleared- %date% %time% >> %log2%
    goto PRCSSCHLR
)Else (
Goto ClearPRCSCache
echo -Cache clear failed %date% %time% >> %log2%
)

:PRCSSCHLR
IF /i [%attempt%]==[1] (
Echo -Problem booting %ServerName% >> %log2%
goto PIACLR
)
set attempt=1
set PS_CFG_HOME=D:\peoplesoft\HR92DEV
@psadmin -p start -d %ServerName%
 
If not exist %PrcsCache%\PSMONITORSRV* (
Echo -Problem booting %ServerName% >> %log2%
echo. >> %log2%
echo ****************End %Date%*************** >> %log2%
echo. >> %log2%
goto PIACLR
)Else (
echo -PRCS Scheduler Started- %date% %time% >> %log2%
@psadmin -p sstatus -d %servername% >> %log2%
echo ****************End %Date%*************** >> %log2%
echo. >> %log2%
echo. >> %log2%
)


:PIACLR
echo ****************%Date%*************** >> %log3%
Title=PIA %ServerName%- Clear Cache
@cd /d %PS_HOME%\appserv
REM @psadmin -w shutdown! -d peoplesoft
net stop peoplesoft-PIA (HR92DEV)
echo -PIA %ServerName% Stopped- %date% %time%  >> %log3%

IF Exist %PIACache% (
   goto ClearPIACache
)ELSE (
echo -No PIA cache folders found- %date% %time%  >> %log3%
REM @psadmin -w start -d peoplesoft
net start peoplesoft-PIA (HR92DEV)
)

:ClearPIACache
cd %PIACache%
del /q %PIACache%\*.*
echo -PIA cache cleared- %date% %time%  >> %log3%
goto StartPIA

:STARTPIA
Echo -Starting PIA- %date% %time% >> %log3%
@cd /d %PS_HOME%\appserv
rem cd %PIAH%
Title=PIA %ServerName%
rem start STARTPIA.cmd %ServerName% PIA Start
REM @psadmin -w start -d peoplesoft
net start peoplesoft-PIA (HR92DEV)
echo PIA STATUS %date% %time% >> %log3%
@psadmin -w status -d peoplesoft >> %log3%
echo ********************END******************** >> %log3%
echo. >> %log3%
echo. >> %log3%



