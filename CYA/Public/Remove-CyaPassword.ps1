function Remove-CyaPassword {
  <#
  .SYNOPSIS
  Deletes CyaPassword.

  .DESCRIPTION
  Deletes the CyaPassword specified by name or supplied through the pipeline.
  If a CyaConfig that makes use of the CyaPassword is found, the processes is
  aborted and an error is displayed.

  .PARAMETER Name
  [String] The name of the CyaPassword

  .OUTPUTS
  [Null]

  .NOTES
    Author: Nick Vissari

  .EXAMPLE
  Remove-CyaPassword Default


  Description
  -----------
  Delete CyaPassword by name.

  .EXAMPLE
  Get-CyaPassword | Remove-CyaPassword


  Description
  -----------
  Delete all CyaPasswords.

  .LINK
  Get-CyaPassword

  .LINK
  New-CyaPassword

  .LINK
  Rename-CyaPassword

  .LINK
  https://github.com/nickadam/powershell-cya

  #>

  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    [String]$Name
  )

  process {

    Get-CyaPassword -Name $Name | Out-Null # will throw

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
        Throw $Message
      }
    }

    $CyaPasswordPath = Get-CyaPasswordPath
    $FilePath = Join-Path -Path $CyaPasswordPath -ChildPath $Name
    Remove-Item $FilePath
  }
}
