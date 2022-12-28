Set-PSDebug -Trace 0
$CSV = Import-Csv -Path .\substitution2.csv
$CSV | Format-Table
$Empty = 10

function RecursivelyReaddress {
    param (
        $FirstDevice
    )
    foreach ($SecondDevice in $CSV) {
        if($FirstDevice.NewMAC -eq $SecondDevice.CurrentMAC) {
            $SecondDevice.CurrentMAC = $Empty + 1
            $Empty++
            $CSV | Format-Table
            RecursivelyReaddress $SecondDevice
        }
    }
    $FirstDevice.CurrentMAC = $FirstDevice.NewMAC
    #RecursivelyReaddress = $FirstDevice

}
foreach ($Device in $CSV) {
    RecursivelyReaddress -FirstDevice $Device
    $CSV | Format-Table
}