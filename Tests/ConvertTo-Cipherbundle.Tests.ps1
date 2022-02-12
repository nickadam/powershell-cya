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
      $result.Ciphertext.length | Should -Be 44
    }
  }

  Context "Pipeline Item, Key param, and Name param with file" {
    BeforeAll {
      $TmpFile = New-TemporaryFile
      (Get-RandomString -Length 1025) | Out-File -Encoding Default -NoNewline $TmpFile

      $result = $TmpFile | ConvertTo-Cipherbundle -Key "key" -Name "test"
    }
    It "Should return an object with CiphertextFile" {
      (Split-Path $result.CiphertextFile -Leaf) | Should -Be "test.0"
    }
    AfterAll {
      Remove-Item $result.CiphertextFile
    }
  }

  AfterAll {
    Remove-Item $Env:CYAPATH -Force -Recurse
    $Env:CYAPATH = $OriginalCyaPath
  }
}
