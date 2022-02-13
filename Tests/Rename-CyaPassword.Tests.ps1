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

  # setup cya passwords
  Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter new password" }
  Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Confirm new password" }
  New-CyaPassword -Name "test"
  New-CyaPassword -Name "test2"
  # setup cya configs
  $Env:MYVAR = ""
  Mock Invoke-ChoicePrompt { "EnvVar" } -ParameterFilter { $Caption -eq "Config type" }
  Mock Read-Host {"MYVAR"} -ParameterFilter { $Prompt -eq "Variable 1 name (Enter when done)" }
  Mock Read-Host {ConvertTo-SecureString -String "my value" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "MYVAR value" }
  Mock Read-Host {""} -ParameterFilter { $Prompt -eq "Variable 2 name (Enter when done)" }
  Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter password for CyaPassword `"test`"" }
  New-CyaConfig -Name "test" -CyaPassword "test"
  New-CyaConfig -Name "test2" -CyaPassword "test"
  $ConfigsPath = Join-Path $CYAPATH "configs"
  $PasswordsPath = Join-Path $CYAPATH "passwords"
}

Describe "Rename-CyaPassword" {
  Context "WhatIf switch" {
    BeforeAll {
      Rename-CyaPassword "test" "test3" -WhatIf
      $OldPasswordFile = Test-Path (Join-Path $PasswordsPath "test")
      $NewPasswordFile = Test-Path (Join-Path $PasswordsPath "test3")

    }
    It "Should not remove the old password name" {
      $OldPasswordFile | Should -Be $True
    }
    It "Should not add the new password name" {
      $NewPasswordFile | Should -Be $False
    }
    It "Should not change the CyaPassword in CyaConfigs" {
      (Get-CyaConfig).CyaPassword | Should -Be @("test", "test")
    }
  }

  Context "Conflict" {
    It "Should throw" {
      {Rename-CyaPassword "test" "test2"} | Should -Throw
    }
    It "Should not rename the old password name" {
      $OldPasswordFile = Test-Path (Join-Path $PasswordsPath "test")
      $OldPasswordFile | Should -Be $True
    }
    It "Should not change the CyaPassword in CyaConfigs" {
      (Get-CyaConfig).CyaPassword | Should -Be @("test", "test")
    }
  }

  Context "Position 0 and 1 params" {
    BeforeAll {
      Rename-CyaPassword "test" "test3"
      $OldPasswordFile = Test-Path (Join-Path $PasswordsPath "test")
      $NewPasswordFile = Test-Path (Join-Path $PasswordsPath "test3")
    }
    It "Should remove the old password name" {
      $OldPasswordFile | Should -Be $False
    }
    It "Should add the new password name" {
      $NewPasswordFile | Should -Be $True
    }
    It "Should change the CyaPassword in CyaConfigs" {
      (Get-CyaConfig).CyaPassword | Should -Be @("test3", "test3")
    }
  }
}

AfterAll {
  if(Get-Item $CYAPATH -EA SilentlyContinue){
    Remove-Item $CYAPATH -Force -Recurse
  }
  $Env:CYAPATH = $OriginalCyaPath
}
