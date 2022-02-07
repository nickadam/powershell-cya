function New-CyaConfig {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]
    $Name,

    [ValidateSet("EnvVar", "File")]
    $Type,

    $EnvVarName,
    $EnvVarValue,
    $EnvVarSecureString,
    $EnvVarCollection,

    [Parameter(ValueFromPipeline)]
    $File,

    [ValidateSet($True, $False, 1, 0)]
    $ProtectOnExit,

    $CyaPassword="Default",
    $Password
  )

  begin {
    $Items = @()
  }

  process {
    if($File){
      $Items += $File
    }
  }

  end {
    # Items could be a list of files or environment variables
    if($Items){
      $File = $False
      $EnvVarCollection = @()
      ForEach($Item in $Items){
        if(Get-Item $Item -ErrorAction SilentlyContinue){
          # must be a list of files
          $File = $Items
        }else{
          # must be a list of environment variables
          $ItemEnvVarName = $Item
          $ItemEnvVarValue = Get-EnvVarValueByName -Name $ItemEnvVarName
          if(-not $ItemEnvVarValue){
            $Message = "The piped item `"$ItemEnvVarName`" is not a file or a " +
            "set environment variable and can't be added to a collection."
            Write-Error $Message -ErrorAction Stop
          }
          $EnvVarCollection += [PSCustomObject]@{
            "Name" = $ItemEnvVarName
            "Value" = $ItemEnvVarValue
          }
        }
      }
    }

    if(-not (Get-CyaPassword -Name $CyaPassword -EA SilentlyContinue)){
      Write-Warning "CyaPassword `"$CyaPassword`" password not found, creating now with New-CyaPassword."
      if(!$Password){
        $Password = Get-NewPassword
      }
      New-CyaPassword -Name $CyaPassword -Password $Password
    }

    # Attempt to set $Type
    if($EnvVarName -or $EnvVarCollection){
      $Type = "EnvVar"
    }
    if($File){
      $Type = "File"
    }

    # normalize protect on exit
    if($ProtectOnExit -eq 1){
      $ProtectOnExit = $True
    }
    if($ProtectOnExit -eq 0){
      $ProtectOnExit = $False
    }

    # Show option for type
    if(-not $Type){
      $Options = [System.Management.Automation.Host.ChoiceDescription[]] @("&EnvVar", "&File")
      $Option = $host.UI.PromptForChoice("Config type:", "", $Options, 0)
      Switch($Option){
        0 { $Type = "EnvVar"}
        1 { $Type = "File"}
      }
    }

    $ConfigPath = Join-Path -Path (Get-CyaConfigPath) -ChildPath $Name

    # Check if config already exists
    if(Test-Path $ConfigPath){
      Write-Error -Message "Config `"$Name`" already exists" -ErrorAction Stop
    }

    # Create Environment Variable config
    if($Type -eq "EnvVar"){
      if($EnvVarName -and $EnvVarValue){
        $EnvVarCollection = [PSCustomObject]@{
          "Name" = $EnvVarName
          "Value" = $EnvVarValue
        }
      }
      if($EnvVarName -and $EnvVarSecureString){
        $EnvVarCollection = [PSCustomObject]@{
          "Name" = $EnvVarName
          "Value" = Get-SecureStringText -SecureString $EnvVarSecureString
        }
      }

      # no EnvVar specified, prompt user
      if(-not $EnvVarCollection){
        $Collecting = $True
        $EnvVarCollection = @()
        $n = 0
        while($Collecting){
          $n++
          Write-Host -NoNewline "Variable $n name (Enter when done): "
          $EnvVarName = Read-Host
          if($EnvVarName){
            $SetValue = Get-EnvVarValueByName -Name $EnvVarName
            if($SetValue){
              Write-Host -NoNewline "$EnvVarName value [$SetValue]: "
            }else{
              Write-Host -NoNewline "$EnvVarName value : "
            }
            $EnvVarSecureString = Read-Host -AsSecureString
            $EnvVarValue = Get-SecureStringText -SecureString $EnvVarSecureString
            if($SetValue -and (-not $EnvVarValue)){
              $EnvVarValue = $SetValue
            }
            $EnvVar = [PSCustomObject]@{
              "Name" = $EnvVarName
              "Value" = $EnvVarValue
            }
            $EnvVarCollection += $EnvVar
          }else{
            $Collecting = $False
          }
        }
      }

      # nothing to do
      if(-not $EnvVarCollection){
        return
      }

      if(-not $Password){
        Write-Host -NoNewline "Enter password for CyaPassword `"$CyaPassword`": "
        $Password = Read-Host -AsSecureString
      }
      $Key = Get-Key -CyaPassword $CyaPassword -Password $Password

      # convert hashtable to list of objects
      $EnvVarCollectionList = @()
      if($EnvVarCollection.GetType().Name -eq "Hashtable"){
        $EnvVarCollection.Keys | ForEach {
          $EnvVarName = $_
          $EnvVarValue = $EnvVarCollection.$EnvVarName
          $EnvVarCollectionList += [PSCustomObject]@{
            "Name" = $EnvVarName
            "Value" = $EnvVarValue
          }
        }
        $EnvVarCollection = $EnvVarCollectionList
      }

      $CyaConfigEnvVarCollection = $EnvVarCollection | ConvertTo-Cipherbundle -Key $Key

      if($CyaConfigEnvVarCollection.length -eq 1){
        $CyaConfig = [PSCustomObject]@{
          "Type" = "EnvVar"
          "CyaPassword" = $CyaPassword
          "Variables" = @($CyaConfigEnvVarCollection)
        }
      }else{
        $CyaConfig = [PSCustomObject]@{
          "Type" = "EnvVar"
          "CyaPassword" = $CyaPassword
          "Variables" = $CyaConfigEnvVarCollection
        }
      }

      if(-not (Test-Path (Get-CyaConfigPath))){
        mkdir -p (Get-CyaConfigPath) | Out-Null
      }
    }

    if($Type -eq "File"){
      if($ProtectOnExit -eq $Null){
        $Options = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes", "&No")
        $Message = "Would you like to automatically run Protect-CyaConfig (deletes unencrypted config files) on this config when unloading the Cya module or exiting powershell?"
        $Option = $host.UI.PromptForChoice("Protect on exit:", $Message, $Options, 0)
        Switch($Option){
          0 { $ProtectOnExit = $True}
          1 { $ProtectOnExit = $False}
        }
      }

      # no files specified, prompt user
      if(-not $File){
        $File = @()
        $Collecting = $True
        $n = 0
        while($Collecting){
          $n++
          Write-Host -NoNewline "File $n path (Enter when done): "
          $FilePath = Read-Host
          if($FilePath){
            if(-not (Test-Path $FilePath -PathType Leaf)){
              Write-Error -Message "File $FilePath not found" -ErrorAction Stop
            }
            $File += $FilePath
          }else{
            $Collecting = $False
          }
        }
      }

      # nothing to do
      if(-not $File){
        return
      }

      # Check all files exist
      $File | ForEach {
        $FilePath = $_
        if(-not (Test-Path $FilePath -PathType Leaf)){
          Write-Error -Message "File $FilePath not found" -ErrorAction Stop
        }
      }

      # get the key
      if(-not $Password){
        Write-Host -NoNewline "Enter password for CyaPassword `"$CyaPassword`": "
        $Password = Read-Host -AsSecureString
      }
      $Key = Get-Key -CyaPassword $CyaPassword -Password $Password

      # # encrypt all the files
      $FileCollection = $File | Get-Item | ConvertTo-Cipherbundle -Key $Key

      if($FileCollection.length -eq 1){
        $CyaConfig = [PSCustomObject]@{
          "Type" = "File"
          "CyaPassword" = $CyaPassword
          "ProtectOnExit" = $ProtectOnExit
          "Files" = @($FileCollection)
        }
      }else{
        $CyaConfig = [PSCustomObject]@{
          "Type" = "File"
          "CyaPassword" = $CyaPassword
          "ProtectOnExit" = $ProtectOnExit
          "Files" = $FileCollection
        }
      }
    }

    # nothing to do
    if(-not $CyaConfig){
      return
    }

    # write config file
    $CyaConfig | ConvertTo-Json -Depth 3 | Out-File -Encoding Default $ConfigPath
    Get-CyaConfig -Name $Name
  }
}
