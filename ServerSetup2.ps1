##scheduled task 2
Start-Transcript -Path 'c:\ServerSetup\log.txt' -append

"Working on Step 2" | Out-File -FilePath 'c:\Users\Administrator\Desktop\Step 2 is running.txt'

Write-Host "Getting Domain Admin credentials for domain join." -Fore yellow -back black 
$domainadmincred = Get-Credential "DomainAdmin@domain"
$domainadmincred | Export-Clixml c:\ServerSetup\varstor\domainadmincred.xml

#read variables
Write-Host "Reading variables from local store." -Fore yellow -back black 
$newipaddress = Import-Clixml c:\ServerSetup\varstor\newipaddress.clicml
$newipgateway = Import-Clixml c:\ServerSetup\varstor\newipgateway.clicml
$newdns1 = Import-Clixml c:\ServerSetup\varstor\newdns1.clicml
$newdns2 = Import-Clixml c:\ServerSetup\varstor\newdns2.clicml
$newservername = Import-Clixml c:\ServerSetup\varstor\newservername.clicml

#Remove this scheduled task
Write-Host "Unregistering scheduled task." -Fore yellow -back black 
Unregister-ScheduledTask -TaskName 'ServerSetupStep2' -Confirm:$false

#Change IP settings
Write-Host "Setting IP and Network Settings." -Fore yellow -back black 
$adapter = Get-NetAdapter | ? {$_.Name -like "*ethernet*"}
$adapter | Remove-NetIPAddress -Confirm:$false
$oldgateway = Get-NetRoute -DestinationPrefix "0.0.0.0/0"
Remove-NetRoute -ifindex $adapter.ifindex -NextHop $oldgateway.NextHop -Confirm:$false
$adapter | Set-NetIPInterface -Dhcp Disabled
New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $newipaddress -PrefixLength 24 -DefaultGateway $newipgateway
Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("$newdns1","$newdns2")

#Enable SNMP
Write-Host "Ensuring SNMP service is set to automatic." -Fore yellow -back black 
$snmp = Get-Service -Name SNMP
if($snmp.StartType -eq "Disabled") {
    $snmp | Set-Service -StartupType Automatic
    $snmp | Start-Service
}
if($snmp.StartType -eq "Manual") {
    $snmp | Set-Service -StartupType Automatic
    $snmp | Start-Service
}

#add scheduled task 3
Write-Host "Creating scheduled task for next script." -Fore yellow -back black 
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument " -File C:\ServerSetup\ServerSetup3.ps1"
$trigger = New-ScheduledTaskTrigger -AtLogOn -RandomDelay 00:00:30
$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
$task | Register-ScheduledTask -TaskName 'ServerSetupStep3'

#Rename local machine
Write-Host "Setting computer name." -Fore yellow -back black
if ($env:COMPUTERNAME -eq $newservername) {
    Write-Host "The computer name is already set to $newservername" -Fore yellow -back black
} else {
    Rename-Computer -NewName $newservername
} 

Get-Item -Path 'c:\Users\Administrator\Desktop\Step 2 is running.txt' | Remove-Item

Stop-Transcript

Write-Host "Rebooting in 15 seconds." -Fore yellow -back black 
Start-Sleep -s 15
Restart-Computer