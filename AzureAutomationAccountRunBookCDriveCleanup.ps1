param(
    [object]$WebhookData
)

Write-Output "Webhook triggered..."

# -------------------------------------------------------------
# 1. Parse webhook payload (CORRECT WAY)
# -------------------------------------------------------------
if (-not $WebhookData) {
    throw "Runbook must be triggered by a webhook."
}

if (-not $WebhookData.RequestBody) {
    throw "Webhook RequestBody is empty."
}

Write-Output "Parsing webhook RequestBody..."

try {
    $body = $WebhookData.RequestBody | ConvertFrom-Json
}
catch {
    throw "Invalid JSON in webhook RequestBody. Error: $_"
}

$SubscriptionId = $body.SubscriptionId
$ResourceGroup  = $body.ResourceGroup
$VmName         = $body.VmName

if (-not $SubscriptionId -or -not $ResourceGroup -or -not $VmName) {
    throw "Missing required parameters in webhook payload."
}

Write-Output "SubscriptionId : $SubscriptionId"
Write-Output "ResourceGroup  : $ResourceGroup"
Write-Output "VM Name        : $VmName"

# -------------------------------------------------------------
# 2. Blob URL (direct link)
# -------------------------------------------------------------
$blobUrl = "https://gtscloudopsazure.blob.core.windows.net/cdrivecleanup/CDriveCleanup.ps1"
Write-Output "Using direct Blob URL: $blobUrl"

# -------------------------------------------------------------
# 3. Connect to Azure using Managed Identity
# -------------------------------------------------------------
Connect-AzAccount -Identity
Set-AzContext -Subscription $SubscriptionId

# -------------------------------------------------------------
# 4. Ensure C:\Scripts folder exists on VM
# -------------------------------------------------------------
$ensureFolderScript = @"
if (!(Test-Path 'C:\Scripts')) { New-Item -Path 'C:\Scripts' -ItemType Directory -Force }
"@

Invoke-AzVMRunCommand `
    -ResourceGroupName $ResourceGroup `
    -VMName $VmName `
    -CommandId "RunPowerShellScript" `
    -ScriptString $ensureFolderScript

# -------------------------------------------------------------
# 5. Build Run Command script to download and execute the blob
# -------------------------------------------------------------

$runCommandScript = @"
Write-Output 'Downloading script from Storage...'
Invoke-WebRequest -Uri '$blobUrl' -OutFile 'C:\Scripts\CDriveCleanup.ps1' -UseBasicParsing

Write-Output 'Executing script...'
try {
    & 'C:\Scripts\CDriveCleanup.ps1'
    Write-Output 'Script execution completed successfully.'
}
catch {
    Write-Output 'Script execution failed:'
    Write-Output \$_
}
"@

# -------------------------------------------------------------
# 6. Execute script on the VM
# -------------------------------------------------------------
Write-Output "Sending script to VM: $VmName"

$commandResult = Invoke-AzVMRunCommand `
    -ResourceGroupName $ResourceGroup `
    -VMName $VmName `
    -CommandId "RunPowerShellScript" `
    -ScriptString $runCommandScript

# -------------------------------------------------------------
# 7. Output results
# -------------------------------------------------------------
Write-Output "Run Command output:"
$commandResult.Value | ForEach-Object { Write-Output $_.Message }
Write-Output "Run Command completed."