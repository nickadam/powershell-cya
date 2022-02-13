BeforeAll {
  $ModulePath = Split-Path $PSCommandPath | Split-Path

  $OriginalCyaPath = $Env:CYAPATH
  $TmpFile = New-TemporaryFile
  Remove-Item $TmpFile
  mkdir $TmpFile
  $Env:CYAPATH = $TmpFile
  $CYAPATH = $Env:CYAPATH

  $OriginalPSModulePath = $Env:PSModulePath
  $Env:PSModulePath=$ModulePath
}

Describe "Cya.pms1" {
  Context "Import-Module" {
    BeforeAll {
      Get-CyaConfig
    }
    It "Should import ten functions" {
      (Get-Command -Module Cya | measure).Count | Should -Be 10
    }
    AfterAll {
      Remove-Module Cya
    }
  }
}

AfterAll {
  if(Get-Item $CYAPATH -EA SilentlyContinue){
    Remove-Item $CYAPATH -Force -Recurse
  }
  $Env:PSModulePath = $OriginalPSModulePath
}
