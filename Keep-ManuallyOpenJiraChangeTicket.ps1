#Creating a Standard Change in Jira by API = https://docs.google.com/document/d/1aSc_jNEsc_GkujHfYU3BZArKKGanZ9RiEjOMTWs-SBA/edit?tab=t.0
#Jira Change Queue:  https://wexinc.atlassian.net/jira/servicedesk/projects/CHG/section/changes/custom/126

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
    externalReferenceNumber   = "CDriveCleanup"
    region                    = "NA/EMEA/Vienna/Crewe"
    ownedByTeam               = "Cloud Operations Azure"
    owner                     = "Matt Sly"
    cab                       = "Benefits"
    beginImplementation       = $true
    additionalDescriptionText = "Jira test from Matt Sly - Executed from VM: $hostname"
} | ConvertTo-Json -Depth 5


Invoke-RestMethod `
    -Uri $webhookUrl `
    -Method Post `
    -Headers $headers `
    -Body $body