outputPath = "C:\temp\cleanupoutput.txt"

# Clear previous output
if (Test-Path $outputPath) {
    Clear-Content $outputPath
}

Function DSC_Cleanup {
    "-----DSC_Cleanup-----------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
    # Define the target folder
    $folderPath = "C:\Windows\System32\Configuration\ConfigurationStatus"

    # Check if the folder exists
    if (Test-Path -Path $folderPath) {
        # Get all files in the folder
        $files = Get-ChildItem -Path $folderPath -File -Recurse
        $DSCfileCount = $files.Count
        $DSCfolderSizeBeforeBytes = ($files | Measure-Object -Property Length -Sum).Sum
        $DSCfolderSizeBeforeMB = [math]::Round($DSCfolderSizeBeforeBytes / 1MB, 2)

        # Log before cleanup
        "[$($env:COMPUTERNAME)] File count before DSC_Cleanup: $DSCfileCount" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
        "[$($env:COMPUTERNAME)] Folder size before DSC_Cleanup: $DSCfolderSizeBeforeMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

        # Delete the files
        try {
            $files | Remove-Item -Force -ErrorAction Stop
        } catch {
            "[$($env:COMPUTERNAME)] Error deleting files: $_" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
        }

        # Recalculate after cleanup
        $DSCfilesAfter = Get-ChildItem -Path $folderPath -File -Recurse
        $DSCfileCountAfter = $DSCfilesAfter.Count
        $DSCfolderSizeAfterBytes = ($DSCfilesAfter | Measure-Object -Property Length -Sum).Sum
        $DSCfolderSizeAfterMB = [math]::Round($DSCfolderSizeAfterBytes / 1MB, 2)

        # Calculate space reclaimed
        $global:DSCspaceFreedMB = [math]::Round($DSCfolderSizeBeforeMB - $DSCfolderSizeAfterMB, 2)

        # Log after cleanup
        "[$($env:COMPUTERNAME)] File count after DSC_Cleanup: $DSCfileCountAfter" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
        "[$($env:COMPUTERNAME)] Folder size after DSC_Cleanup: $DSCfolderSizeAfterMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
        "*[$($env:COMPUTERNAME)] Space reclaimed by DSC_Cleanup: $DSCspaceFreedMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
        "-----DSC_Cleanup-----------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
    }
}
Function MemoryDmp_Cleanup {
    "-----MemoryDmp_Cleanup-----------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
    $dumpFile = "C:\Windows\Memory.dmp"

    if (Test-Path $dumpFile) {
        $dumpSizeBytes = (Get-Item $dumpFile).Length
        $dumpSizeMB = [math]::Round($dumpSizeBytes / 1MB, 2)

        "[$($env:COMPUTERNAME)] Memory.dmp file exists: $dumpSizeMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

        try {
            Remove-Item $dumpFile -Force -ErrorAction Stop
            "[$($env:COMPUTERNAME)] Memory.dmp deleted successfully." | Out-File -FilePath $outputPath -Encoding UTF8 -Append
            $global:MemoryDmpFreedMB = $dumpSizeMB
        } catch {
            "[$($env:COMPUTERNAME)] Failed to delete Memory.dmp: $_" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
            $global:MemoryDmpFreedMB = 0
        }
    } else {
        "[$($env:COMPUTERNAME)] No Memory.dmp file found." | Out-File -FilePath $outputPath -Encoding UTF8 -Append
        $global:MemoryDmpFreedMB = 0
    }

    "-----MemoryDmp_Cleanup-----------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
}
Function Empty_RecycleBin {
    "-----Empty_RecycleBin------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
    "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

    # Create Shell COM object to access Recycle Bin
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(10)
    $RecycletotalSize = 0

    # Calculate used space in Recycle Bin before cleanup
    foreach ($item in $recycleBin.Items()) {
        $RecycletotalSize += $item.ExtendedProperty("Size")
    }

    $RecycleSizeBeforeMB = [math]::Round($RecycletotalSize / 1MB, 2)
    "[$($env:COMPUTERNAME)] Used capacity in the Recycle Bin before cleanup: $RecycleSizeBeforeMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

    # Perform Recycle Bin cleanup
    Clear-RecycleBin -Force

    # Wait a moment to allow system to update
    Start-Sleep -Seconds 3

    # Calculate used space in Recycle Bin after cleanup
    $RecycletotalSize = 0
    foreach ($item in $recycleBin.Items()) {
        $RecycletotalSize += $item.ExtendedProperty("Size")
    }

    $RecycleSizeAfterMB = [math]::Round($RecycletotalSize / 1MB, 2)
    $global:RecycledSpaceFreedMB = [math]::Round($RecycleSizeBeforeMB - $RecycleSizeAfterMB, 2)


    "[$($env:COMPUTERNAME)] Used capacity in the Recycle Bin after cleanup: $RecycleSizeAfterMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
    "*[$($env:COMPUTERNAME)] Space reclaimed from Recycle Bin: $RecycledSpaceFreedMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

    "-----Empty_RecycleBin------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
}

Function Send_NotificationEmail {
    $totalFreedMB = $RecycledSpaceFreedMB + $DSCspaceFreedMB + $MemoryDmpFreedMB
    "[$($env:COMPUTERNAME)] Total space reclaimed: $totalFreedMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append


    # Read cleanup output
    $cleanupOutput = Get-Content -Path "C:\temp\cleanupoutput.txt" -Raw

    $EmailBody = @"
This job runs from:  [$($env:COMPUTERNAME)]

$cleanupOutput
"@

    $EmailSplat = @{
        From       = "noreply@wexglobal.com"
        To         = @("matthew.sly@wexinc.com")
        Subject    = "C Drive Cleanup Checker $(Get-Date -Format 'MM-dd-yyyy') - [$($env:COMPUTERNAME)]"
        Body       = $EmailBody
        SmtpServer = "smtp.azr.wexglobal.com"
        Port       = 25002
        Attachments= "C:\temp\cleanupoutput.txt"
    }

    Send-MailMessage @EmailSplat
}

DSC_Cleanup
MemoryDmp_Cleanup
Empty_RecycleBin
Send_NotificationEmail