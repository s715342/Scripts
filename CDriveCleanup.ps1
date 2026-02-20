Function Initialization {
    Write-Host "Initialization"
    $script:outputPath = "C:\GTS-Automation\CDriveCleanup\CDriveCleanupOutput.txt"
    $script:TranscriptPath = "C:\GTS-Automation\CDriveCleanup\CleanupTranscript_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
    # Ensure C:\temp exists
    if (-not (Test-Path "C:\temp")) {
        New-Item -Path "C:\temp" -ItemType Directory -Force
    }
      
    $now = Get-Date
    
    # If file does not exist, create it and proceed
    if (-not (Test-Path "C:\GTS-Automation\CDriveCleanup\CDriveCleanupOutput.txt")) {
        New-Item -Path "C:\GTS-Automation\CDriveCleanup\CDriveCleanupOutput.txt" -ItemType File -Force | Out-Null
        
        #Start Tanscription
        Start-Transcript -Path $TranscriptPath -Append
    }
    else {
        # File exists, check last write time
         $lastWrite = (Get-Item "C:\GTS-Automation\CDriveCleanup\CDriveCleanupOutput.txt").LastWriteTime

        # If last write is newer than 24 hours, exit
        if (($lastWrite -gt $now.AddHours(-24))) {
            #Start Tanscription
            Start-Transcript -Path $TranscriptPath -Append

            Add-Content -Path "C:\GTS-Automation\CDriveCleanup\CDriveCleanupOutput.txt" -Value "`n--------------"
            Add-Content -Path "C:\GTS-Automation\CDriveCleanup\CDriveCleanupOutput.txt" -Value "`nOutput file was updated within the last 24 hours. Exiting script."
            Add-Content -Path "C:\GTS-Automation\CDriveCleanup\CDriveCleanupOutput.txt" -Value "`n-------------- $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
            Write-Output "-----CDriveCleanupOutput is newer than 24 hours, exiting on line 30."
            Send_NotificationEmail
            exit
        }
    }

    # Initialize global cleanup metrics
    $global:CTempspaceFreedMB = 0
    $global:DSCspaceFreedMB = 0
    $global:MemoryDmpFreedMB = 0
    $global:RecycledSpaceFreedMB = 0
}

Function OpenChangeTicket {
    Write-Host "CDriveCleanup-$($env:COMPUTERNAME)"
    $global:ChangeTicketVar = "CDriveCleanup-$($env:COMPUTERNAME)"

    #Creating a Standard Change in Jira by API = https://docs.google.com/document/d/1aSc_jNEsc_GkujHfYU3BZArKKGanZ9RiEjOMTWs-SBA/edit?tab=t.0
    #Jira Change Queue:  https://wexinc.atlassian.net/jira/servicedesk/projects/CHG/section/changes/custom/126
    Write-Host "OpenChangeTicket"
    $webhookUrl = "https://api-private.atlassian.com/automation/webhooks/jira/a/48af41da-3deb-4f00-a9c5-2a5c873f8b26/018b4a43-82c5-74a1-a9a3-368599f994f2"

    $headers = @{
        "Content-Type"               = "application/json"
        "X-automation-webhook-token" = "678dbd1d19476f5d6dc6195abcfb712f7c2d327f"
    }

    # Get current UTC time values
    $currentUtc      = (Get-Date).ToUniversalTime()
    $endUtcPlus5Min = (Get-Date).AddMinutes(+5).ToUniversalTime()

    # Get hostname
    $hostname = $env:COMPUTERNAME

    $body = @{
        originatesFrom            = "Grafana"
        action                    = "Create"
        requester                 = "Matt Sly"
        businessServiceLine       = "Benefits"
        standardChangeTemplate    = "Run CDriveCleanup Script"
        proposedStartDate         = $currentUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
        proposedEndDate           = $endUtcPlus5Min.ToString("yyyy-MM-ddTHH:mm:ssZ")
        externalReferenceNumber   = $ChangeTicketVar
        region                    = "NA/EMEA/Vienna/Crewe"
        ownedByTeam               = "Cloud Operations Azure"
        owner                     = "Matt Sly"
        cab                       = "Benefits"
        beginImplementation       = "TRUE"
        additionalDescriptionText = "CDriveCleanupScript - Executed from VM: $hostname"
    } | ConvertTo-Json -Depth 5


    Invoke-RestMethod `
        -Uri $webhookUrl `
        -Method Post `
        -Headers $headers `
        -Body $body

    Start-Sleep -Seconds 15
}

