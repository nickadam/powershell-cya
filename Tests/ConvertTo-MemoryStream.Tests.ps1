BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")
  . (Join-Path $PrivateDirectory $ScriptName.Replace('.Tests.ps1','.ps1'))
}

Describe "ConvertTo-MemoryStream" {
  Context "String param" {
    BeforeAll {
      $MemoryStream = ConvertTo-MemoryStream -String "abc"
      $Bytes = @()
      do {
        try {
          $Byte = $MemoryStream.ReadByte()
        } catch {
          Throw
        }
        if($Byte -ne -1){
          $Bytes += $Byte
        }
      } while($Byte -ne -1)

      $result = [System.Text.Encoding]::UTF8.GetString($Bytes)

    }
    It "Should return a MemoryStream with content of string" {
      $result | Should -Be "abc"
    }
    AfterAll {
      $MemoryStream.Dispose()
    }
  }

  Context "String FromBase64" {
    BeforeAll {
      $MemoryStream = ConvertTo-MemoryStream -String "YWJj" -FromBase64 
      $Bytes = @()
      do {
        try {
          $Byte = $MemoryStream.ReadByte()
        } catch {
          Throw
        }
        if($Byte -ne -1){
          $Bytes += $Byte
        }
      } while($Byte -ne -1)

      $result = [System.Text.Encoding]::UTF8.GetString($Bytes)

    }
    It "Should return a MemoryStream with content of string" {
      $result | Should -Be "abc"
    }
    AfterAll {
      $MemoryStream.Dispose()
    }
  }

}
