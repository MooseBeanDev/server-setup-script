##scheduled task 3
Start-Transcript -Path 'c:\ServerSetup\log.txt' -append

"Working on Step 3" | Out-File -FilePath 'c:\Users\Administrator\Desktop\Step 3 is running.txt'

#Read variables
Write-Host "Reading variables from local store." -Fore yellow -back black 
$targetdc = Import-Clixml c:\ServerSetup\varstor\targetdc.clicml
$domainadmincred = Import-Clixml c:\ServerSetup\varstor\domainadmincred.xml

#Add Computer to Domain
Write-Host "Adding computer to domain." -Fore yellow -back black 
Add-Computer -DomainName cog.coggov.local -Credential $domainadmincred -Force -Confirm:$false

#Remove this scheduled task
Write-Host "Unregistering scheduled task." -Fore yellow -back black 
Unregister-ScheduledTask -TaskName 'ServerSetupStep3' -Confirm:$false

#add shortcut task 4
Write-Host "Adding shortcut for final step to desktop." -Fore yellow -back black 
$TargetFile = "C:\ServerSetup\ServerSetup4.ps1"
$ShortcutFile = "C:\Users\Administrator\Desktop\Finish.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

Get-Item -Path 'c:\Users\Administrator\Desktop\Step 3 is running.txt' | Remove-Item

Stop-Transcript

Write-Host "Rebooting in 15 seconds." -Fore yellow -back black 
Start-Sleep -s 15
Restart-Computer