Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
trap {
    Write-Host
    Write-Host 'ERROR: $_'
    Write-Host (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Write-Host (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1')
    Write-Host
    Write-Host 'Sleeping for 60m to give you time to look around the virtual machine before self-destruction...'
    Start-Sleep -Seconds (60*60)
    Exit 1
}

$hostName = "MetaTrader"

Write-Host "###################################################################"
Write-Host "Enable auto login vagrant user"
Write-Host "###################################################################"
$logonPath = 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty -Path $logonPath -Name AutoAdminLogon -Value 1
Set-ItemProperty -Path $logonPath -Name DefaultDomainName -Value $hostName
Set-ItemProperty -Path $logonPath -Name DefaultUserName -Value vagrant
Set-ItemProperty -Path $logonPath -Name DefaultPassword -Value vagrant

Write-Host "###################################################################"
Write-Host "Always show file extensions"
Write-Host "###################################################################"
Set-ItemProperty `
    -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
    -Name 'HideFileExt' `
    -Value 0

Write-Host "###################################################################"
Write-Host "Enable audio service"
Write-Host "###################################################################"
Get-Service | Where {$_.Name -match "audio"} | format-table -autosize
Get-Service | Where {$_.Name -match "audio"} | start-service
Get-Service | Where {$_.Name -match "audio"} | set-service -StartupType "Automatic"
# Validate our startup changes (Should say- StartMode:Auto)
Get-WmiObject -class win32_service -filter "Name='AudioSrv'"

Set-TimeZone -Name "Central Standard Time"

$ScriptPath = Split-Path $MyInvocation.InvocationName

# Write-Host "###################################################################"
# Write-Host 'Install MetaTrader 4 (forexcom)'
# Write-Host "###################################################################"
# Start-Process -ArgumentList '/auto' -FilePath "$ScriptPath\forexcom4setup.exe" -Wait
# $installDir = "C:/Program Files (x86)/FOREX.com US"

# Write-Host "###################################################################"
# Write-Host 'Install MetaTrader 4 (ig)'
# Write-Host "###################################################################"
# Start-Process -ArgumentList '/auto' -FilePath "$ScriptPath\ig4setup.exe" -Wait
# $installDir = "C:/Program Files (x86)/IG Metatrader 4 Terminal"

# Write-Host "###################################################################"
# Write-Host 'Install MetaTrader 4 (oanda)'
# Write-Host "###################################################################"
# Start-Process -ArgumentList '/auto' -FilePath "$ScriptPath\oanda4setup.exe" -Wait
# $installDir = 'C:/Program Files (x86)/OANDA - Metatrader'

# # start the MetaTrader 4 (oanda) terminal to generate the default MQL5 folders
# Start-Process -FilePath "$installDir/terminal.exe"
# Start-Sleep -Seconds 60 # pause a minute to let applications launch

# # mt4setup downloaded from metatrader official actually installs mt5
# Write-Host "###################################################################"
# Write-Host 'Install MetaTrader 4'
# Write-Host "###################################################################"
# Start-Process -ArgumentList '/auto' -FilePath "$ScriptPath\mt4setup.exe" -Wait
# $installDir = "C:/Program Files/Metatrader"

# # start the MetaTrader 5 terminal to generate the default MQL5 folders
# Start-Process -FilePath "$installDir/terminal.exe"
# Start-Sleep -Seconds 60 # pause a minute to let applications launch

# Define a list of MetaTrader Terminals to install
$terminals = @('Oanda Demo','Oanda Live')

for ($t=0; $t -lt $terminals.length; $t++) {
  $terminal = $terminals[$t]
  $ogAppName = "OANDA - MetaTrader"
  $appName = "MT4 - $terminal"
  $installDir = "C:/Program Files (x86)"

  Write-Host "###################################################################"
  Write-Host "Install $appName"
  Write-Host "###################################################################"
  Start-Process -ArgumentList '/auto' -FilePath "$ScriptPath\oanda4setup.exe" -Wait

  # remove default desktop shortcut
  Remove-Item -Path "C:/Users/*/Desktop/$ogAppName.lnk"
  Remove-Item -Path "C:/Users/*/Desktop/MetaEditor 4.lnk"

  # remove default start menu shortcuts
  Remove-Item -Path "$Env:ProgramData/Microsoft/Windows/Start Menu/Programs/$ogAppName" -Recurse

  # rename /auto install to new install
  Rename-Item -Path "$installDir/$ogAppName" -NewName $appName

  # create new desktop shortcut
  $WshShell = New-Object -comObject WScript.Shell
  $Shortcut = $WshShell.CreateShortcut("$Home/Desktop/$terminal.lnk")
  $Shortcut.TargetPath = "$installDir/$appName/terminal.exe"
  $Shortcut.Save()

  # link MQL4 directory into $dataDir
  New-Item -ItemType Junction -Path "$installDir/$appName/MQL4" -Value "$Home/MQL4"
  # link mt4config folders into $dataDir
  $dirs = @('config','profiles','templates')
  for ($i=0; $i -lt $dirs.length; $i++) {
    $dir = $dirs[$i]
    $localPath = "$installDir/$appName/$dir"
    If (test-path $localPath){
      Rename-Item -path $localpath -newName "$localPath-og"
    }
    New-Item -ItemType SymbolicLink -Path $localPath -Target "C:/Users/vagrant/mt4config/$dir/"
  }
}

# remove user start menu shortcuts
Remove-Item -Path "$Env:APPDATA/Microsoft/Windows/Start Menu/Programs/Oracle VM VirtualBox guest Additions" -Recurse

Write-Host "###################################################################"
Write-Host "Rename host and restart"
Write-Host "###################################################################"
Rename-Computer -NewName $hostName -Force
Start-Process `
  -ArgumentList '/c "timeout /t 3 /nobreak && shutdown -r -f -t 0"' `
  -FilePath "cmd.exe" `
  -WindowStyle Hidden

Exit 0
