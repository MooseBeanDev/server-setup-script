Write-Host "........................................." -Fore yellow -back black 
Write-host "............ServerSetup1.ps1............." -fore yellow -back black 
Write-Host "........................................." -Fore yellow -back black 
Write-Host ""

#Read in user variables
Write-Host "Reading in variables." -Fore yellow -back black
Write-host "Enter New Hostname: " -ForegroundColor Green -back black -NoNewline 
$newservername = Read-Host
Write-host "Enter New IP Address: " -ForegroundColor Green -back black -NoNewline 
$newipaddress = Read-Host
Write-host "Enter New Gateway: " -ForegroundColor Green -back black -NoNewline 
$newipgateway = Read-Host
Write-host "Enter DNS Server 1. Leave blank for default of DNS1: " -ForegroundColor Green -back black -NoNewline 
$newdns1 = Read-Host
Write-host "Enter DNS Server 2. Leave blank for default of DNS2: " -ForegroundColor Green -back black -NoNewline 
$newdns2 = Read-Host
Write-host "Enter New Local Admin Account Name. Leave blank for default of 'gntadm': " -ForegroundColor Green -back black -NoNewline 
$localadmin = Read-Host
Write-host "Enter New local admin password: " -ForegroundColor Green -back black -NoNewline 
$newpassword = Read-Host -AsSecureString
$databaseserver = $false;
$appsteam = $false;
$driveletter = "";
$drivename = "";
$logdriveletter = "";
$logdrivename = "";
$targetdc = "DC Name"

if (!($newdns1)) {
    $newdns1 = "XXX.XXX.XXX.XXX"
}

if (!($newdns2)) {
    $newdns2 = "XXX.XXX.XXX.XXX"
}
if (!($localadmin)) {
    $localadmin = "gntadm"
}

Write-host "Is this a database server?" -ForegroundColor Green -back black
            Write-Host " (y/n) : " -Fore Green -back black -NoNewline
            $Readhost = Read-Host
            Switch ($ReadHost) 
            { 
            Y {
                $databaseserver = $true
                Write-host "Please enter a drive letter for the database drive. Leave blank for F: " -ForegroundColor Green -back black -NoNewline
                $driveletter = Read-Host
                Write-host "Please enter a drive name for the database drive. Leave blank for 'Database': " -ForegroundColor Green -back black -NoNewline
                $drivename = Read-Host
                Write-host "Please enter a drive letter for the logs drive. Leave blank for L: " -ForegroundColor Green -back black -NoNewline
                $logdriveletter = Read-Host
                Write-host "Please enter a drive name for the logs drive. Leave blank for 'Logs': " -ForegroundColor Green -back black -NoNewline
                $logdrivename = Read-Host
                Write-Host "Database server registered. Drive will be created and premissions will be set." -ForegroundColor Yellow -back black

                if (!($driveletter)) {
                    $driveletter = "F"
                }
                
                if (!($drivename)) {
                    $drivename = "Database"
                }

                if (!($driveletter)) {
                    $driveletter = "L"
                }
                
                if (!($drivename)) {
                    $drivename = "Logs"
                }
            } 
            N {
                Write-Host "Not a database server. No extra drive or MIS-DBA permissions will be assigned." -ForegroundColor Yellow -back black
              } 
            Default {Write-Host "Y/N input not given. Not a database server. No extra drive or MIS-DBA permissions will be assigned." -ForegroundColor Yellow -back black} 
}

Write-host "Is this a server for the apps team?" -ForegroundColor Green -back black
            Write-Host " (y/n) : " -Fore Green -back black -NoNewline
            $Readhost = Read-Host
            Switch ($ReadHost) 
            { 
            Y {
                Write-Host "Apps team server registered. Permissions will be set." -ForegroundColor Yellow -back black
                $appsteam = $true
            } 
            N {
                Write-Host "Not an apps team server. Permissions for MIS-AppAdmin group will not be assigned." -ForegroundColor Yellow -back black
              } 
            Default {Write-Host "Y/N input not given. Not an apps team server. Permissions for MIS-AppAdmin group will not be assigned." -ForegroundColor Yellow -back black} 
}
            

