function Remove-CyaPassword {
  [CmdletBinding(SupportsShouldProcess,
  DefaultParameterSetName = "FromPipeline")]
  param(
    [Parameter(Mandatory,
    ParameterSetName="FromName")]
    [String]$Name,

    [Parameter(Mandatory,
    ValueFromPipeline,
    DontShow,
    ParameterSetName="FromPipeline")]
    [Object]$InputObject
  )

  process {
    $PasswordName = $Name
    if(-not $Name -and $InputObject){
      $PasswordName = $InputObject.Name
    }

    Get-CyaPassword -Name $PasswordName | Out-Null # will throw

    # Check if any configs still use the password
    $StillInUse = @()
    $CyaConfigPath = Get-CyaConfigPath
    if(Test-Path $CyaConfigPath){
      ForEach($File in (Get-ChildItem $CyaConfigPath)){
        $CyaConfig = $File | Get-Content | ConvertFrom-Json
        if($CyaConfig.CyaPassword -eq $PasswordName){
          $StillInUse += Get-CyaConfig -Name $File.Name
        }
      }
      if($StillInUse){
        $StillInUse
        $Message = "The CyaConfigs above are still using this password. " +
          "To delete the CyaPassword you must first run Remove-CyaConfig"
        Throw $Message
      }
    }

    $CyaPasswordPath = Get-CyaPasswordPath
    $FilePath = Join-Path -Path $CyaPasswordPath -ChildPath $PasswordName
    Remove-Item $FilePath
  }
}