# Function: Write to Windows Application Event Log
Function WriteTo_ApplicationEventLog {
    Add-Content -Path $outputPath -Value "`n-------------- $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

    Write-Output "Starting cleanup..."
    Write-Host "WriteTo_ApplicationEventLog"
    "-----WriteTo_ApplicationEventLog-Start-----------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

    $logName = "Application"
    $source = "CDriveCleanup"
    $eventID = 1001
    $entryType = [System.Diagnostics.EventLogEntryType]::Information
    $message = "*CDriveCleanup* has started."

    if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
        New-EventLog -LogName $logName -Source $source
        Write-Host "Event source '$source' created. Please run the script again."
        "[$($env:COMPUTERNAME)] Event source created. Rerun required." | Out-File -FilePath $outputPath -Encoding UTF8 -Append
        "-----WriteTo_ApplicationEventLog-End-----------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
    }

    Write-EventLog -LogName $logName -Source $source -EntryType $entryType -EventId $eventID -Message $message
    "[$($env:COMPUTERNAME)] Event log entry written." | Out-File -FilePath $outputPath -Encoding UTF8 -Append
    "-----WriteTo_ApplicationEventLog-End-----------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
}

# Function: DSC Cleanup
Function DSC_Cleanup {
    Write-Host "DSC_Cleanup"
    "-----DSC_Cleanup-Start-----------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

    $folderPath = "C:\Windows\System32\Configuration\ConfigurationStatus"
    if (Test-Path -Path $folderPath) {
        $files = Get-ChildItem -Path $folderPath -File -Recurse -ErrorAction SilentlyContinue
        $DSCfileCount = $files.Count
        $DSCfolderSizeBeforeMB = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

        "[$($env:COMPUTERNAME)] Files before: $DSCfileCount | Size: $DSCfolderSizeBeforeMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

        try {
            $files | Remove-Item -Force -ErrorAction Stop
        } catch {
            "[$($env:COMPUTERNAME)] Error deleting files: $_" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
        }

        $DSCfilesAfter = Get-ChildItem -Path $folderPath -File -Recurse -ErrorAction SilentlyContinue
        $DSCfolderSizeAfterMB = [math]::Round(($DSCfilesAfter | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

        $global:DSCspaceFreedMB = [math]::Round($DSCfolderSizeBeforeMB - $DSCfolderSizeAfterMB, 2)
        "[$($env:COMPUTERNAME)] Space reclaimed: $DSCspaceFreedMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
    }

    "-----DSC_Cleanup-End-------------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
}

# Function: Clean Memory Dump
Function MemoryDmp_Cleanup {
    Write-Host "MemoryDmp_Cleanup"
    "-----MemoryDmp_Cleanup-Start-----------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

    $dumpFile = "C:\Windows\Memory.dmp"
    if (Test-Path $dumpFile) {
        $dumpSizeMB = [math]::Round((Get-Item $dumpFile).Length / 1MB, 2)
        "[$($env:COMPUTERNAME)] Memory.dmp size: $dumpSizeMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

        try {
            Remove-Item $dumpFile -Force -ErrorAction Stop
            $global:MemoryDmpFreedMB = $dumpSizeMB
            "[$($env:COMPUTERNAME)] Memory.dmp deleted." | Out-File -FilePath $outputPath -Encoding UTF8 -Append
        } catch {
            "[$($env:COMPUTERNAME)] Failed to delete Memory.dmp: $_" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
        }
    } else {
        "[$($env:COMPUTERNAME)] No Memory.dmp file found." | Out-File -FilePath $outputPath -Encoding UTF8 -Append
    }

    "-----MemoryDmp_Cleanup-End-------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
}

# Function: Clean C:\temp
Function CleanUpCTemp {
    Write-Host "CleanupCTemp"
    "-----CleanupCTemp-Start-----------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

    $folderPath = "C:\temp"
    if (Test-Path $folderPath) {
        $files = Get-ChildItem -Path $folderPath -File -Recurse -Force -ErrorAction SilentlyContinue
        $CTempfolderSizeBeforeMB = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

        "[$($env:COMPUTERNAME)] C Temp folder size before: $CTempfolderSizeBeforeMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append



        try {
            $files | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path $folderPath -Directory -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

            $CTempfilesAfter = Get-ChildItem -Path $folderPath -File -Recurse -Force -ErrorAction SilentlyContinue
            $CTempfolderSizeAfterMB = [math]::Round(($CTempfilesAfter | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

            $global:CTempspaceFreedMB = [math]::Round($CTempfolderSizeBeforeMB - $CTempfolderSizeAfterMB, 2)

            "[$($env:COMPUTERNAME)] Space reclaimed from C:\temp: $CTempspaceFreedMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
        } catch {
            Write-Warning "Failed to clean: $folderPath - $_"
        }
    } else {
        Write-Warning "Path does not exist: $folderPath"
    }

    "-----CleanupCTemp-End-------------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
}

# Function: Empty Recycle Bin
Function Empty_RecycleBin {
    Write-Host "Empty_RecycleBin"
    "-----Empty_RecycleBin-Start------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(10)
    $RecycletotalSize = 0

    foreach ($item in $recycleBin.Items()) {
        $RecycletotalSize += $item.ExtendedProperty("Size")
    }

    $RecycleSizeBeforeMB = [math]::Round($RecycletotalSize / 1MB, 2)
    "[$($env:COMPUTERNAME)] Recycle Bin size before: $RecycleSizeBeforeMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3

    $RecycletotalSize = 0
    foreach ($item in $recycleBin.Items()) {
        $RecycletotalSize += $item.ExtendedProperty("Size")
    }

    $RecycleSizeAfterMB = [math]::Round($RecycletotalSize / 1MB, 2)
    $global:RecycledSpaceFreedMB = [math]::Round($RecycleSizeBeforeMB - $RecycleSizeAfterMB, 2)

    "[$($env:COMPUTERNAME)] Space reclaimed from Recycle Bin: $RecycledSpaceFreedMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
    "-----Empty_RecycleBin-End-------------------------------" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
}

Function CloseChangeTicket {

    Write-Host "CloseChangeTicket"

    $webhookUrl = "https://api-private.atlassian.com/automation/webhooks/jira/a/48af41da-3deb-4f00-a9c5-2a5c873f8b26/018b4a43-82c5-74a1-a9a3-368599f994f2"

    $headers = @{
        "Content-Type"               = "application/json"
        "X-automation-webhook-token" = "678dbd1d19476f5d6dc6195abcfb712f7c2d327f"
    }

    # Generate dynamic UTC timestamps
    $actualEndUtc   = (Get-Date).ToUniversalTime()
    $actualStartUtc = (Get-Date).AddMinutes(-5).ToUniversalTime()

    $body = @{
        originatesFrom          = "Grafana"
        action                  = "Close"
        externalReferenceNumber = $ChangeTicketVar
        actualStartDate         = $actualStartUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
        actualEndDate           = $actualEndUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
        implementersNotes       = "Automation Test"
        finalDisposition        = "Successful"
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod `
        -Uri $webhookUrl `
        -Method Post `
        -Headers $headers `
        -Body $body
}

# Function: Email Summary
Function Send_NotificationEmail {
    Write-Host "Send_NotificationEmail"
    $totalFreedMB = $RecycledSpaceFreedMB + $DSCspaceFreedMB + $MemoryDmpFreedMB + $CTempspaceFreedMB

    "[$($env:COMPUTERNAME)] Total space reclaimed: $totalFreedMB MB" | Out-File -FilePath $outputPath -Encoding UTF8 -Append

    $cleanupOutput = Get-Content -Path $outputPath -Raw

    $EmailBody = @"
This job ran on: [$($env:COMPUTERNAME)]
----------------------------------------

$cleanupOutput
"@

    $EmailSplat = @{
        From        = "noreply@wexglobal.com"
        To          = @(
           "gl-azure-cloud-operations@wexinc.com"#,
           #"matthew.sly@wexinc.com"
        )
        Subject     = "C Drive Cleanup Report - $(Get-Date -Format 'MM-dd-yyyy') [$($env:COMPUTERNAME)]"
        Body        = $EmailBody
        SmtpServer  = "smtp.azr.wexglobal.com"
        Port        = 25002
        Attachments = @($outputPath, $TranscriptPath)
    }

    try {
        Stop-Transcript
        Send-MailMessage @EmailSplat
        Write-Host "Email sent successfully."
    } catch {
        Write-Warning "Failed to send email: $_"
        "[$($env:COMPUTERNAME)] Email sending failed: $_" | Out-File -FilePath $outputPath -Encoding UTF8 -Append
    }
}

# --- Main Execution ---
Initialization
OpenChangeTicket
WriteTo_ApplicationEventLog
DSC_Cleanup
MemoryDmp_Cleanup
CleanUpCTemp
Empty_RecycleBin
CloseChangeTicket
Send_NotificationEmail
Write-Output "Cleanup completed."