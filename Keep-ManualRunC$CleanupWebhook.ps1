#$webhookUrl = "https://c820c972-ade2-48ce-ba67-c3a30f3fdddc.webhook.eus.azure-automation.net/webhooks?token=GqePI%2fAZ8nr5IpZjB3BX2YtxgUUCcZ4GSu1TOTawJyo%3d"
$webhookUrl = "https://48895874-6920-4aa8-86b0-d4113f16c4b5.webhook.eus.azure-automation.net/webhooks?token=NB%2bAdKhuTSJGGOlIPNTXd5J8bpmTzCVYQPxvlJy5XkQ%3d"

    #"SubscriptionId": "cc76a746-c9c0-45f3-b167-962842e90b6c",
    #"ResourceGroup": "RG-CORESERVICESPROD-01-EASTUS",
    #"VmName": "MEU1ROBO001P"

$body = '{
    "SubscriptionId": "cc76a746-c9c0-45f3-b167-962842e90b6c",
    "ResourceGroup": "rg-coreservicesprod-01-eastus",
    "VmName": "MEU1TOOLSN000P"
}'

Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json"