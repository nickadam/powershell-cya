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
  Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter new password" }
  Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Confirm new password" }
  Mock Invoke-ChoicePrompt { "EnvVar" } -ParameterFilter { $Caption -eq "Config type" }
  Mock Read-Host {"MYVAR"} -ParameterFilter { $Prompt -eq "Variable 1 name (Enter when done)" }
  Mock Read-Host {ConvertTo-SecureString -String "my value" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "MYVAR value" }
  Mock Read-Host {""} -ParameterFilter { $Prompt -eq "Variable 2 name (Enter when done)" }
  New-CyaConfig -Name "test" | Out-Null
  $TmpFile1 = New-TemporaryFile
  $TmpFile1Path = $TmpFile1.ToString()
  Get-RandomString | Out-File -Encoding Default -NoNewline $TmpFile1
  Mock Invoke-ChoicePrompt { "File" } -ParameterFilter { $Caption -eq "Config type" }
  Mock Invoke-ChoicePrompt { "" } -ParameterFilter { $Caption -eq "Protect on exit" }
  Mock Read-Host {$TmpFile1} -ParameterFilter { $Prompt -eq "File 1 path (Enter when done)" }
  Mock Read-Host {""} -ParameterFilter { $Prompt -eq "File 2 path (Enter when done)" }
  Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter password for CyaPassword `"Default`"" }
  New-CyaConfig -Name "test2" | Out-Null
  Protect-CyaConfig
  $ConfigsPath = Join-Path $CYAPATH "configs"
}

Describe "Get-ProtectionStatus" {
  Context "Unprotected EnvVar" {
    BeforeAll {
      Get-CyaConfig test | Unprotect-CyaConfig
      $Cipherbundle = (Get-Content (Join-Path $ConfigsPath "test") | ConvertFrom-Json).Variables
      $result = $Cipherbundle | Get-ProtectionStatus
    }
    It "Should return status Unprotected" {
      $result.Status | Should -Be "Unprotected"
    }
    AfterAll {
      Protect-CyaConfig
    }
  }

  Context "Protected EnvVar" {
    BeforeAll {
      $Cipherbundle = (Get-Content (Join-Path $ConfigsPath "test") | ConvertFrom-Json).Variables
      $result = $Cipherbundle | Get-ProtectionStatus
    }
    It "Should return status Protected" {
      $result.Status | Should -Be "Protected"
    }
  }

  Context "Conflicting EnvVar" {
    BeforeAll {
      $Env:MYVAR = "not my value"
      $Cipherbundle = (Get-Content (Join-Path $ConfigsPath "test") | ConvertFrom-Json).Variables
      $result = $Cipherbundle | Get-ProtectionStatus
    }
    It "Should return status Protected" {
      $result.Status | Should -Be "Protected"
    }
  }

  Context "Unprotected File" {
    BeforeAll {
      Get-CyaConfig test2 | Unprotect-CyaConfig
      $Cipherbundle = (Get-Content (Join-Path $ConfigsPath "test2") | ConvertFrom-Json).Files
      $result = $Cipherbundle | Get-ProtectionStatus
    }
    It "Should return status Unprotected" {
      $result.Status | Should -Be "Unprotected"
    }
    AfterAll {
      Protect-CyaConfig
    }
  }

  Context "Protected File" {
    BeforeAll {
      $Cipherbundle = (Get-Content (Join-Path $ConfigsPath "test2") | ConvertFrom-Json).Files
      $result = $Cipherbundle | Get-ProtectionStatus
    }
    It "Should return status Protected" {
      $result.Status | Should -Be "Protected"
    }
  }

  Context "Conflicting File" {
    BeforeAll {
      Get-RandomString | Out-File -Encoding Default -NoNewline $TmpFile1Path
      $Cipherbundle = (Get-Content (Join-Path $ConfigsPath "test2") | ConvertFrom-Json).Files
      $result = $Cipherbundle | Get-ProtectionStatus
    }
    It "Should return status Protected" {
      $result.Status | Should -Be "Protected"
    }
  }

}

AfterAll {
  if(Get-Item $CYAPATH -EA SilentlyContinue){
    Remove-Item $CYAPATH -Force -Recurse
  }
  $Env:CYAPATH = $OriginalCyaPath
}
