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
  Mock Invoke-ChoicePrompt { "EnvVar" } -ParameterFilter { $Caption -eq "Config type" }
  Mock Read-Host {"MYVAR"} -ParameterFilter { $Prompt -eq "Variable 1 name (Enter when done)" }
  Mock Read-Host {ConvertTo-SecureString -String "my value" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "MYVAR value" }
  Mock Read-Host {""} -ParameterFilter { $Prompt -eq "Variable 2 name (Enter when done)" }
  Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter password for CyaPassword `"test`"" }
  $PasswordsPath = Join-Path $CYAPATH "passwords"
}

Describe "Remove-CyaPassword" {
  Context "WhatIf switch with config" {
    BeforeAll {
      New-CyaConfig test -CyaPassword test
    }
    It "Should throw" {
      { Remove-CyaPassword test -WhatIf } | Should -Throw
    }
    AfterAll {
      Get-CyaConfig | Remove-CyaConfig
    }
  }

  Context "WhatIf switch" {
    BeforeAll {
      Remove-CyaPassword test -WhatIf
      $PasswordFile = Test-Path (Join-Path $PasswordsPath "test")
    }
    It "Should not remove the password file" {
      $PasswordFile | Should -Be $True
    }
  }

  Context "CyaPasswords pipeline" {
    BeforeAll {
      Get-CyaPassword | Remove-CyaPassword
      $PasswordFile = Test-Path (Join-Path $PasswordsPath "test")
      $Password2File = Test-Path (Join-Path $PasswordsPath "test2")
    }
    It "Should remove the password file" {
      $PasswordFile | Should -Be $False
    }
    It "Should remove the password2 file" {
      $Password2File | Should -Be $False
    }
  }
}

AfterAll {
  if(Get-Item $CYAPATH -EA SilentlyContinue){
    Remove-Item $CYAPATH -Force -Recurse
  }
  $Env:CYAPATH = $OriginalCyaPath
}
