function New-CyaConfig {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]
    [String]$Name,

    [ValidateSet("EnvVar", "File")]
    [String]$Type,

    [String]$EnvVarName,
    [String]$EnvVarValue,
    [SecureString]$EnvVarSecureString,
    [Object]$EnvVarCollection,

    [Parameter(ValueFromPipeline)]
    [Object]$File,

    [ValidateSet(0, 1)]
    [Int]$ProtectOnExit = -1,

    [String]$CyaPassword="Default",
    [SecureString]$Password
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

    # Show option for type
    if(-not $Type){
      $Options = [System.Management.Automation.Host.ChoiceDescription[]] @("&EnvVar", "&File")
      $Option = $host.UI.PromptForChoice("Config type:", "", $Options, 0)
      Switch($Option){
        0 { $Type = "EnvVar"}
        1 { $Type = "File"}
      }
    }

    $CyaConfigPath = Get-CyaConfigPath
    $ConfigPath = Join-Path -Path $CyaConfigPath -ChildPath $Name

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
        Write-Warning "Nothing to do"
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

      $Cipherbundle = $EnvVarCollection | ConvertTo-Cipherbundle -Key $Key -Name $Name

      if($Cipherbundle.length -eq 1){
        $CyaConfig = [PSCustomObject]@{
          "Type" = "EnvVar"
          "CyaPassword" = $CyaPassword
          "Variables" = @($Cipherbundle)
        }
      }else{
        $CyaConfig = [PSCustomObject]@{
          "Type" = "EnvVar"
          "CyaPassword" = $CyaPassword
          "Variables" = $Cipherbundle
        }
      }

      if(-not (Test-Path $CyaConfigPath)){
        mkdir -p $CyaConfigPath | Out-Null
      }
    }

    if($Type -eq "File"){
      if($ProtectOnExit -eq -1){
        $Options = [System.Management.Automation.Host.ChoiceDescription[]] @("&No", "&Yes")
        $Message = "Would you like to automatically run Protect-CyaConfig (deletes unencrypted config files) on this config when unloading the Cya module or exiting powershell?"
        $Option = $host.UI.PromptForChoice("Protect on exit:", $Message, $Options, 1)
        Switch($Option){
          0 { $ProtectOnExit = 0}
          1 { $ProtectOnExit = 1}
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
        Write-Warning "Nothing to do"
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
      $FileCollection = $File | Get-Item | ConvertTo-Cipherbundle -Key $Key -Name $Name

      if($FileCollection.length -eq 1){
        $CyaConfig = [PSCustomObject]@{
          "Type" = "File"
          "CyaPassword" = $CyaPassword
          "ProtectOnExit" = [Bool]$ProtectOnExit
          "Files" = @($FileCollection)
        }
      }else{
        $CyaConfig = [PSCustomObject]@{
          "Type" = "File"
          "CyaPassword" = $CyaPassword
          "ProtectOnExit" = [Bool]$ProtectOnExit
          "Files" = $FileCollection
        }
      }
    }

    # nothing to do
    if(-not $CyaConfig){
      Write-Warning "Nothing to do"
      return
    }

    # write config file
    $CyaConfig | ConvertTo-Json | Out-File -Encoding Default $ConfigPath
    Get-CyaConfig -Name $Name -Status
  }
}
