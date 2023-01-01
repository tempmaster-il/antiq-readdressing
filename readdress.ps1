﻿function LifeCheck {
    param (
        $Instance
    )
    .\bacrp.exe $Instance 8 1 44
}
function CreateAddressAtomicFile {
    param (
        $NewInstance,
        $NewMAC
    )
    .\BACAF1.EXE $NewInstance $NewMAC "$NewInstance.F1"
}
function WriteAddressAtomicFile {
    param (
        $DeviceInstance,
        $FileName
    )
    # It's file instance 1
    .\bacawf.exe $DeviceInstance 1 "$FileName.F1"
}
function RestartDevice {
    param (
        $Instance
    )
    # Instance, State 0 (Coldstart), Password
    .\bacrd.exe $Instance 0 snowman
}
function Readdress {
    param (
        $CurrentInstance,
        $NewInstance,
        $CurrentMAC,
        $NewMAC
    )
    LifeCheck -Instance $CurrentInstance
    if ($LASTEXITCODE -ne 0) {
        return "Not Found"
    }
    CreateAddressAtomicFile -NewInstance $NewInstance -NewMAC $NewMAC
    WriteAddressAtomicFile -DeviceInstance $CurrentInstance -FileName $NewInstance
    RestartDevice -Instance $CurrentInstance
    LifeCheck -Instance $NewInstance
}
Set-PSDebug -Trace 0
$Env:BACNET_IFACE = Read-Host "Please enter the BACnet Interface IP"
$Empty = [int](Read-Host "Please enter the start of a empty range")
$CSV = Import-Csv -Path .\substitution.csv
function RecursivelyReaddress {
    param (
        $FirstDevice
    )
    foreach ($SecondDevice in $CSV) {
        if($FirstDevice.NewMAC -eq $SecondDevice.CurrentMAC) {
            $SecondDeviceStatus = Readdress -CurrentInstance $SecondDevice.CurrentInstance -CurrentMAC $SecondDevice.CurrentMAC -NewInstance $SecondDevice.CurrentInstance -NewMAC $Empty
            if ($SecondDeviceStatus -eq "Not Found") {
                $SecondDevice.Status = "Not Found"
                break
            }
            $SecondDevice.CurrentMAC = $Empty
            $Empty++
            RecursivelyReaddress -FirstDevice $SecondDevice
        }
    }
    $SecondDeviceStatus = Readdress -CurrentInstance $FirstDevice.CurrentInstance -CurrentMAC $FirstDevice.CurrentMAC -NewInstance $FirstDevice.NewInstance -NewMAC $FirstDevice.NewMAC
    if ($SecondDeviceStatus -eq "Not Found") {
        $SecondDevice.Status = "Not Found"
        return
    }
    $FirstDevice.CurrentMAC = $FirstDevice.NewMAC
}
foreach ($Device in $CSV) {
    if ($Device.CurrentMAC -ne $Device.NewMAC) {
        RecursivelyReaddress -FirstDevice $Device
    }
}

$CSV | Export-Csv -Path .\output.csv -NoTypeInformation