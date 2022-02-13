BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")
  $PublicDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Public")

  # import all private and public scripts
  $Items = Get-ChildItem -Path (Join-Path $PrivateDirectory "*.ps1")
  $Items += Get-ChildItem -Path (Join-Path $PublicDirectory "*.ps1")
  $Items | ForEach-Object {
    try {
      . $_.FullName
    } catch {
      $FullName = $_.FullName
      Write-Error -Message "Failed to import $_"
    }
  }

  $OriginalCyaPath = $Env:CYAPATH
  $TmpFile = New-TemporaryFile
  Remove-Item $TmpFile
  mkdir $TmpFile
  $Env:CYAPATH = $TmpFile
  $CYAPATH = $Env:CYAPATH

  $WarningPreference='SilentlyContinue'

  # setup cya profile
  $Env:MYVAR = ""
  $Env:MYOTHERVAR = "my other value"
  Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter new password" }
  Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Confirm new password" }
  Mock Invoke-ChoicePrompt { "EnvVar" } -ParameterFilter { $Caption -eq "Config type" }
  Mock Read-Host {"MYVAR"} -ParameterFilter { $Prompt -eq "Variable 1 name (Enter when done)" }
  Mock Read-Host {ConvertTo-SecureString -String "my value" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "MYVAR value" }
  Mock Read-Host {"MYOTHERVAR"} -ParameterFilter { $Prompt -eq "Variable 2 name (Enter when done)" }
  Mock Read-Host {New-Object System.Security.SecureString} -ParameterFilter { $Prompt -eq "MYOTHERVAR value [my other value]" }
  Mock Read-Host {""} -ParameterFilter { $Prompt -eq "Variable 3 name (Enter when done)" }
  $Status = New-CyaConfig -Name "test"
  $TmpFile1 = New-TemporaryFile
  $TmpFile1Path = $TmpFile1.ToString()
  Get-RandomString | Out-File -Encoding Default -NoNewline $TmpFile1
  $TmpFile2 = New-TemporaryFile
  $TmpFile2Path = $TmpFile2.ToString()
  Get-RandomString | Out-File -Encoding Default -NoNewline $TmpFile2
  $OriginalPwd = pwd
  cd (Split-Path $TmpFile2)
  Mock Invoke-ChoicePrompt { "File" } -ParameterFilter { $Caption -eq "Config type" }
  Mock Invoke-ChoicePrompt { "" } -ParameterFilter { $Caption -eq "Protect on exit" }
  Mock Read-Host {$TmpFile1} -ParameterFilter { $Prompt -eq "File 1 path (Enter when done)" }
  Mock Read-Host {Split-Path $TmpFile2 -Leaf} -ParameterFilter { $Prompt -eq "File 2 path (Enter when done)" }
  Mock Read-Host {""} -ParameterFilter { $Prompt -eq "File 3 path (Enter when done)" }
  Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter password for CyaPassword `"Default`"" }
  $Status = New-CyaConfig -Name "test2"
  cd $OriginalPwd
  Remove-Item $TmpFile2
  $ConfigsPath = Join-Path $CYAPATH "configs"
  $BinsPath = Join-Path $CYAPATH "bins"
}

Describe "Remove-CyaConfig" {
  Context "WhatIf switch" {
    BeforeAll {
      Remove-CyaConfig test2 -WhatIf
      $ConfigFile = Test-Path (Join-Path $ConfigsPath "test2")
      $Bin1File = Test-Path (Join-Path $BinsPath "test2.0")
      $Bin2File = Test-Path (Join-Path $BinsPath "test2.1")
    }
    It "Should not remove the config file" {
      $ConfigFile | Should -Be $True
    }
    It "Should not remove the test2.0 bin file" {
      $Bin1File | Should -Be $True
    }
    It "Should remove the test2.1 bin file" {
      $Bin2File | Should -Be $True
    }
  }

  Context "Name param" {
    BeforeAll {
      Remove-CyaConfig test2
      $ConfigFile = Test-Path (Join-Path $ConfigsPath "test2")
      $Bin1File = Test-Path (Join-Path $BinsPath "test2.0")
      $Bin2File = Test-Path (Join-Path $BinsPath "test2.1")
    }
    It "Should not remove the config file" {
      $ConfigFile | Should -Be $False
    }
    It "Should not remove the test2.0 bin file" {
      $Bin1File | Should -Be $False
    }
    It "Should remove the test2.1 bin file" {
      $Bin2File | Should -Be $False
    }
  }

  Context "CyaConfigs pipeline WhatIf switch" {
    BeforeAll {
      Get-CyaConfig | Remove-CyaConfig -WhatIf
      $ConfigFile = Test-Path (Join-Path $ConfigsPath "test")
    }
    It "Should not remove the config file" {
      $ConfigFile | Should -Be $True
    }
  }

  Context "CyaConfigs pipeline" {
    BeforeAll {
      Get-CyaConfig | Remove-CyaConfig
      $ConfigFile = Test-Path (Join-Path $ConfigsPath "test")
    }
    It "Should not remove the config file" {
      $ConfigFile | Should -Be $False
    }
  }
}

AfterAll {
  if(Get-Item $CYAPATH -EA SilentlyContinue){
    Remove-Item $CYAPATH -Force -Recurse
  }
  $Env:CYAPATH = $OriginalCyaPath
}