#Create local store for variables
Write-Host "Creating local variable store." -Fore yellow -back black 
if(Test-Path -Path 'c:\ServerSetup\varstor') {
    Get-ChildItem -Path 'c:\ServerSetup\varstor' | Remove-Item
    Remove-Item -Path 'c:\ServerSetup\varstor'
}
if(Test-Path -Path 'c:\ServerSetup\log.txt') {
    Get-Item -Path 'c:\ServerSetup\log.txt' | Remove-Item
}
if(!(Test-Path -Path 'c:\ServerSetup\varstor')) {
    New-Item -ItemType  directory -Path 'c:\ServerSetup\varstor'
}

Start-Transcript -Path 'c:\ServerSetup\log.txt' -append

#Export variables for later use
Write-Host "Exporting variables to local store." -Fore yellow -back black 
$newpassword | Export-Clixml c:\ServerSetup\varstor\newpassword.xml
$newipaddress | Export-Clixml c:\ServerSetup\varstor\newipaddress.clicml
$newipgateway | Export-Clixml c:\ServerSetup\varstor\newipgateway.clicml
$newdns1 | Export-Clixml c:\ServerSetup\varstor\newdns1.clicml
$newdns2 | Export-Clixml c:\ServerSetup\varstor\newdns2.clicml
$newservername | Export-Clixml c:\ServerSetup\varstor\newservername.clicml
$oldgateway | Export-Clixml c:\ServerSetup\varstor\oldgateway.clicml
$targetdc | Export-Clixml c:\ServerSetup\varstor\targetdc.clicml
$appsteam | Export-Clixml c:\ServerSetup\varstor\appsteam.clicml
$databaseserver | Export-Clixml c:\ServerSetup\varstor\databaseserver.clicml
$driveletter | Export-Clixml c:\ServerSetup\varstor\driveletter.clicml
$drivename | Export-Clixml c:\ServerSetup\varstor\drivename.clicml
$logdriveletter | Export-Clixml c:\ServerSetup\varstor\logdriveletter.clicml
$logdrivename | Export-Clixml c:\ServerSetup\varstor\logdrivename.clicml


#add scheduled task2 for next login
Write-Host "Creating scheduled task for next script." -Fore yellow -back black 
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-NonInteractive -NoLogo -File C:\ServerSetup\ServerSetup2.ps1"
$trigger = New-ScheduledTaskTrigger -AtLogOn -RandomDelay 00:00:30
$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
$task | Register-ScheduledTask -TaskName 'ServerSetupStep2'

#Set the pagefile
Write-Host "Setting page file to 150% of available memory." -Fore yellow -back black 
$env:path += ";c:\ServerSetup"
Unblock-File "C:\ServerSetup\AdjustVirtualMemoryPagingFileSize.psm1"
Import-Module "C:\ServerSetup\AdjustVirtualMemoryPagingFileSize.psm1"

$memory = (Get-WMIObject -class Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | %{[Math]::Round(($_.sum / 1MB),2)})
$memory *= 1.5
Set-OSCVirtualMemory -DriveLetter "C:" -InitialSize $memory -MaximumSize $memory -Confirm:$false


#Change local admin password and user, disable guest account
Write-Host "Changing local admin to $localadmin with proper password." -Fore yellow -back black 
if (Get-WmiObject Win32_UserAccount -Filter "LocalAccount='true' and Name ='Administrator'") {
    Set-LocalUser -Name Administrator -Password $newpassword
    Rename-LocalUser -Name Administrator -NewName $localadmin
}

Write-Host "Disabling guest user." -Fore yellow -back black 
Disable-LocalUser -Name Guest

Stop-Transcript

#Restart to apply changes
Write-Host "Rebooting in 15 seconds." -Fore yellow -back black 
Start-Sleep -s 15
Restart-Computer