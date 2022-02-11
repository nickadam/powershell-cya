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
  $ConfigsPath = Join-Path $CYAPATH "configs"

  $WarningPreference='SilentlyContinue'
}

Describe "New-CyaConfig" {
  Context "Creating unset environment variables" {
    BeforeAll {
      $Env:MYVAR = ""
      $Env:MYOTHERVAR = ""
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter new password" }
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Confirm new password" }
      Mock Invoke-ChoicePrompt { "EnvVar" } -ParameterFilter { $Caption -eq "Config type" }
      Mock Read-Host {"MYVAR"} -ParameterFilter { $Prompt -eq "Variable 1 name (Enter when done)" }
      Mock Read-Host {ConvertTo-SecureString -String "my value" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "MYVAR value" }
      Mock Read-Host {"MYOTHERVAR"} -ParameterFilter { $Prompt -eq "Variable 2 name (Enter when done)" }
      Mock Read-Host {ConvertTo-SecureString -String "my other value" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "MYOTHERVAR value" }
      Mock Read-Host {""} -ParameterFilter { $Prompt -eq "Variable 3 name (Enter when done)" }
      $Status = New-CyaConfig -Name "test"
    }
    It "Should create two items in one config" {
      $Expected = '[{"Name":"test","Type":"EnvVar","CyaPassword":"Default","ProtectOnExit":true,"Item":"MYVAR","Status":"Protected"},{"Name":"test","Type":"EnvVar","CyaPassword":"Default","ProtectOnExit":true,"Item":"MYOTHERVAR","Status":"Protected"}]'
      $Status | ConvertTo-Json -Compress | Should -Be $Expected
    }
    It "Should put create a CyaConfig file" {
      (Get-Content (Join-Path $ConfigsPath "test") | ConvertFrom-Json).Type | Should -Be "EnvVar"
    }
    AfterAll {
      Remove-Item $CYAPATH -Force -Recurse
    }
  }

  Context "Creating set environment variables accepting default" {
    BeforeAll {
      $Env:MYVAR = "my value"
      $Env:MYOTHERVAR = "my other value"
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter new password" }
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Confirm new password" }
      Mock Invoke-ChoicePrompt { "EnvVar" } -ParameterFilter { $Caption -eq "Config type" }
      Mock Read-Host {"MYVAR"} -ParameterFilter { $Prompt -eq "Variable 1 name (Enter when done)" }
      Mock Read-Host {New-Object System.Security.SecureString} -ParameterFilter { $Prompt -eq "MYVAR value [my value]" }
      Mock Read-Host {"MYOTHERVAR"} -ParameterFilter { $Prompt -eq "Variable 2 name (Enter when done)" }
      Mock Read-Host {New-Object System.Security.SecureString} -ParameterFilter { $Prompt -eq "MYOTHERVAR value [my other value]" }
      Mock Read-Host {""} -ParameterFilter { $Prompt -eq "Variable 3 name (Enter when done)" }
      $Status = New-CyaConfig -Name "test"
    }
    It "Should create two items in one config" {
      $Expected = '[{"Name":"test","Type":"EnvVar","CyaPassword":"Default","ProtectOnExit":true,"Item":"MYVAR","Status":"Unprotected"},{"Name":"test","Type":"EnvVar","CyaPassword":"Default","ProtectOnExit":true,"Item":"MYOTHERVAR","Status":"Unprotected"}]'
      $Status | ConvertTo-Json -Compress | Should -Be $Expected
    }
    It "Should put create a CyaConfig file" {
      (Get-Content (Join-Path $ConfigsPath "test") | ConvertFrom-Json).Type | Should -Be "EnvVar"
    }
    AfterAll {
      $Env:MYVAR = ""
      $Env:MYOTHERVAR = ""
      Remove-Item $CYAPATH -Force -Recurse
    }
  }

  AfterAll {
    if(Get-Item $CYAPATH -EA SilentlyContinue){
      Remove-Item $CYAPATH -Force -Recurse
    }
    $Env:CYAPATH = $OriginalCyaPath
  }
}
