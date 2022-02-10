BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")
  . (Join-Path $PrivateDirectory $ScriptName.Replace('.Tests.ps1','.ps1'))
}

Describe "ConvertTo-ByteArray" {
  Context "String param" {
    BeforeAll {
      $result = ConvertTo-ByteArray -String "abc"
    }
    It "Should return a byte array" {
      $result.Count | Should -Be 3
    }
  }

  Context "File param" {
    BeforeAll {
      $TmpFile = "TestDrive:\test.txt"
      "test content" | Out-File -NoNewline -Encoding Default $TmpFile
      $result = ConvertTo-ByteArray -File $TmpFile
    }
    It "Should return a byte array from the contents of the file" {
      $result.Count | Should -Be 12
    }
  }

  Context "Pipeline of string" {
    BeforeAll {
      $result = "abc" | ConvertTo-ByteArray
    }
    It "Should return a byte array" {
      $result.Count | Should -Be 3
    }
  }

  Context "Pipeline of strings" {
    BeforeAll {
      $result = "a","b" | ConvertTo-ByteArray
    }
    It "Should return a byte array" {
      $result.Count | Should -Be 2
    }
  }

  Context "Pipeline of file" {
    BeforeAll {
      $TmpFile = "TestDrive:\test.txt"
      "test content" | Out-File -NoNewline -Encoding Default $TmpFile
      $result = (Get-Item $TmpFile) | ConvertTo-ByteArray
    }
    It "Should return a byte array from the contents of the file" {
      $result.Count | Should -Be 12
    }
  }

  Context "Pipeline of files" {
    BeforeAll {
      $TmpFile = "TestDrive:\test.txt"
      $TmpFile2 = "TestDrive:\test2.txt"
      "test content" | Out-File -NoNewline -Encoding Default $TmpFile
      "more test content" | Out-File -NoNewline -Encoding Default $TmpFile2
      $result = (Get-Item $TmpFile), (Get-Item $TmpFile2) | ConvertTo-ByteArray
    }
    It "Should return a byte array from the contents of the files" {
      $result.Count | Should -Be 29
    }
  }
}
