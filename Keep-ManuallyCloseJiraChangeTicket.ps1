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
    externalReferenceNumber = "CDriveCleanup"
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
