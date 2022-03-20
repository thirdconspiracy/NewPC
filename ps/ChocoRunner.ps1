class ChocoRunner {
    [PSObject]$Logger

    ChocoRunner($logger) {
        $this.Logger = $logger
    }
    
    InstallFromConfig([string] $configPath, [string[]] $chocoArgs) {

        if (-not(Test-Path -Path $configPath)) {
            $this.Logger.LogError("[$configPath] does not exist.")
            return
        }

        $resolvedPath = Resolve-Path -Path $configPath

        

        $cmdArgs = @("install", $resolvedPath)
        $cmdArgs += $chocoArgs
        & choco $cmdArgs | Tee-Object -FilePath "$($this.Logger.LogPath)" | Write-Host

        if ($LASTEXITCODE -eq 3010) {
            $this.Logger.LogInfo("Rebbot required after running installs for config [$resolvedPath]")
        } elseif ($LASTEXITCODE -ne 0) {
            $this.Logger.LogError("Failed to install packages from [$resolvedPath]")
        } else {
            $this.Logger.LogInfo("Installed packages from $resolvedPath")
        }
    }

    InstallChocolatey() {
        try{
            $cmdArgs = @("config", "get", "cacheLocation")
            & choco $cmdArgs | Tee-Object -FilePath "$($this.Logger.LogPath)" | Write-Host
            $this.Logger.LogInfo("Chocolatey already installed")
        }catch{
            $this.Logger.LogInfo("Chocolatey not detected, trying to install now...")
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            $this.Logger.LogInfo("Finished installing chocolatey.")
        }
    }
}