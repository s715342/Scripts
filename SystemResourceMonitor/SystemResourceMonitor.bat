@echo off
rem -------------------------------------------------------------------------------
rem -----This was created by Matt Sly on the CSC Backup team supporting Wex
rem -----This will monitor Processes, CPU % and Available Memory
rem -----This will run every 30 minutes but can be adjusted in Scheduled Tasks.
rem -----Docs Used:  http://stackoverflow.com/questions/20208373/how-to-get-the-current-cpu-usage-and-available-memory-in-batch-file
rem -------------------------------------------------------------------------------

rem ---------------------------------------------------------------------------------------
rem ----Loop that will check for Running Processes, ProcessorTime and Available Memory-----
rem ---------------------------------------------------------------------------------------

echo %date% - %time% >> C:\temp\SystemResourceMonitor\1RunningProcesses.txt
tasklist /FI "MEMUSAGE gt 5" /FI "STATUS eq running" >> C:\temp\SystemResourceMonitor\1RunningProcesses.txt

echo %date% - %time% >> C:\temp\SystemResourceMonitor\2NotRespondingProcesses.txt
tasklist /FI "MEMUSAGE gt 5" /FI "STATUS eq not responding" >> C:\temp\SystemResourceMonitor\2NotRespondingProcesses.txt

echo %date% - %time% >> C:\temp\SystemResourceMonitor\3UnknownProcesses.txt
tasklist /FI "MEMUSAGE gt 5" /FI "STATUS eq unknown" >> C:\temp\SystemResourceMonitor\3UnknownProcesses.txt

SETLOCAL ENABLEDELAYEDEXPANSION
SET count=1
FOR /F "tokens=* USEBACKQ" %%F IN (`typeperf "\processor(_total)\%% processor time" -SC 1 -y`) DO (
  SET var!count!=%%F
  SET /a count=!count!+1
)
echo %var2% >> C:\temp\SystemResourceMonitor\4ProcessorTime.txt
ENDLOCAL
	
SETLOCAL ENABLEDELAYEDEXPANSION
SET count=1
FOR /F "tokens=* USEBACKQ" %%F IN (`typeperf "\Memory\Available MBytes" -SC 1 -y`) DO (
  SET var!count!=%%F
  SET /a count=!count!+1
)
echo %var2% >> C:\temp\SystemResourceMonitor\5AvailableMemory.txt
ENDLOCAL

SETLOCAL ENABLEDELAYEDEXPANSION
SET count=1
FOR /F "tokens=* USEBACKQ" %%F IN (`typeperf "\Network Interface(*)\Bytes Total/sec" -SC 1 -y`) DO (
  SET var!count!=%%F
  SET /a count=!count!+1
)
echo %var2% >> C:\temp\SystemResourceMonitor\6NetworkBytesPerInterface.txt
ENDLOCAL