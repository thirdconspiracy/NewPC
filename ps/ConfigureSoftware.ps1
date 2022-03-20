param (
    [Parameter(Position=0)][string]$BuildRoot = "c:\dev"
)

####TODO: ###
# 1. Configure for C:\dev
# 2. Create global config
# 3. Set name/email
# 4. Add Diff/Merge for Beyond Compare, Code Compare, & VS
# 5. Set Diff & Merge to Code Compare
# 6. Add checkin template & hooks
# 7. Add Git Aliases
# 8. Clone Repos

#### MAIN ####
[ScriptScope]::CreateDirIfNotExists($BuildRoot)
[ScriptScope]::SetMsbuildPath()
[GitConfig]::DoIt()
[GitConfig]::CloneIrsBuild($BuildRoot)
[NugetConfig]::DoIt()


[ScriptScope]::TurnOnDistributedTransactionCoordinator()
[ScriptScope]::EnablePseudoLocales()
[ScriptScope]::LimitSqlServerMemoryUsage()


#### END MAIN ####

class NugetConfig {
    static DoIt() {
        [ScriptScope]::LogInfo("Configuring nuget settings")


        [NugetConfig]::AddSource("Team City", "https://teamcity.inreach.garmin.com/httpAuth/app/nuget/v1/FeedService.svc/")
        [NugetConfig]::SetSourceCredentials("Team City")

    }

    hidden static SetSourceCredentials($name) {
        $userName = $null
        do {
            $userName = Read-Host -Prompt "Enter your Garmin user name without any garmin reference, or q to quit trying  E.g. smith"
            if (($userName -like "*garmin*") -or ($userName -match "^\s*$")) {
                $userName = $null
            }
        } while ($null -eq $userName)

        if ($userName -eq "q") {
            return
        }

        $securePwd = $null
        $myPwd = $null
        do {
            $securePwd = Read-Host -Prompt "Enter your Garmin password or q to quit trying" -AsSecureString
            $myPwd = [System.Net.NetworkCredential]::new("", $securePwd).Password
        } while ($null -eq $myPwd)

        if ($myPwd -eq "q") {
            return
        }

        $cmdArgs = @(
            "sources",
            "update",
            "-Name",
            $name,
            "-Username",
            $userName,
            "-Password",
            $myPwd
        )

        [NugetConfig]::RunNuget($cmdArgs, "Updating nuget user and password for source [$name]")

        if ([NugetConfig]::TestCredentialsFailed($name)) {
            Write-Host "Credential test failed.  Try again"
            [NugetConfig]::SetSourceCredentials($name)
        }
    }

    hidden static [bool] TestCredentialsFailed($name) {
        $cmdArgs = @(
            "list",
            "xx",
            "-Source",
            $name,
            "-NonInteractive"
        )

        try {
            [ScriptScope]::LogInfo("Test nuget credentials for source [$name] ...")
            [NugetConfig]::RunNuget($cmdArgs)
            [ScriptScope]::LogInfo("nuget credentials for source [$name] are valid.")
            return $false
        } catch {
            [ScriptScope]::LogError("credential test [$cmdArgs] for $name failed.")
            return $true
        }
    }


    hidden static AddSource([string] $name, [string] $path) {

        if ([NugetConfig]::SourceExists($name)) {
            [ScriptScope]::LogInfo("Source [$name] already exists")
            return;
        }

        [ScriptScope]::LogInfo("Adding nuget source [$name] ...")
        $cmdArgs = @(
            "sources",
            "Add",
            "-Name",
            $name,
            "-Source",
            $path
        )

        [NugetConfig]::RunNuget($cmdArgs)
        [ScriptScope]::LogInfo("Finished adding nuget source [$name] ...")
    }

    hidden static [Boolean] SourceExists([string] $name) {
        $cmdArgs = @(
            "sources",
            "list"
        )

        $result = (& nuget $cmdArgs | Where-Object {$_ -like "*$name*Enabled*"}) | Out-String
        return $result -like "*$name*"
    }

    hidden static RunNuget($cmdArgs, $loggingContext) {
        & nuget $cmdArgs | Tee-Object -FilePath "$([ScriptScope]::LOG_PATH)" | Write-Host
        if ($LASTEXITCODE -ne 0) {
            $msg = "nuget failed to execute [$loggingContext]"
            [ScriptScope]::LogError($msg)
            throw $msg
        } else {
            [ScriptScope]::LogInfo($loggingContext)
        }
    }

    hidden static RunNuget($cmdArgs) {
        & nuget $cmdArgs | Tee-Object -FilePath "$([ScriptScope]::LOG_PATH)" | Write-Host
        if ($LASTEXITCODE -ne 0) {
            $msg = "nuget failed to execute [$cmdArgs] and got exit code [$LASTEXITCODE]"
            [ScriptScope]::LogError($msg)
            throw $msg
        } else {
            [ScriptScope]::LogInfo("nuget executed with [$cmdArgs]")
        }
    }
}

class GitConfig {
    static DoIt() {
        [ScriptScope]::LogInfo("Configuring git settings")

        [GitConfig]::ConfigureForMaine()
        [GitConfig]::SetName()
        [GitConfig]::SetEmail()
        [GitConfig]::AddCommitHooks()
        [GitConfig]::ConfigureBeyondCompare()
        [GitConfig]::SetAutoCrLfOn()
    }

