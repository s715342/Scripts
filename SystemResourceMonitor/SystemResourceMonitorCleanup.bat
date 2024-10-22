@echo off
rem -------------------------------------------------------------------------------
rem -----This was created by Matt Sly on the CSC Backup team supporting Wex
rem -----This will monitor Processes, CPU % and Available Memory
rem -----This will run every 30 minutes but can be adjusted in Scheduled Tasks.
rem -----Docs Used:  http://stackoverflow.com/questions/20208373/how-to-get-the-current-cpu-usage-and-available-memory-in-batch-file
rem -------------------------------------------------------------------------------

rem ------------------------------------------------------------------
rem ----Pre scripts to be run before the main script.  This will------
rem ----clean up any left over files from a previously run script.----
rem ------------------------------------------------------------------

del C:\temp\SystemResourceMonitor\1RunningProcesses.txt
del C:\temp\SystemResourceMonitor\2NotRespondingProcesses.txt
del C:\temp\SystemResourceMonitor\3UnknownProcesses.txt
del C:\temp\SystemResourceMonitor\4ProcessorTime.txt
del C:\temp\SystemResourceMonitor\5AvailableMemory.txt
del C:\temp\SystemResourceMonitor\6NetworkBytesPerInterface.txt