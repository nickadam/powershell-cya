BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")
  . (Join-Path $PrivateDirectory $ScriptName.Replace('.Tests.ps1','.ps1'))
}

Describe "ConvertFrom-MemoryStream" {
  Context "MemoryStream" {
    BeforeAll {

      $MemoryStream = [System.IO.MemoryStream]::New()

      [System.Text.Encoding]::UTF8.GetBytes("abc") | ForEach-Object {
        $MemoryStream.WriteByte($_)
      }

      $MemoryStream.Seek(0, [IO.SeekOrigin]::Begin) | Out-Null

      $result = ConvertFrom-MemoryStream -MemoryStream $MemoryStream

    }
    It "Should return a MemoryStream with content of string" {
      $result | Should -Be "abc"
    }
  }
  Context "MemoryStream ToBase64" {
    BeforeAll {

      $MemoryStream = [System.IO.MemoryStream]::New()

      [System.Text.Encoding]::UTF8.GetBytes("abc") | ForEach-Object {
        $MemoryStream.WriteByte($_)
      }

      $MemoryStream.Seek(0, [IO.SeekOrigin]::Begin) | Out-Null

      $result = ConvertFrom-MemoryStream -MemoryStream $MemoryStream -ToBase64

    }
    It "Should return a MemoryStream with content of string" {
      $result | Should -Be "YWJj"
    }
  }
}
