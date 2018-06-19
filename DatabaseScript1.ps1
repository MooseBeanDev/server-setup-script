# Write to console and get the user input for the AD Username
Write-Host "........................................." -Fore yellow -back black 
Write-host "..........DatabaseScript1.ps1............" -fore yellow -back black 
Write-Host "........................................." -Fore yellow -back black 
Write-Host ""

Get-Disk

Write-Host ""
Write-Host "Please enter the desired database drive letter: " -NoNewline -Fore Green -back black
$dbdriveletter = Read-Host

Write-Host "Please enter the desired database drive name: " -NoNewline -Fore Green -back black
$dbdrivename = Read-Host

Write-Host ""
Write-Host "Please enter the desired log drive letter: " -NoNewline -Fore Green -back black
$logdriveletter = Read-Host

Write-Host "Please enter the desired log drive name: " -NoNewline -Fore Green -back black
$logdrivename = Read-Host

Write-Host "Creating $dbdriveletter $dbdrivename." -NoNewline -Fore Yellow -back black
Get-Disk | Where PartitionStyle -eq 'RAW' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter $dbdriveletter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$dbdrivename" -Confirm:$false

Write-Host "Creating $logdriveletter $logdrivename." -NoNewline -Fore Yellow -back black
Get-Disk | Where PartitionStyle -eq 'RAW' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter $logdriveletter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$logdrivename" -Confirm:$false

Write-Host "Adding MIS-DBA to Local Administrators." -NoNewline -Fore Green -back black
$computername = $env:COMPUTERNAME
$domaingroup = "DB Admins Group"
$localgroup = "Administrators"
$domainname = "XXX"

([ADSI]"WinNT://$computername/$localgroup,group").psbase.Invoke("Add",([ADSI]"WinNT://$domainname/$domaingroup").path)
