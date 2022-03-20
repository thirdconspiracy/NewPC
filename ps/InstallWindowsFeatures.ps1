#Requires -RunAsAdministrator
param (
    [Parameter(Position=0)][string[]]$WindowsFeaturesLists = @()
)

$logPath = "$PSCommandPath.log"

$chocoScriptPath = "$PSScriptRoot\ChocoRunner.ps1"
. $chocoScriptPath

$scriptScope = [ScriptScope]::new($logPath)
$chocoRunner = [ChocoRunner]::new($scriptScope)

$chocoRunner.InstallChocolatey()

$WindowsFeaturesLists | ForEach-Object {
    $chocoRunner.InstallFromConfig($_, @("-y", "-s=windowsfeatures"))
}


class ScriptScope {
    [string]$LogPath = "$PSScriptRoot\$PSCommandPath.log"
    [bool]$HasError = $false

    ScriptScope($logPath) {
        $this.LogPath = $logPath
    }
    LogError([string] $errorMsg) {
        $this.HasError = $true
        "$(Get-Date) ERROR: $errorMsg" | Tee-Object -FilePath "$($this.LogPath)" | Write-Host
    }

    LogInfo([string] $msg) {
        "$(Get-Date) INFO: $msg" | Tee-Object -FilePath "$($this.LogPath)" | Write-Host
    }
}

