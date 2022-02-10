BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")
  . (Join-Path $PrivateDirectory $ScriptName.Replace('.Tests.ps1','.ps1'))
}

Describe "Get-RandomString" {
  Context "No params" {
    BeforeAll {
      $result = Get-RandomString
    }
    It "Should return a string with length 64" {
      $result.length | Should -Be 64
    }
  }

  Context "Length params" {
    BeforeAll {
      $result = Get-RandomString -Length 2
    }
    It "Should return a string with length 2" {
      $result.length | Should -Be 2
    }
  }
}
