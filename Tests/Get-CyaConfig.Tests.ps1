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
  (Get-RandomString -Length 1025) | Out-File -Encoding Default -NoNewline $TmpFile1
  $TmpFile2 = New-TemporaryFile
  (Get-RandomString -Length 1025) | Out-File -Encoding Default -NoNewline $TmpFile2
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
}

Describe "Get-CyaConfig" {
  Context "No params" {
    BeforeAll {
      $results = Get-CyaConfig
    }
    It "Should return two summary objects" {
      $results.Length | Should -Be 2
    }
    It "Should return one file type summary objects" {
      ($results | where{$_.Type -eq "File"} | measure).Count | Should -Be 1
    }
    It "Should return one envvar type summary objects" {
      ($results | where{$_.Type -eq "EnvVar"} | measure).Count | Should -Be 1
    }
  }

  Context "Get one config" {
    BeforeAll {
      $results = Get-CyaConfig test2
    }
    It "Should return one summary objects" {
      ($results | measure).Count | Should -Be 1
    }
    It "Should return one file type summary objects" {
      ($results | where{$_.Type -eq "File"} | measure).Count | Should -Be 1
    }
    It "Should return zero envvar type summary objects" {
      ($results | where{$_.Type -eq "EnvVar"} | measure).Count | Should -Be 0
    }
  }

  Context "Unprotected" {
    BeforeAll {
      $results = Get-CyaConfig -Unprotected
    }
    It "Should return two item objects" {
      $results.Length | Should -Be 2
    }
    It "Should return one file type item object" {
      ($results | where{$_.Type -eq "File"} | measure).Count | Should -Be 1
    }
    It "Should return zero envvar type item object" {
      ($results | where{$_.Type -eq "EnvVar"} | measure).Count | Should -Be 1
    }
  }

  Context "Status" {
    BeforeAll {
      $results = Get-CyaConfig -Status
    }
    It "Should return four item objects" {
      $results.Length | Should -Be 4
    }
    It "Should return one file type item object" {
      ($results | where{$_.Status -eq "Unprotected"} | measure).Count | Should -Be 2
    }
    It "Should return zero envvar type item object" {
      ($results | where{$_.Status -eq "Protected"} | measure).Count | Should -Be 2
    }
  }
}

AfterAll {
  if(Get-Item $CYAPATH -EA SilentlyContinue){
    Remove-Item $CYAPATH -Force -Recurse
  }
  Remove-Item $TmpFile1
  $Env:MYOTHERVAR = ""
  $Env:CYAPATH = $OriginalCyaPath
}
