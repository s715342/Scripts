@echo off
setlocal enabledelayedexpansion
cd D:\
cd D:\Tools\FailedBackupTicketCreator

rem *********Cleans up the files created by CV console**************
ren BackupJobSummaryReport*Details.csv DetailInput.txt
ren BackupJobSummaryReport*Summary.csv SummaryInput.txt
del /f BackupJobSummaryReport*.csv

rem *******defines variables for input and output files ************
set PingOutPut=D:\Tools\FailedBackupTicketCreator\PingOutPut.txt
set OutPut=D:\Tools\FailedBackupTicketCreator\OutPut.txt
set DetailInput=D:\Tools\FailedBackupTicketCreator\DetailInput.txt
set DetailInput2=D:\Tools\FailedBackupTicketCreator\DetailInput2.txt
set SummaryInput=D:\Tools\FailedBackupTicketCreator\SummaryInput.txt
set CombinedInput=D:\Tools\FailedBackupTicketCreator\CombinedInput.txt
set CombinedOut=D:\Tools\FailedBackupTicketCreator\CombinedOut.txt
set CombinedOut2=D:\Tools\FailedBackupTicketCreator\CombinedOut2.txt
set OutPutEmpty=D:\Tools\FailedBackupTicketCreator\OutPutEmpty.txt

rem ****************************************************************************
rem *Writes and empty file called Output.txt************************************
rem ****************************************************************************

echo. 2> %OutPutEmpty%                

rem ****************************************************************************
rem *loops though SummaryImput for the first COMMA and writes to CombinedInput**
rem ****************************************************************************
for /f "tokens=1 delims=," %%a in ('type %SummaryInput%') do (
	echo %%a >> %CombinedInput%
)


rem ****************************************************************************
rem *loops through DetailInput for "with errors" and writes to DetailInput2*****
rem ****************************************************************************
findstr /c:"with errors" x.y %DetailInput% > %DetailInput2%
findstr /c:"Failed" x.y %DetailInput% >> %DetailInput2%

rem ************************************************************************************************************
rem *loops through DetailInput2 for the second COMMA then excludes all "N/A" before it APPENDS to CombinedInput*
rem ************************************************************************************************************
for /f "tokens=2 delims=," %%b in ('type %DetailInput2%') do (
	IF NOT "%%b" == "N/A" (echo %%b >> %CombinedInput%)
)


rem ************************************************************************************
rem *loops through CombinedInput removing duplicates and writes out to CombinedOut******
rem ************************************************************************************
call jsort %CombinedInput% /u >> %CombinedOut%


rem *****************List of names I exclude from the report********************
set @var1=Virtual Server
set @var2=Subclient
set @var3=‹¯¨Client
set @var4=Windows File System
set @var5=Linux
set @var6=All
set @var7=Protected
set @var8=Job
set @var9=Agent
set @var10=PostgreSQL

findstr /v "%@var1% %@var2% %@var3% %@var4% %@var5% %@var6% %@var7% %@var8% %@var9% %@var10%" %CombinedOut% > %CombinedOut2%

rem ********** sets the size of CombinedOut2.txt to %combinedout2size%, then if %cominedout2size% is less than 1 echo ...
for /f %%i in ("CombinedOut2.txt") do set combinedout2size=%%~zi
if %combinedout2size% lss 1 (
	echo WexHealth - No failed backups. Please manually run report. >> %OutPutEmpty%
rem	Powershell.exe Send-MailMessage -From 'alerts@wexcloudservices.com' -To 'matthew.sly@wexinc.com' -Subject 'WexHealth Failed CommVault Backups from %date:~4,2%-%date:~7,2%-%date:~10,4% - No failed backups.' -SmtpServer 'smtp.azr.wexglobal.com' -Port 25002 -Attachments "%OutPutEmpty%"
	Powershell.exe Send-MailMessage -From 'alerts@wexcloudservices.com' -To 'gl-azure-cloud-operations@wexinc.com' -Subject 'WexHealth Failed CommVault Backups from %date:~4,2%-%date:~7,2%-%date:~10,4% - No failed backups.' -SmtpServer 'smtp.azr.wexglobal.com' -Port 25002 -Attachments "%OutPutEmpty%"

)ELSE (
rem	Powershell.exe Send-MailMessage -From 'alerts@wexcloudservices.com' -To 'matthew.sly@wexinc.com' -Subject 'WexHealth Failed CommVault Backups from %date:~4,2%-%date:~7,2%-%date:~10,4%' -SmtpServer 'smtp.azr.wexglobal.com' -Port 25002 -Attachments "%CombinedOut2%"
	Powershell.exe Send-MailMessage -From 'alerts@wexcloudservices.com' -To 'gl-azure-cloud-operations@wexinc.com' -Subject 'WexHealth Failed CommVault Backups from %date:~4,2%-%date:~7,2%-%date:~10,4%' -SmtpServer 'smtp.azr.wexglobal.com' -Port 25002 -Attachments "%CombinedOut2%"
rem	Powershell.exe Send-MailMessage -From 'alerts@wexcloudservices.com' -To 'email_mailbox@commvault.wexinc.xmatters.com' -Subject 'WexHealth Failed CommVault Backups from %date:~4,2%-%date:~7,2%-%date:~10,4%' -SmtpServer 'smtp.azr.wexglobal.com' -Port 25002 -Attachments "%CombinedOut2%"

)

rem ******Added a delay ***********
ping localhost -n 5 >> %PingOutPut%

rem ***********CYA to confirm the tickets created in the above loop matches what the following email output resembles ********
for /f "tokens=1 delims=" %%c in ('type D:\Tools\FailedBackupTicketCreator\CombinedOut2.txt') do (
	rem echo %%c- WexHealth CommVault Backup Error > D:\Tools\FailedBackupTicketCreator\OutPut.txt

rem	Powershell.exe Send-MailMessage -From 'alerts@wexcloudservices.com' -To 'gl-azure-cloud-operations@wexinc.com' -Subject 'WexHealth Failed CommVault Backups from %date:~4,2%-%date:~7,2%-%date:~10,4% - %%c' -SmtpServer 'smtp.azr.wexglobal.com' -Port 25002
	Powershell.exe Send-MailMessage -From 'alerts@wexcloudservices.com' -To 'email_mailbox@commvault.wexinc.xmatters.com' -Subject 'WexHealth Failed CommVault Backups from %date:~4,2%-%date:~7,2%-%date:~10,4% - %%c' -SmtpServer 'smtp.azr.wexglobal.com' -Port 25002


	rem ******Added a 15 second delay so Cherwell handles creating tickets better ***********
	ping localhost -n 15 >> %PingOutPut%
)

rem ******cleanup*****************
del %PingOutPut%
del %OutPutEmpty%
del %OutPut%
del %DetailInput%
del %DetailInput2%
del %SummaryInput%
del %CombinedInput%
del %CombinedOut%
del %CombinedOut2%