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
  $TmpFile2Content = Get-RandomString
  $TmpFile2Content | Out-File -Encoding Default -NoNewline $TmpFile2
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

Describe "Protect-CyaConfig" {
  Context "WhatIf switch" {
    BeforeAll {
      $results = Protect-CyaConfig -WhatIf | Where{$_.Status -eq 'Protected'}
      $File1 = Test-Path $TmpFile1Path
    }
    It "Should not remove TmpFile1" {
      $File1 | Should -Be $True
    }
    It "Should not remove MYOTHERVAR" {
      $Env:MYOTHERVAR | Should -Be "my other value"
    }
  }

  Context "No params" {
    BeforeAll {
      $results = Protect-CyaConfig | Where{$_.Status -eq 'Protected'}
      $File1 = Test-Path $TmpFile1Path
      $File2 = Test-Path $TmpFile2Path
    }
    It "Should return list of all protected CyaConfig items" {
      $results.Length | Should -Be 4
    }
    It "Should return two file type item objects" {
      ($results | where{$_.Type -eq "File"}).Length | Should -Be 2
    }
    It "Should return two envvar type item objects" {
      ($results | where{$_.Type -eq "EnvVar"}).Length | Should -Be 2
    }
    It "Should remove TmpFile1" {
      $File1 | Should -Be $False
    }
    It "Should remove MYOTHERVAR" {
      $Env:MYOTHERVAR | Should -Be $Null
    }
  }

  Context "Name param" {
    BeforeAll {
      $results = Protect-CyaConfig test2 | Where{$_.Status -eq 'Protected'}
      $File1 = Test-Path $TmpFile1Path
      $File2 = Test-Path $TmpFile2Path
    }
    It "Should return list of all protected CyaConfig items" {
      $results.Length | Should -Be 2
    }
    It "Should return two file type item objects" {
      ($results | where{$_.Type -eq "File"}).Length | Should -Be 2
    }
  }

  Context "String pipeline" {
    BeforeAll {
      $results = "test" | Protect-CyaConfig  | Where{$_.Status -eq 'Protected'}
    }
    It "Should return list of all protected CyaConfig items" {
      $results.Length | Should -Be 2
    }
    It "Should return two file type item objects" {
      ($results | where{$_.Type -eq "EnvVar"}).Length | Should -Be 2
    }
  }

  Context "CyaConfig pipeline" {
    BeforeAll {
      $results = Get-CyaConfig "test" | Protect-CyaConfig  | Where{$_.Status -eq 'Protected'}
    }
    It "Should return list of all protected CyaConfig items" {
      $results.Length | Should -Be 2
    }
    It "Should return two file type item objects" {
      ($results | where{$_.Type -eq "EnvVar"}).Length | Should -Be 2
    }
  }

  Context "File with different contents" {
    BeforeAll {
      Get-RandomString | Out-File -Encoding Default -NoNewline $TmpFile1Path
      Protect-CyaConfig | Out-Null
      $result = Test-Path $TmpFile1Path
    }
    It "Should not remove the file" {
      $result | Should -Be $True
    }
  }

  Context "EnvVar with different value" {
    BeforeAll {
      $Env:MYVAR = "not my value"
      Protect-CyaConfig | Out-Null
    }
    It "Should not unset MYVAR" {
      $Env:MYVAR | Should -Be "not my value"
    }
  }
}

AfterAll {
  if(Get-Item $CYAPATH -EA SilentlyContinue){
    Remove-Item $CYAPATH -Force -Recurse
  }
  $Env:CYAPATH = $OriginalCyaPath
}
