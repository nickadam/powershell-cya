function Unprotect-CyaConfig {
  <#
  .SYNOPSIS
  Decrypts files and sets environment variables.

  .DESCRIPTION
  Each item in the CyaConfig is either set as an environment variable or
  decrypted to the filepath defined. If a different file exists at the target
  filepath the process is aborted and an error is presented.

  .PARAMETER Name
  [String] The name of the CyaConfig

  .PARAMETER Password
  [SecureString] The password to decrypt the CyaPassword

  .OUTPUTS
  [Object] CyaConfig item status

  .NOTES
    Author: Nick Vissari

  .EXAMPLE
  Unprotect-CyaConfig
  Enter password for CyaPassword "Default": *********

  Name          : test
  Type          : File
  CyaPassword   : Default
  ProtectOnExit : False
  Item          : C:\Users\nickadam\test.txt
  Status        : Unprotected


  Description
  -----------
  With no parameters specified, all Items in all CyaConfigs are unprotected.

  .EXAMPLE
  Unprotect-CyaConfig test
  Enter password for CyaPassword "Default": *********

  Name          : test
  Type          : File
  CyaPassword   : Default
  ProtectOnExit : False
  Item          : C:\Users\nickadam\test.txt
  Status        : Unprotected


  Description
  -----------
  A specific CyaConfig can be specified by name.

  .LINK
  New-CyaConfig

  .LINK
  Get-CyaConfig

  .LINK
  Protect-CyaConfig

  .LINK
  Rename-CyaConfig

  .LINK
  Remove-CyaConfig

  .LINK
  https://github.com/nickadam/powershell-cya

  #>

  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [String]$Name,

    [SecureString]$Password
  )
  begin {
    $Configs = @()
  }
  process {
    if($Name){
      $Configs += Get-CyaConfig -Name $Name
    }
  }
  end{
    # nothing provided, get all configs
    if(-not $Configs){
      $Configs = Get-CyaConfig
    }

    # nothing to do
    if(-not $Configs){
      Write-Warning "No CyaConfigs specified or found."
      return
    }

    $CyaConfigPath = Get-CyaConfigPath

    # if file exists and protected, stop we have a conflict
    ForEach($Config in $Configs){
      $ConfigPath = Join-Path -Path $CyaConfigPath -ChildPath $Config.Name
      $Config = Get-Item $ConfigPath | Get-Content | ConvertFrom-Json
      if($Config.Type -eq "File"){
        ForEach($Cipherbundle in $Config.Files){
          $FilePath = $Cipherbundle.FilePath
          if(Test-Path $FilePath){
            $ProtectionStatus = $Cipherbundle | Get-ProtectionStatus
            if($ProtectionStatus.Status -eq "Protected"){
              $Message = "Conflicting file `"$FilePath`" exists. " +
                "The file may have been overwritten or modified since it was " +
                "unprotected. Delete or rename the file to resolve the conflict."
              Throw $Message
            }
          }
        }
      }
    }

    # Get all keys
    $CyaPasswords = ($Configs.CyaPassword | Group-Object).Name
    $Keys = @{}
    ForEach($CyaPassword in $CyaPasswords){
      if(-not $Password){
        $Password = Read-Host -Prompt "Enter password for CyaPassword `"$CyaPassword`"" -AsSecureString
      }
      $Key = Get-Key -CyaPassword $CyaPassword -Password $Password -ErrorAction Stop
      $Keys[$CyaPassword] = $Key
    }

    # change the environment!
    ForEach($Config in $Configs){
      $ConfigPath = Join-Path -Path $CyaConfigPath -ChildPath $Config.Name
      $Config = Get-Item $ConfigPath | Get-Content | ConvertFrom-Json
      if($Config.Type -eq "File"){
        ForEach($Cipherbundle in $Config.Files){
          $FilePath = $Cipherbundle.FilePath

          # already there
          if(Test-Path $FilePath){
            Continue
          }

          # make directory
          $Directory = Split-Path $FilePath
          if(-not (Test-Path $Directory)){
            mkdir -p $Directory | Out-Null
          }

          # write file
          $Cipherbundle | ConvertFrom-Cipherbundle -Key $Keys[$Config.CyaPassword] | Out-Null
        }
      }

      # set environment variables
      if($Config.Type -eq "EnvVar"){
        $Config.Variables | ConvertFrom-Cipherbundle -Key $Keys[$Config.CyaPassword] | Out-Null
      }
    }

    # Show protection status
    ForEach($Config in $Configs){
      Get-CyaConfig -Name $Config.Name -Status
    }
  }
}
