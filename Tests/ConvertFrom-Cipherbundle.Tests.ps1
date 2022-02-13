BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")

  # import all private scripts
  $Items = Get-ChildItem -Path (Join-Path $PrivateDirectory "*.ps1")
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
}

Describe "ConvertFrom-Cipherbundle" {
  Context "Pipeline Cipherbundle with small string EnvVar" {
    BeforeAll {
      $Env:testvar1 = ""
      $Item = [PSCustomObject]@{
        "Name" = "testvar1"
        "Value" = "val1"
      }
      $Cipherbundle = $Item | ConvertTo-Cipherbundle -Key "key" -Name "test"
      $Cipherbundle | ConvertFrom-Cipherbundle -Key "key"
    }
    It "Should set testvar1" {
      $Env:testvar1 | Should -Be "val1"
    }
    AfterAll {
      $Env:testvar1 = ""
    }
  }

  Context "Pipeline Cipherbundle with file" {
    BeforeAll {
      $TmpFile = New-TemporaryFile
      $RandomString = Get-RandomString
      $RandomString | Out-File -Encoding Default -NoNewline $TmpFile

      $Cipherbundle = $TmpFile | ConvertTo-Cipherbundle -Key "key" -Name "test"
      Remove-Item $TmpFile
      $Cipherbundle | ConvertFrom-Cipherbundle -Key "key" | Out-Null
      $result = Get-Content $TmpFile
    }
    It "Should create the file" {
      $result | Should -Be $RandomString
    }
    AfterAll {
      Remove-Item $TmpFile
    }
  }

  AfterAll {
    Remove-Item $Env:CYAPATH -Force -Recurse
    $Env:CYAPATH = $OriginalCyaPath
  }
}
