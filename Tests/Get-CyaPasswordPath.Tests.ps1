BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")
  . (Join-Path $PrivateDirectory $ScriptName.Replace('.Tests.ps1','.ps1'))

  $OriginalCyaPath = $Env:CYAPATH
}

Describe "Get-CyaPasswordPath" {
  Context "CYAPATH not set" {
    BeforeAll {
      $Env:CYAPATH = ""
      $result = Get-CyaPasswordPath
    }
    It "Should return a string using `$Home" {
      $expected = Join-Path (Join-Path $Home ".cya") "passwords"
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

  AfterAll {
    $Env:CYAPATH = $OriginalCyaPath
  }
}
