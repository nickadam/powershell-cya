BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) "Private"

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
  rm $TmpFile
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

  Context "Pipeline Cipherbundle with large string EnvVar" {
    BeforeAll {
      $Env:testvar1 = ""
      $RandomString = Get-RandomString -Length 1025
      $Item = [PSCustomObject]@{
        "Name" = "testvar1"
        "Value" = $RandomString
      }
      $Cipherbundle = $Item | ConvertTo-Cipherbundle -Key "key" -Name "test"
      $Cipherbundle | ConvertFrom-Cipherbundle -Key "key"
    }
    It "Should set testvar1" {
      $Env:testvar1 | Should -Be $RandomString
    }
    AfterAll {
      $Env:testvar1 = ""
    }
  }

  Context "Pipeline Cipherbundle with small file" {
    BeforeAll {
      $TmpFile = New-TemporaryFile
      "test content" | Out-File -Encoding Default -NoNewline $TmpFile

      $Cipherbundle = $TmpFile | ConvertTo-Cipherbundle -Key "key" -Name "test"
      rm $TmpFile
      $Cipherbundle | ConvertFrom-Cipherbundle -Key "key" | Out-Null
      $result = Get-Content $TmpFile
    }
    It "Should create the file" {
      $result | Should -Be "test content"
    }
    AfterAll {
      rm $TmpFile
    }
  }

  Context "Pipeline Cipherbundle with large file" {
    BeforeAll {
      $TmpFile = New-TemporaryFile
      $RandomString = Get-RandomString -Length 1025
      $RandomString | Out-File -Encoding Default -NoNewline $TmpFile

      $Cipherbundle = $TmpFile | ConvertTo-Cipherbundle -Key "key" -Name "test"
      rm $TmpFile
      $Cipherbundle | ConvertFrom-Cipherbundle -Key "key" | Out-Null
      $result = Get-Content $TmpFile
    }
    It "Should create the file" {
      $result | Should -Be $RandomString
    }
    AfterAll {
      rm $TmpFile
    }
  }

  AfterAll {
    rm $Env:CYAPATH -Force -Recurse
    $Env:CYAPATH = $OriginalCyaPath
  }
}
