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

  Context "Creating files" {
    BeforeAll {
      $TmpFile1 = New-TemporaryFile
      Get-RandomString | Out-File -Encoding Default -NoNewline $TmpFile1
      $TmpFile2 = New-TemporaryFile
      Get-RandomString | Out-File -Encoding Default -NoNewline $TmpFile2
      $OriginalPwd = pwd
      cd (Split-Path $TmpFile2)
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter new password" }
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Confirm new password" }
      Mock Invoke-ChoicePrompt { "File" } -ParameterFilter { $Caption -eq "Config type" }
      Mock Invoke-ChoicePrompt { "" } -ParameterFilter { $Caption -eq "Protect on exit" }
      Mock Read-Host {$TmpFile1} -ParameterFilter { $Prompt -eq "File 1 path (Enter when done)" }
      Mock Read-Host {Split-Path $TmpFile2 -Leaf} -ParameterFilter { $Prompt -eq "File 2 path (Enter when done)" }
      Mock Read-Host {""} -ParameterFilter { $Prompt -eq "File 3 path (Enter when done)" }
      $Status = New-CyaConfig -Name "test"
    }
    It "Should put create a CyaConfig file" {
      (Get-Content (Join-Path $ConfigsPath "test") | ConvertFrom-Json).Type | Should -Be "File"
    }
    AfterAll {
      $Env:MYVAR = ""
      $Env:MYOTHERVAR = ""
      Remove-Item $CYAPATH -Force -Recurse
      Remove-Item $TmpFile1
      Remove-Item $TmpFile2
      cd $OriginalPwd
    }
  }

  Context "Creating file from argument" {
    BeforeAll {
      $TmpFile = New-TemporaryFile
      $n=0; $d=while($n -lt 150){$n++; Get-Random}; ($d * 100) | Out-File -Encoding Default $TmpFile
      $OriginalPwd = pwd
      cd (Split-Path $TmpFile)
      $FileName = Split-Path $TmpFile -Leaf
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter new password" }
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Confirm new password" }
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter password for CyaPassword `"Default`"" }
      Mock Invoke-ChoicePrompt { "" } -ParameterFilter { $Caption -eq "Protect on exit" }
      New-CyaPassword
      $Status = $FileName | New-CyaConfig -Name "test"
    }
    It "Should put create a CyaConfig file" {
      (Get-Content (Join-Path $ConfigsPath "test") | ConvertFrom-Json).Type | Should -Be "File"
    }
    AfterAll {
      $Env:MYVAR = ""
      $Env:MYOTHERVAR = ""
      Remove-Item $CYAPATH -Force -Recurse
      Remove-Item $TmpFile
      cd $OriginalPwd
    }
  }

  Context "Creating file from param" {
    BeforeAll {
      $TmpFile = New-TemporaryFile
      Get-RandomString | Out-File -Encoding Default -NoNewline $TmpFile
      $OriginalPwd = pwd
      cd (Split-Path $TmpFile)
      $FileName = Split-Path $TmpFile -Leaf
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter new password" }
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Confirm new password" }
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter password for CyaPassword `"Default`"" }
      New-CyaPassword
      $Status = New-CyaConfig -File $FileName -Name "test" -ProtectOnExit $True
    }
    It "Should put create a CyaConfig file" {
      (Get-Content (Join-Path $ConfigsPath "test") | ConvertFrom-Json).Type | Should -Be "File"
    }
    AfterAll {
      $Env:MYVAR = ""
      $Env:MYOTHERVAR = ""
      Remove-Item $CYAPATH -Force -Recurse
      Remove-Item $TmpFile
      cd $OriginalPwd
    }
  }

  Context "Creating envvar from hashtable" {
    BeforeAll {
      $TestVars = @{
        "MYVAR" = "my value"
        "MYOTHERVAR" = "my other value"
      }
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter new password" }
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Confirm new password" }
      $Status = New-CyaConfig -Name "test" -EnvVarCollection $TestVars
    }
    It "Should create two items in one config" {
      $Status.Length | Should -Be 2
    }
    It "Should put create a CyaConfig file" {
      (Get-Content (Join-Path $ConfigsPath "test") | ConvertFrom-Json).Type | Should -Be "EnvVar"
    }
    AfterAll {
      Remove-Item $CYAPATH -Force -Recurse
    }
  }

  Context "Creating from list of set environment variables via pipeline" {
    BeforeAll {
      $Env:MYVAR = "my value"
      $Env:MYOTHERVAR = "my other value"
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter new password" }
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Confirm new password" }
      $Status = "MYVAR", "MYOTHERVAR" | New-CyaConfig -Name "test"
    }
    It "Should create two items in one config" {
      $Status.Length | Should -Be 2
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

  Context "Creating from list of set environment variables via pipeline" {
    BeforeAll {
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter new password" }
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Confirm new password" }
      $Status = New-CyaConfig -Name "test" -EnvVarName "MYVAR" -EnvVarValue "my value"
    }
    It "Should create two items in one config" {
      ($Status | measure).Count | Should -Be 1
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
