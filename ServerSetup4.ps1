##Scheduled Task 4
Start-Transcript -Path 'c:\ServerSetup\log.txt' -append

#Read Variables
Write-Host "Reading variables from local store." -Fore yellow -back black 
$targetdc = Import-Clixml c:\ServerSetup\varstor\targetdc.clicml
$domainadmincred = Import-Clixml c:\ServerSetup\varstor\domainadmincred.xml
$databaseserver = Import-Clixml c:\ServerSetup\varstor\databaseserver.clicml
$appsteam = Import-Clixml c:\ServerSetup\varstor\appsteam.clicml
$driveletter = Import-Clixml c:\ServerSetup\varstor\driveletter.clicml
$drivename = Import-Clixml c:\ServerSetup\varstor\drivename.clicml
$logdriveletter = Import-Clixml c:\ServerSetup\varstor\logdriveletter.clicml
$logdrivename = Import-Clixml c:\ServerSetup\varstor\logdrivename.clicml
$computer = $env:computername

#Move computer object
Write-Host "Moving computer object to Production Servers OU." -Fore yellow -back black 
Invoke-Command -ComputerName $targetdc -ArgumentList $computer -Credential $domainadmincred -ScriptBlock {
    param($computer)
    Get-ADComputer -Filter {Name -eq $computer} | Move-ADObject -TargetPath "OU=Production,OU=Servers,DC=COG,DC=COGGOV,DC=LOCAL" -Confirm:$false
    }

#Create folder in NETDOC
Write-Host "Checking for Netdoc folder." -Fore yellow -back black
Invoke-Command -ComputerName $targetdc -Credential $domainadmincred -ScriptBlock { 
        if(!(Test-Path -Path "\\Documentation Root Share\Server Documentation\$args\")) {
            Write-host "Netdoc does not exist, creating folder." -ForegroundColor Yellow -back black
            New-Item -ItemType Directory -Path "\\Documentation Root Share\Server Documentation\$args" -Force
        } 
    } -ArgumentList $computer

#Copy log.txt to netdoc
Invoke-Command -ComputerName $targetdc -ArgumentList $computer -Credential $domainadmincred -ScriptBlock {
        param($computer)
        Copy-Item -Path "\\$computer\c$\ServerSetup\log.txt" -Destination "\\Documentation Root Share\Server Documentation\$computer\ServerSetupLog.txt"
    }

if ($appsteam) {
    Write-Host "Adding MIS-AppsTeam to Power Users and Remote Desktop Users." -Fore Yellow -back black

    net localgroup "Power Users" cog\MIS-AppAdmin /ADD
    net localgroup "Remote Desktop Users" cog\MIS-AppAdmin /ADD

    Write-Host "Changing access permissions on E drive." -Fore Yellow -back black

    $acl = Get-Acl "E:\"
    $ar = New-Object System.Security.AccessControl.FileSystemAccessRule("domain\apps admins","modify","ContainerInherit,ObjectInherit","None","allow")
    $acl.SetAccessRule($ar)
    Set-Acl "E:\" $acl

}

if ($databaseserver) {
    Write-Host "Creating $driveletter $drivename." -Fore Yellow -back black
    Get-Disk | Where PartitionStyle -eq 'RAW' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter $driveletter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$drivename" -Confirm:$false

    Write-Host "Creating $logdriveletter $logdrivename." -Fore Yellow -back black
    Get-Disk | Where PartitionStyle -eq 'RAW' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter $logdriveletter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$logdrivename" -Confirm:$false

    Write-Host "Adding MIS-DBA to Local Administrators." -Fore Yellow -back black

    net localgroup administrators cog\MIS-DBA /ADD
    net localgroup "Remote Desktop Users" cog\MIS-DBA /ADD
}

"Success! Log file located in C:\ServerSetup\log.txt" | Out-File -FilePath 'c:\Users\Administrator\Desktop\Success.txt'
Write-Host "Success! Log file located in C:\ServerSetup\log.txt" -Fore green -back black 

if(Test-Path -Path 'c:\Users\Administrator\Desktop\Finish.lnk') {
    Get-Item -Path 'c:\Users\Administrator\Desktop\Finish.lnk' | Remove-Item
}

#cleanup varstor and scheduled task
Write-Host "Cleaning up local variable store." -Fore yellow -back black 
if(Test-Path -Path 'c:\ServerSetup\varstor') {
    Get-ChildItem -Path 'c:\ServerSetup\varstor' | Remove-Item
    Remove-Item -Path 'c:\ServerSetup\varstor'
}

"Success! Log file located in C:\ServerSetup\log.txt" | Out-File -FilePath 'c:\Users\Administrator\Desktop\Dont Forget CommVault.txt'

"Success! Log file located in C:\ServerSetup\log.txt" | Out-File -FilePath 'c:\Users\Administrator\Desktop\And SCCM Client.txt'

"Success! Log file located in C:\ServerSetup\log.txt" | Out-File -FilePath 'c:\Users\Administrator\Desktop\And Download Updates.txt'

Write-Host "Script will close in 15 seconds." -Fore green -back black
Start-Sleep -s 15

Stop-Transcript