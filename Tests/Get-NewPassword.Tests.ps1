BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")
  . (Join-Path $PrivateDirectory $ScriptName.Replace('.Tests.ps1','.ps1'))
  . (Join-Path $PrivateDirectory 'Get-SecureStringText.ps1')
}

Describe "Get-NewPassword" {
  Context "Both passwords are the same" {
    BeforeAll {
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force}
      $result = Get-SecureStringText (Get-NewPassword)
    }
    It "Should return a string with length 64" {
      $result | Should -Be "password"
    }
  }

  Context "Both passwords are not the same" {
    BeforeAll {
      Mock Read-Host {ConvertTo-SecureString -String "password" -AsPlainText -Force} -ParameterFilter { $Prompt -eq "Enter new password" }
      Mock Read-Host {ConvertTo-SecureString -String "password1" -AsPlainText -Force}
    }
    It "Shouldn't return anything" {
      { Get-SecureStringText (Get-NewPassword) } | Should -Throw
    }
  }
}
