$Env:BACNET_IFACE = '192.168.1.9'
function LifeCheck {
    param (
        $Instance
    )
    .\bacrp.exe $Instance 8 1 44
    if ($LASTEXITCODE -ne 0) {
        # ReadIt $Instance
        Write-Host "error"
    }
}


function CreateAddressAtomicFile {
    param (
        $NewInstance,
        $NewMAC
    )
    .\BACAF1.EXE $NewInstance $NewMAC "$NewInstance.F1"
}
LifeCheck -Instance 1
CreateAddressAtomicFile -NewInstance 1 -NewMAC 1
