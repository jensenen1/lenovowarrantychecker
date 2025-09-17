$ApiUrl = "https://example.com/api/v1"
$ApiToken = "YOURTOKEN"

Install-Module -Name Selenium -Force -AllowClobber
Import-Module Selenium

function Get-ComputerSerialNumber {
    $invalidSerials = @(
        "To Be Filled By O.E.M.",
        "Default_String",
        "INVALID"
    )

    $serialNumber = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber

    if ($serialNumber -in $invalidSerials) {
        return ""
    }

    return $serialNumber
}
$serialNumber = Get-ComputerSerialNumber

$driver = Start-SeChrome 
$driver.Navigate().GoToUrl("https://pcsupport.lenovo.com/us/en/products/$serialNumber/warranty")

Start-Sleep -Seconds 2

#For country popup (May need to be removed if not necessary)
$proceedButton = $driver.FindElementByXPath("//button[contains(text(), 'Proceed with United States of America')]")
$proceedButton.Click()

Start-Sleep -Seconds 2

$dateElements = $driver.FindElementsByCssSelector("span.property-value")

foreach ($el in $dateElements) {
    Write-Output $el.Text
}
$dateValue = $dateElements[1].Text  
$dateValueend = $dateElements[4].Text

Write-Output "Warranty start: $dateValue"
Write-Output "Warranty end: $dateValueEnd"

Stop-SeDriver $driver

$customFields = @{
    "_snipeit_warranty_start_14" = if ($dateValue) { $dateValue } else { "" }
    "_snipeit_warranty_end_15"   = if ($dateValueEnd) { $dateValueEnd } else { "" }
}

$headers = @{
    "Authorization" = "Bearer $SnipeItApiToken"
    "accept"        = "application/json"
    "content-type"  = "application/json"
}

$searchUrl = "$SnipeItApiUrl/hardware?search=$serialNumber"
$response = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method Get

if ($response.total -gt 0) {
    $assetId = $response.rows[0].id
    $body = $customFields | ConvertTo-Json
    $updateUrl = "$SnipeItApiUrl/hardware/$assetId"
    $updateResponse = Invoke-RestMethod -Uri $updateUrl -Headers $headers -Method Patch -Body $body
    Write-Output "Asset updated with ID: $assetId"
} else {
    Write-Output "Asset not found for serial number $serialNumber."
}

