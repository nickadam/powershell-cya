BeforeAll {
  . (Join-Path (Get-Item $PSScriptRoot).Parent "Private" "Get-CyaPasswordPath.ps1")
}

Describe "Get-CyaPasswordPath" {
  Context "CYAPATH not set" {
    BeforeAll {
      $Env:CYAPATH = ""
      $result = Get-CyaPasswordPath
    }
    It "Should return a string using `$Home" {
      $expected = Join-Path $Home ".cya" "passwords"
      $result | Should -Be $expected
    }
  }

  Context "CYAPATH set" {
    BeforeAll {
      $Env:CYAPATH = "TestDrive:\"
      $result = Get-CyaPasswordPath
    }
    It "Should return a string using `$Env:CYAPATH" {
      $expected = Join-Path "TestDrive:\" "passwords"
      $result | Should -Be $expected
    }
  }
}