    static SetAutoCrLfOn() {
        # config --global core.autocrlf true
        [ScriptScope]::LogInfo("Setting auto CRLF to true ...")

        $cmdArgs = @("config", "--global", "core.autocrlf", "true")
        [GitConfig]::RunGit($cmdArgs)

        [ScriptScope]::LogInfo("Finished setting auto CRLF to true")
    }
    static CloneIrsBuild($buildRoot) {

        $destFolder = Join-Path -Path $buildRoot -ChildPath "irs-build"
        if (Test-Path -Path $destFolder) {
            [ScriptScope]::LogInfo("irs-build already exists at [$destFolder].  Skipping.")
            return
        }

        [ScriptScope]::LogInfo("Cloning irs-build into $destFolder")

        $ans = Read-Host -Prompt "Are you working in Maine (Y or N)"
        $cmdArgs = @("clone", "https://itstash.garmin.com/scm/irwt/irs-build.git", $destFolder)
        if ($ans -eq "Y") {
            $cmdArgs = @("clone", "https://yarxpa-itwgit00.garmin.com/scm/itstash/irwt/irs-build.git", $destFolder)
        }

        [GitConfig]::RunGit($cmdArgs)
    }

    hidden static ConfigureForMaine() {
        $ans = Read-Host -Prompt "Are you working in Maine (Y or N)"
        if ($ans -eq "Y") {
            [ScriptScope]::LogInfo("Configuring Maine git settings")
            $cmdArgs = @(
                "config",
                "--global",
                "--replace-all",
                "url.https://itstash.garmin.com/scm/.pushInsteadOf",
                "https://yarxpa-itwgit00.garmin.com/scm/itstash/")

            [GitConfig]::RunGit($cmdArgs)
        }
    }

    hidden static SetName() {
        $name = Read-Host -Prompt "Enter your first and last name"

        if ($name) {
            $cmdArgs = @("config", "--global", "user.name", $name)
            [GitConfig]::RunGit($cmdArgs)
        }
    }

    hidden static SetEmail() {
        $email = Read-Host -Prompt "Enter your garmin email address"
        if ($email) {
            $cmdArgs = @("config", "--global", "user.email", $email)
            [GitConfig]::RunGit($cmdArgs)
        }
    }

    hidden static AddCommitHooks() {
        [ScriptScope]::LogInfo("Configuring git hooks")

        $hookFile = "$PSScriptRoot\prepare-commit-msg"
        Copy-Item -Path $hookFile -Destination "C:\Program Files\Git\mingw64\share\git-core\templates\hooks\" -Force

        $cmdArgs = @("config", "--global", "init.templatedir", "C:/Program Files/Git/mingw64/share/git-core/templates")
        [GitConfig]::RunGit($cmdArgs)

        $cmdArgs = @("config", "--global", "core.hooksPath", "C:/Program Files/Git/mingw64/share/git-core/templates/hooks")
        [GitConfig]::RunGit($cmdArgs)
    }

    hidden static ConfigureBeyondCompare() {
        [ScriptScope]::LogInfo("Mapping difftool and mergetool to BeyondCompare")

        # diff
        $cmdArgs = @("config", "--global", "diff.tool", "bc")
        [GitConfig]::RunGit($cmdArgs)

        $cmdArgs = @("config", "--global", "difftool.bc.path", "c:/Program Files/Beyond Compare 4/bcomp.exe")
        [GitConfig]::RunGit($cmdArgs)

        # merge
        $cmdArgs = @("config", "--global", "merge.tool", "bc")
        [GitConfig]::RunGit($cmdArgs)

        $cmdArgs = @("config", "--global", "mergetool.bc.path", "c:/Program Files/Beyond Compare 4/bcomp.exe")
        [GitConfig]::RunGit($cmdArgs)
    }

    hidden static RunGit([string[]] $cmdArgs) {
        & git $cmdArgs | Tee-Object -FilePath "$([ScriptScope]::LOG_PATH)" | Write-Host
        if ($LASTEXITCODE -ne 0) {
            [ScriptScope]::LogError("Git failed to execute [$cmdArgs]")
        } else {
            [ScriptScope]::LogInfo("Git executed with [$cmdArgs]")
        }
    }
}


class ScriptScope {
    static [string]$LOG_PATH = "$PSScriptRoot\$PSCommandPath.log"
    static [bool]$HasError = $false

    static LimitSqlServerMemoryUsage() {
        $queryFile = "$PSScriptRoot\SetMaxSqlServerMemory.sql"
        Invoke-Sqlcmd -InputFile $queryFile -ServerInstance "(local)"
    }

    static EnablePseudoLocales() {
        $registryFile = "\\ad.garmin.com\yarmouth\Web_Team\inReach_Web\Localization\EnablePseudoLocales.reg"
        & reg import $registryFile
        if ($LASTEXITCODE -ne 0) {
            [ScriptScope]::LogError("Failed enable pseudo locales from [$registryFile]")
        } else {
            [ScriptScope]::LogInfo("Enabled pseudo locales from $registryFile")
        }
    }

    static TurnOnDistributedTransactionCoordinator() {
        Set-Service "MSDTC" -StartupType "Automatic"
        Start-Service "MSDTC"
        [ScriptScope]::LogInfo("Turned on Distributed Transaction Coordinator")
    }

    static SetMsbuildPath() {
        if (-Not([Environment]::GetEnvironmentVariable("msbuild", "Machine"))) {
            [Environment]::SetEnvironmentVariable( `
                "msbuild", `
                "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe", `
                "Machine" )
        }
    }

    static CreateDirIfNotExists($dir) {
        if (-Not (Test-Path -Path $dir)) {
            mkdir $dir
        }
    }

    static LogError([string] $errorMsg) {
        [ScriptScope]::HasError = $true
        "$(Get-Date) ERROR: $errorMsg" | Tee-Object -FilePath "$([ScriptScope]::LOG_PATH)" | Write-Host
    }

    static LogInfo([string] $msg) {
        "$(Get-Date) INFO: $msg" | Tee-Object -FilePath "$([ScriptScope]::LOG_PATH)" | Write-Host
    }
}