#Data Dog Monitor path:  https://app.datadoghq.com/check/summary?id=Panzura.UNCCheck
# or https://app.datadoghq.com/monitors/144143425 

function TestUNCPath {
    param (
        [String]$UNC_Path,
        $Check_Name,
        $FileName = "dd_test.txt"
    )

    $Tags = @(("unc_path:" + [String]$UNC_Path))
    $Full_Path = Join-Path -Path $UNC_Path -ChildPath $FileName      #Joins fullPath with File name = \\wexprodr\wh\LBTest\dd_test.txt
    try {
        Write-Host ("Writing to file at " + $Full_Path)              #writes file to share ... basically writes a new blank file.
        Add-Content -Path $Full_Path -Value "This is a test file" -ErrorAction Stop    #adds text to test file

        #Check if file exists
        if (Test-Path $Full_Path) {
            Write-Host("File successfully written to: " + $Full_Path)
            SubmitServiceCheck $Check_Name 0 $Tags                          #calls SubmitServiceCheck to call DataDog
        }
        else {
            Write-Error("Failed to write file: " + $Full_Path)
            SubmitServiceCheck $Check_Name 2 $Tags "Test file not found"     #submits a 2 to DataDog
        }
     
        # Delete test file
        Remove-Item -Path $Full_Path -Force -ErrorAction Stop
        Write-Host("Test file deleted: " + $Full_Path)            #degug ... write to console
    }
    catch {
        Write-Error("Error during UNC Path Test: " + $_)        #any failures above will enter here.
        SubmitServiceCheck $Check_Name 2 $Tags ("Error during UNC Path Test: " + $_)     #writes failure to SubmitServiceCheck
    }
}


function SubmitServiceCheck {
    param (
        $CheckName,
        $Status,
        $Tags,
        $Message=""
    )
    
    $headers=@{}                                                         #authentication headers into DataDog
    $headers.Add("DD-API-KEY", "72c6fb72507e30f06d725323a8eaf6d9")      #
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "Basic Og==")

    $body = @{                                                          #data sending to DataDog
        "check" = $Check_Name
        "status" = $Status
        "tags" = $Tags
        "message" = $Message
    }
    #Write-Host $body
    $json = $body | ConvertTo-Json -depth 4                         #converting BODY from PowerShellObject to JSON Object
    Write-Host $json

    $response = Invoke-WebRequest -Uri 'https://api.datadoghq.com/api/v1/check_run' -Method POST -Headers $headers -ContentType 'application/json' -Body $json

    if($response.StatusCode -eq "202") {
        Write-Host "Data submitted successfully"
    }
    else {
        Write-Host ("Error submitting data:" + $response.StatusCode)
    }
}


#---DevRing - meu1panfile000d
TestUNCPath "\\wexprodr\wh\WHint\logging\GrafanaMonitor2" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\whint_SecureKey\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHnonprod\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHqa\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\whqa_securekey\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\whqa_tiger\logging\GrafanaMonitor" "Panzura.UNCCheck"

#---StageRing - meu1panfile000s
#TestUNCPath "\\wexprodr\wh\protected-nonprod\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHstg\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\whstg_securekey\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHteams_stg\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\whtrn_securekey\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHuat_SecureKey\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHvt\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\whvt_securekey\logging\GrafanaMonitor" "Panzura.UNCCheck"

#---StageRing - meu1panfile100s
#TestUNCPath "\\wexprodr\wh\WHOnBasePartnerNP\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHtrn\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHuat\logging\GrafanaMonitor" "Panzura.UNCCheck"

#---ProdRing - meu1panfile000p
#TestUNCPath "\\wexprodr\wh\protected-prod\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHCobraRPA\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHDBFS\logging\GrafanaMonitor" "Panzura.UNCCheck"#TestUNCPath "\\wexprodr\wh\WHOnBaseDirect\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHOnBaseImport\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHOnBasePartner\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHprd\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHprd_appdata\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHprd_Quickbooks\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\whprd_securekey\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHprd_tiger\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHsql\logging\GrafanaMonitor" "Panzura.UNCCheck"
#TestUNCPath "\\wexprodr\wh\WHTeams\logging\GrafanaMonitor" "Panzura.UNCCheck"