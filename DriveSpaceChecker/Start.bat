@echo off
cd D:\
cd D:\CommVault\DriveSpaceChecker

del DriveSpace.txt

ping localhost

Powershell.exe -executionpolicy remotesigned -File  DriveSpaceChecker.ps1