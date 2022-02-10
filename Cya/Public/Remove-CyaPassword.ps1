function Remove-CyaPassword {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory=$true)]
    $Name
  )

  Get-CyaPassword -Name $Name -ErrorAction Stop | Out-Null

  # Check if any configs still use the password
  $StillInUse = @()
  $CyaConfigPath = Get-CyaConfigPath
  if(Test-Path $CyaConfigPath){
    ForEach($File in (Get-ChildItem $CyaConfigPath)){
      $CyaConfig = $File | Get-Content | ConvertFrom-Json
      if($CyaConfig.CyaPassword -eq $Name){
        $StillInUse += Get-CyaConfig -Name $File.Name
      }
    }
    if($StillInUse){
      $StillInUse
      $Message = "The CyaConfigs above are still using this password. " +
        "To delete the CyaPassword you must first run Remove-CyaConfig"
      Write-Error $Message -ErrorAction Stop
    }
  }

  $CyaPasswordPath = Get-CyaPasswordPath
  $FilePath = Join-Path -Path $CyaPasswordPath -ChildPath $Name
  Remove-Item $FilePath
}
