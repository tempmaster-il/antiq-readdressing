function LifeCheck {
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

function  {
    param (
        $DesiredMAC
    )
    foreach ($OccupierDevice in $CSV) {
        if ($OccupierDevice.CurrentMAC -eq $DesiredMAC) {
            return $OccupierDevice
        }
    }
    $OccupierDevice = $null
}
function Readdress {
    param (
        $CurrentInstance,
        $CurrentMAC,
        $NewInstance,
        $NewMAC
    )
    LifeCheck -Instance $Device.CurrentInstance
    CreateAddressAtomicFile -NewInstance $NewInstance -NewMAC $NewMAC
    WriteAddressAtomicFile -DeviceInstance $CurrentInstance -FileName $NewInstance
    RestartDevice -Instance $CurrentInstance
    LifeCheck -Instance $Device.NewInstance
}

Set-PSDebug -Trace 1
$Env:BACNET_IFACE = Read-Host "Please enter the BACnet Interface IP"
$CSV = Import-Csv -Path .\substitution.csv

foreach ($Device in $CSV) {

    $OccupierDevice = WhoIsOccupierDevice -DesiredMAC $Device.NewMAC
    if ($null -ne $OccupierDevice) {
        Readdress -CurrentInstance $OccupierDevice.CurrentInstance -CurrentMAC $OccupierDevice.CurrentMAC -NewInstance $OccupierDevice.CurrentInstance -NewMAC 127
        Readdress -CurrentInstance $Device.CurrentInstance -CurrentMAC $Device.CurrentMAC -NewInstance $Device.NewInstance -NewMAC $Device.NewMAC
        Readdress -CurrentInstance $OccupierDevice.CurrentInstance -CurrentMAC 127 -NewInstance $OccupierDevice.CurrentInstance -NewMAC $OccupierDevice.CurrentMAC
    }
    else {
        Readdress -CurrentInstance $Device.CurrentInstance -CurrentMAC $Device.CurrentMAC -NewInstance $Device.NewInstance -NewMAC $Device.NewMAC
    }
}

function RecursivelyReaddress {
    param (
        $FirstDevice
    )
    foreach ($SecondDevice in $CSV) {
        if($FirstDevice.NewMAC -eq $SecondDevice.CurrentMAC) {
            Readdress $FirstDevice $i
            RecursivelyReaddress $SecondDevice $i+1
        }
    }
    Readdress $FirstDevice
}