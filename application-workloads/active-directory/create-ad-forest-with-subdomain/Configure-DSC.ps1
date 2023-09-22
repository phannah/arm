#Requires -Version 5
#
# set policy for the whole system.
#
Set-ExecutionPolicy Unrestricted -Force

#
# Install required DSC modules before we get started. 
#
Install-PackageProvider -Name NuGet -Force
Install-Module -Name ComputerManagementDSC -Force
Install-Module -Name xActiveDirectory -Force
Install-Module -Name xNetworking -Force
Install-Module -Name xStorage -Force

#
# Server 2016 and later default to a very small swapfile on D, so small that the DSC modules
# cause out of memory errors. This code will reconfigure a static but sufficient swap file.
#
$swapDiskSize = (get-partition -DriveLetter D).Size
Write-Verbose ("Size of partition D (containing pagefile): {0:f2} GB" -f ($swapDiskSize / 1GB))

$physicalMemory = (Get-WmiObject -class "cim_physicalmemory" | Measure-Object -Property Capacity -Sum).Sum
Write-Verbose ("Size of Physical memory                  : {0:f2} GB" -f ($physicalMemory / 1GB))

$newSwapDiskSize = [math]::min($swapDiskSize * 0.8, $physicalMemory + 10Mb)
Write-Verbose ("New swapfile for D, size                 : {0:f2} GB" -f ($newSwapDiskSize / 1GB))

$swapSizeMB = [math]::Round($newSwapDiskSize / 100Mb) * 100Mb / 1MB
Write-Verbose ("New rounded swapfile in MB for D, size   : {0:f0} MB" -f ($swapSizeMB))

#
# clear all pagefile settings, set to manual, and configure the swapfile for d
#
Write-Verbose "Initial settings for the swapfile(s)"
wmic pagefile list /format:list

Write-Verbose "Removing swapfile settings"
wmic pagefileset delete

Write-Verbose "Converting all to manually managed"
wmic computersystem set AutomaticManagedPagefile=False

Write-Verbose "Configuring swapfile for D:"
& 'wmic' 'pagefileset' 'create' "name=`"d:\pagefile.sys`",InitialSize=2048,MaximumSize=$swapSizeMB"

Write-Verbose "Post settings for the swapfile(s)"
wmic pagefile list /format:list

Write-Verbose "Settings will be effective after the next reboot."

Write-Verbose -Message ("Installing KACE agent")
Write-Verbose -Message ("Installing KACE agent")
$toolsFolder = "c:\OdradTools"

if (!(Test-Path $toolsFolder -PathType Container)) {
	New-Item -ItemType Directory -Force -Path $toolsFolder
}

$fileName = $toolsFolder + "\KACEInstall.ps1"
$updatedFileName = $toolsFolder + "\UpdatedKACEInstall.ps1"
   
Invoke-WebRequest -Uri "https://isops-static.quest.com/downloads/quest/kace/smaagent/win/Install_KSMAAgent_Lab.ps1.txt" -OutFile $fileName

Get-content $fileName | % {$_ -replace "Clear-Host",""} | Out-File $updatedFileName
& $updatedFileName     


New-Item C:\questowner.txt
Set-Content C:\questowner.txt 'peter.hannah@quest.com'
     

#
# required to satisfy the Travis CI QA check at Quicktemplates
#
exit 0
