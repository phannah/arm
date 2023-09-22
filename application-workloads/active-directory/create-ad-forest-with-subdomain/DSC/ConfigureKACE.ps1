configuration ConfigureKACE
{
   param
    (
        [Parameter(Mandatory)]
        [String]$AgentAzureDownloadPath
    )

    Node localhost
    {
        Script ExecuteInstallKACEAgentForAzure 
        {
          SetScript = 
          {
	
	try
	{
              Write-Verbose -Message ("Installing KACE agent")
	      $toolsFolder = "c:\OdradTools"

		if (!(Test-Path $toolsFolder -PathType Container)) {
		    New-Item -ItemType Directory -Force -Path $toolsFolder
		}

              $fileName = $toolsFolder + "\KACEInstall.ps1"
              $updatedFileName = $toolsFolder + "\UpdatedKACEInstall.ps1"
   
              Invoke-WebRequest -Uri "$($AgentAzureDownloadPath)" -OutFile $fileName
              Get-content $fileName | % {$_ -replace "Clear-Host",""} | Out-File $updatedFileName
              & $updatedFileName          
	}
	catch
	{
		throw "error From Script: $AgentAzureDownloadPath" + $_.Exception
	}

          }
       
          TestScript = 
          {
              Write-Verbose -Message ("Installing KACE agent - TestScript")           
              if (Test-Path "C:\Program Files (x86)\Quest\KACE")
              {
                  Write-Verbose -Message ("KACE already installed")
                  return $true
              }
              else
              {
                  Write-Verbose -Message ("KACE agent to be installed")
                  return $false
              }
          }
        
          GetScript = 
          {
              Write-Verbose -Message ("Installing KACE agent - GetScript")
          }
        }   
        
    }
}
