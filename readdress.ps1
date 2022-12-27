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

function IfExistMoveToTemp {
    param (
        $DesiredMAC
    )
    foreach ($OccupierDevice in $CSV) {
        if ($OccupierDevice.CurrentMAC -eq $DesiredMAC) {
            $TempMac = [int]($OccupierDevice.CurrentMAC) + $TempPrefix
            #Readdress -CurrentInstance $OccupierDevice.CurrentInstance -CurrentMAC $OccupierDevice.CurrentMAC -NewInstance $OccupierDevice.CurrentInstance -NewMAC $TempMac
            #if ($LASTEXITCODE -eq 0) {
                $OccupierDevice.CurrentMAC = $TempMac
                $CSV | Export-Csv -Path .\substitution.csv -NoTypeInformation
            #}
            break
        }
    }
}
function Readdress {
    param (
        $CurrentInstance,
        $CurrentMAC,
        $NewInstance,
        $NewMAC
    )
    LifeCheck -Instance $CurrentInstance
    CreateAddressAtomicFile -NewInstance $NewInstance -NewMAC $NewMAC
    WriteAddressAtomicFile -DeviceInstance $CurrentInstance -FileName $NewInstance
    RestartDevice -Instance $CurrentInstance
}

$Env:BACNET_IFACE = Read-Host "Please enter the BACnet Interface IP"
$TempPrefix = [int](Read-Host "Please enter a empty prefix (e.g. 1 = 100, so 22 will moved to 122 temporarly)") * 100
$CSV = Import-Csv -Path .\substitution.csv

foreach ($Device in $CSV) {
    IfExistMoveToTemp -DesiredMAC $Device.NewMAC
    Readdress -CurrentInstance $Device.CurrentInstance -CurrentMAC $Device.CurrentMAC -NewInstance $Device.NewInstance -NewMAC $Device.NewMAC
    LifeCheck -Instance $Device.NewInstance
    if ($LASTEXITCODE -eq 0) {
        $Device.CurrentMAC = $Device.NewMAC
        $Device.CurrentInstance = $Device.NewInstance
        $CSV | Export-Csv -Path .\substitution.csv -NoTypeInformation
    }
}