# Clear previous output files (optional)
Remove-Item "E:\Scripts\Azure\AzureUnattachedDisks\ResourceGroups.txt" -ErrorAction SilentlyContinue
Remove-Item "E:\Scripts\Azure\AzureUnattachedDisks\UnattachedDisks.txt" -ErrorAction SilentlyContinue
Remove-Item "E:\Scripts\Azure\AzureUnattachedDisks\subscriptions.txt" -ErrorAction SilentlyContinue

Connect-AzAccount

# Save list of subscription IDs
Get-AzSubscription | Select-Object Id | Out-File -FilePath "E:\Scripts\Azure\AzureUnattachedDisks\subscriptions.txt"
$subscriptions = Get-AzSubscription | Select-Object Id

# Write header for unattached disk CSV
"Name,ResourceGroupName,Location,DiskSizeGB,OsType,Sku" | Out-File -FilePath "E:\Scripts\Azure\AzureUnattachedDisks\UnattachedDisks.txt"

Write-Host "Current subscription: $subscription"

foreach ($subscription in $subscriptions.Id) {
    # Set the subscription context
    Select-AzSubscription -SubscriptionId $subscription

    # Fetch and log resource groups
    Add-Content -Path "E:\Scripts\Azure\AzureUnattachedDisks\ResourceGroups.txt" -Value "=== Subscription: $subscription ==="

    $rgList = Get-AzResourceGroup
    if ($rgList.Count -eq 0) {
        Write-Host "No resource groups found in this subscription."
    } else {
        $rgList | Select-Object -ExpandProperty ResourceGroupName | Out-File -FilePath "E:\Scripts\Azure\AzureUnattachedDisks\ResourceGroups.txt" -Append
    }

    # Loop through each resource group and collect unattached disks
    foreach ($rg in $rgList) {
        $diskList = Get-AzDisk -ResourceGroupName $rg.ResourceGroupName
        $unattachedDisks = $diskList | Where-Object { $_.DiskState -eq 'Unattached' -and ($_.Name -notlike '*ASRReplica*') }

        $unattachedDisks | Select-Object Name, ResourceGroupName, Location, DiskSizeGB, OsType, @{Name='Sku'; Expression = {$_.Sku.Name}} |
        Export-Csv -Path "E:\Scripts\Azure\AzureUnattachedDisks\UnattachedDisks.txt" -Append -NoTypeInformation
    }
 }

#defines email variables
$unattachedDisksContent = Get-Content -Path "E:\Scripts\Azure\AzureUnattachedDisks\UnattachedDisks.txt" -Raw

$EmailBody = @"
This job runs from:  meu1toolsn000p\E$\Scripts\Azure\AzureUnattachedDisks\get-azdisk.ps1
This job outputs all Disks with a "DiskStates" equal to:  "Unattached" and excludes all disks with the name:  ASRReplica.
If there is nothing below:  Name,ResourceGroupName,Location,DiskSizeGB,OsType,Sku  then there are no UnAttached disks that need reviewed and deleted.

$unattachedDisksContent
"@

$EmailSplat = @{
    From       = "noreply@wexglobal.com"
    To         = @(
        "memail_mailbox@commvault.wexinc.xmatters.com"
        #,"matthew.sly@wexinc.com"
    )
    Subject    = "Azure Unattached Disks $(Get-Date -Format 'MM-dd-yyyy')"
    Body       = $EmailBody
    SmtpServer = "smtp.azr.wexglobal.com"
    Port       = 25002
    Attachments= "E:\Scripts\Azure\AzureUnattachedDisks\UnattachedDisks.txt"
}

Send-MailMessage @EmailSplat