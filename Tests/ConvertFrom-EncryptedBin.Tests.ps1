BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")
  . (Join-Path $PrivateDirectory $ScriptName.Replace('.Tests.ps1','.ps1'))
  . (Join-Path $PrivateDirectory 'ConvertTo-MemoryStream.ps1')
  . (Join-Path $PrivateDirectory 'ConvertFrom-MemoryStream.ps1')
  . (Join-Path $PrivateDirectory 'ConvertTo-EncryptedBin.ps1')

  $ProgressPreference='SilentlyContinue'
}

Describe "ConvertFrom-EncryptedBin" {
  Context "String param" {
    BeforeAll {
      $result = ConvertFrom-EncryptedBin -String "d73sIC+rv2o9cIBKgQhWUGzG5x57RlFjPLNpV0Ths1s=" -Key "password"
    }
    It "Should return a string" {
      $result | Should -Be "abc"
    }
  }

  Context "String pipeline" {
    BeforeAll {
      $result = "d73sIC+rv2o9cIBKgQhWUGzG5x57RlFjPLNpV0Ths1s=" | ConvertFrom-EncryptedBin -Key "password"
    }
    It "Should return a string" {
      $result | Should -Be "abc"
    }
  }

  Context "FileIn FileOut params" {
    BeforeAll {
      $TmpFile1 = New-TemporaryFile
      $TmpFile2 = New-TemporaryFile
      $TmpFile3 = New-TemporaryFile
      $n=0; $d=while($n -lt 100){$n++; Get-Random}; $d | Out-File -Encoding Default $TmpFile1
      ConvertTo-EncryptedBin -FileIn $TmpFile1 -FileOut $TmpFile2 -Key "password"
      ConvertFrom-EncryptedBin -FileIn $TmpFile2 -FileOut $TmpFile3 -Key "password"
      $Hash1 = (Get-FileHash $TmpFile1).Hash
      $Hash3 = (Get-FileHash $TmpFile3).Hash
    }
    It "Should decrypt the file" {
      $Hash1 | Should -Be $Hash3
    }
    AfterAll {
      rm $TmpFile1
      rm $TmpFile2
      rm $TmpFile3
    }
  }

  Context "FileIn pipeline FileOut param" {
    BeforeAll {
      $TmpFile1 = New-TemporaryFile
      $TmpFile2 = New-TemporaryFile
      $TmpFile3 = New-TemporaryFile
      $n=0; $d=while($n -lt 100){$n++; Get-Random}; $d | Out-File -Encoding Default $TmpFile1
      ConvertTo-EncryptedBin -FileIn $TmpFile1 -FileOut $TmpFile2 -Key "password"
      $TmpFile2 | ConvertFrom-EncryptedBin -FileOut $TmpFile3 -Key "password"
      $Hash1 = (Get-FileHash $TmpFile1).Hash
      $Hash3 = (Get-FileHash $TmpFile3).Hash
    }
    It "Should decrypt the file" {
      $Hash1 | Should -Be $Hash3
    }
    AfterAll {
      rm $TmpFile1
      rm $TmpFile2
      rm $TmpFile3
    }
  }
}
