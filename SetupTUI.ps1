
$windows = New-Object System.Management.Automation.Host.ChoiceDescription '&1', 'Install: Windows Features'
$software = New-Object System.Management.Automation.Host.ChoiceDescription '&2', 'Install: Software'
$vars = New-Object System.Management.Automation.Host.ChoiceDescription '&3', 'Install: Environment Vars'
$options = [System.Management.Automation.Host.ChoiceDescription[]]($windows, $software, $vars)
$title = 'New PC Install TUI'
$message = @"
New PC Install
1: Press '1' to Install Windows Features
2: Press '2' to Install 3rd Party Software
3: Press '3' to Install Environment Variables
4: Press '4' to Install PowerShell Profile
5: Press '5' to Install Git Bash Profile
"@
$result = $host.ui.PromptForChoice($title, $message, $options, 0)
switch ($result)
{
    0 { 'You want to install Windows Features' }
    1 { 'You want to install 3rd Part Software' }
    2 { 'You want to install Environment Variables' }
    3 { 'You want to install PowerShell Profile' }
    4 { 'You want to install Git Bash Profile' }
}

