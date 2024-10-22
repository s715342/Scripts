@echo off
setlocal enabledelayedexpansion
cd D:\
cd D:\CommVault\FailedBackupTicketCreator

set PingOutPut=D:\CommVault\FailedBackupTicketCreator\PingOutPut.txt

@echo %time% >> %PingOutPut%
ping localhost -n 65
@echo %time% >> %PingOutPut%
pause

del D:\CommVault\FailedBackupTicketCreator\PingOutPut.txt