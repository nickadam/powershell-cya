BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) "Private"

  # import all private scripts
  $Items = Get-ChildItem -Path (Join-Path $PrivateDirectory "*.ps1")
  $Items | ForEach {
    try {
      . $_.FullName
    } catch {
      $FullName = $_.FullName
      Write-Error -Message "Failed to import $_"
    }
  }

  $TmpFile = New-TemporaryFile
  rm $TmpFile
  mkdir $TmpFile
  $Env:CYAPATH = $TmpFile
}

Describe "ConvertTo-Cipherbundle" {
  Context "Pipeline Item, Key param, and Name param with small string" {
    BeforeAll {
      $Item = [PSCustomObject]@{
        "Key" = "var1"
        "Value" = "val1"
      }
      $result = $Item | ConvertTo-Cipherbundle -Key "key" -Name "test"
    }
    It "Should an return object with Ciphertext" {
      $result.Ciphertext.length | Should -Be 24
    }
  }

  Context "Pipeline Item, Key param, and Name param with large string" {
    BeforeAll {
      $Item = [PSCustomObject]@{
        "Key" = "var1"
        "Value" = Get-RandomString -Length 1025
      }
      $result = $Item | ConvertTo-Cipherbundle -Key "key" -Name "test"
    }
    It "Should return an object with CiphertextFile" {
      (Split-Path $result.CiphertextFile -Leaf) | Should -Be "test.0"
    }
    AfterAll {
      rm $result.CiphertextFile
    }
  }

  Context "Pipeline Item, Key param, and Name param with small file" {
    BeforeAll {
      $TmpFile = New-TemporaryFile
      "test content" | Out-File -Encoding Default -NoNewline $TmpFile

      $result = $TmpFile | ConvertTo-Cipherbundle -Key "key" -Name "test"
    }
    It "Should return an object with Ciphertext" {
      $result.Ciphertext.length | Should -Be 24
    }
  }

  Context "Pipeline Item, Key param, and Name param with large file" {
    BeforeAll {
      $TmpFile = New-TemporaryFile
      (Get-RandomString -Length 1025) | Out-File -Encoding Default -NoNewline $TmpFile

      $result = $TmpFile | ConvertTo-Cipherbundle -Key "key" -Name "test"
    }
    It "Should return an object with CiphertextFile" {
      (Split-Path $result.CiphertextFile -Leaf) | Should -Be "test.0"
    }
    AfterAll {
      rm $result.CiphertextFile
    }
  }

  AfterAll {
    rm $Env:CYAPATH -Force -Recurse
    $Env:CYAPATH=""
  }
}
