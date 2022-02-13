BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")
  . (Join-Path $PrivateDirectory $ScriptName.Replace('.Tests.ps1','.ps1'))
}

Describe "Invoke-ChoicePrompt" {
  Context "Mock Get-Host" {
    BeforeAll {
      # Thanks to, https://stackoverflow.com/questions/57698737/how-do-i-mock-host-ui-promptforchoice-with-pester
      Mock Get-Host { [PSCustomObject]@{ "ui" = Add-Member -PassThru -Name PromptForChoice -InputObject ([pscustomobject] @{}) -Type ScriptMethod -Value { return 0 }}}
    }
    It "Should return a MemoryStream with content of string" {
      Invoke-ChoicePrompt "test" "test" "Yes", "No" | Should -Be "Yes"
    }
  }
}
