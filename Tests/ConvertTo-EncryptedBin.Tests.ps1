BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")
  . (Join-Path $PrivateDirectory $ScriptName.Replace('.Tests.ps1','.ps1'))
  . (Join-Path $PrivateDirectory 'ConvertFrom-MemoryStream.ps1')

  $ProgressPreference='SilentlyContinue'
}

Describe "ConvertTo-EncryptedBin" {
  Context "String param" {
    BeforeAll {
      $result = ConvertTo-EncryptedBin -String "abc" -Key "password"
    }
    It "Should return a string" {
      $result.GetType().Name | Should -Be "String"
    }
  }

  Context "String pipeline" {
    BeforeAll {
      $result = "abc" | ConvertTo-EncryptedBin -Key "password"
    }
    It "Should return a string" {
      $result.GetType().Name | Should -Be "String"
    }
  }

  Context "FileIn FileOut params" {
    BeforeAll {
      $TmpFile1 = New-TemporaryFile
      $TmpFile2 = New-TemporaryFile
      $n=0; $d=while($n -lt 100){$n++; Get-Random}; $d  | Out-File -Encoding Default $TmpFile1
      ConvertTo-EncryptedBin -FileIn $TmpFile1 -FileOut $TmpFile2 -Key "password"
      $Size1 = (Get-Item $TmpFile1).Size
      $Size2 = (Get-Item $TmpFile2).Size
    }
    It "Should create a file of comparable size" {
      $Size1 - $Size2 | Should -BeLessThan 100
    }
    It "Should create a file of comparable size" {
      $Size1 - $Size2 | Should -BeGreaterThan -100
    }
    AfterAll {
      rm $TmpFile1
      rm $TmpFile2
    }
  }

  Context "FileIn pipeline FileOut param" {
    BeforeAll {
      $TmpFile1 = New-TemporaryFile
      $TmpFile2 = New-TemporaryFile
      $n=0; $d=while($n -lt 100){$n++; Get-Random}; $d  | Out-File -Encoding Default $TmpFile1
      $TmpFile1 | ConvertTo-EncryptedBin -FileOut $TmpFile2 -Key "password"
      $Size1 = (Get-Item $TmpFile1).Size
      $Size2 = (Get-Item $TmpFile2).Size
    }
    It "Should create a file of comparable size" {
      $Size1 - $Size2 | Should -BeLessThan 100
    }
    It "Should create a file of comparable size" {
      $Size1 - $Size2 | Should -BeGreaterThan -100
    }
    AfterAll {
      rm $TmpFile1
      rm $TmpFile2
    }
  }
}
