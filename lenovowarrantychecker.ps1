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

$proceedButton = $driver.FindElementByXPath("//button[contains(text(), 'Proceed with United States of America')]")
$proceedButton.Click()

Start-Sleep -Seconds 2

$dateElements = $driver.FindElementsByCssSelector("span.property-value")

foreach ($el in $dateElements) {
    Write-Output $el.Text
}
$dateValue = $dateElements[1].Text  

Write-Output "Warranty Start-date: $dateValue"
