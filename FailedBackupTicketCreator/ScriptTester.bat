@echo off
setlocal enabledelayedexpansion
cd D:\
cd D:\Tools\FailedBackupTicketCreator

del D:\Tools\FailedBackupTicketCreator\OutPut.txt
del D:\Tools\FailedBackupTicketCreator\PingOutPut.txt
del D:\Tools\FailedBackupTicketCreator\OutPutCombinedEmpty.txt
del D:\Tools\FailedBackupTicketCreator\Junk.txt
del D:\Tools\FailedBackupTicketCreator\OutPutEmpty.txt
del D:\Tools\FailedBackupTicketCreator\DetailInput.txt
del D:\Tools\FailedBackupTicketCreator\DetailInputDB3.txt
del D:\Tools\FailedBackupTicketCreator\DetailInput2.txt
del D:\Tools\FailedBackupTicketCreator\DetailInputDB1.txt
del D:\Tools\FailedBackupTicketCreator\DetailInputDB2.txt
del D:\Tools\FailedBackupTicketCreator\DetailInputFILE1.txt
del D:\Tools\FailedBackupTicketCreator\DetailInputFILE2.txt

del D:\Tools\FailedBackupTicketCreator\DetailInputFILE3.txt
del D:\Tools\FailedBackupTicketCreator\DetailInputFILE4.txt
del D:\Tools\FailedBackupTicketCreator\DetailInput4.txt
del D:\Tools\FailedBackupTicketCreator\SummaryInput.txt
del D:\Tools\FailedBackupTicketCreator\SummaryInput2.txt
del D:\Tools\FailedBackupTicketCreator\DetailInput3.txt
del D:\Tools\FailedBackupTicketCreator\TicketsToBeCreated.txt
del D:\Tools\FailedBackupTicketCreator\OutPutWEX.txt
del D:\Tools\FailedBackupTicketCreator\OutPutAOC.txt
del D:\Tools\FailedBackupTicketCreator\DetailOut.txt
del D:\Tools\FailedBackupTicketCreator\DetailOut2.txt
del D:\Tools\FailedBackupTicketCreator\DetailOut3.tx
del D:\Tools\FailedBackupTicketCreator\CombinedInput.txt
del D:\Tools\FailedBackupTicketCreator\CombinedInput2.txt
del D:\Tools\FailedBackupTicketCreator\CombinedOut.txt
del D:\Tools\FailedBackupTicketCreator\CombinedOut2.txt
del D:\Tools\FailedBackupTicketCreator\CombinedOut3.txt
del D:\Tools\FailedBackupTicketCreator\test.txt
del D:\Tools\FailedBackupTicketCreator\CombinedOutAOC.txt
del D:\Tools\FailedBackupTicketCreator\CombinedOutWEX.txt
del D:\Tools\FailedBackupTicketCreator\OutPutWEXEmpty.txt
del D:\Tools\FailedBackupTicketCreator\OutPutAOCEmpty.txt

copy C:\Users\x-msly\Desktop\BackupJobSummaryReport*.csv D:\Tools\FailedBackupTicketCreator
copy C:\Users\x-msly\Desktop\BackupJobSummaryReport*Summary.csv D:\Tools\FailedBackupTicketCreator
copy C:\Users\x-msly\Desktop\BackupJobSummaryReport*Details.csv D:\Tools\FailedBackupTicketCreator