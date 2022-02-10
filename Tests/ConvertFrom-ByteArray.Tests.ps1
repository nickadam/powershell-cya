BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")
  . (Join-Path $PrivateDirectory $ScriptName.Replace('.Tests.ps1','.ps1'))
}

Describe "ConvertFrom-ByteArray" {
  Context "ByteArray param with String switch" {
    BeforeAll {
      $Bytes = @(97, 98, 99)
      $result = ConvertFrom-ByteArray -ByteArray $Bytes -ToString
    }
    It "Should return a string" {
      $result | Should -Be "abc"
    }
  }

  Context "ByteArray param with Destination param" {
    BeforeAll {
      $Bytes = @(97, 98, 99)
      # $TmpFile = "TestDrive:\test.txt" serious problems here with Split-Path -IsAbsolute
      $TmpFile = New-TemporaryFile
      Remove-Item $TmpFile
      $File = ConvertFrom-ByteArray -ByteArray $Bytes -Destination $TmpFile
      $Content = Get-Content $TmpFile
      Remove-Item $TmpFile
    }
    It "Should put the content in a file" {
      $Content | Should -Be "abc"
    }
    It "Should return a file object" {
      $File.GetType().Name | Should -Be "FileInfo"
    }
  }

  Context "Pipeline with String switch" {
    BeforeAll {
      $Bytes = @(97, 98, 99)
      $result = $Bytes | ConvertFrom-ByteArray -ToString
    }
    It "Should return a string" {
      $result | Should -Be "abc"
    }
  }

  Context "Pipeline Destination param" {
    BeforeAll {
      $Bytes = @(97, 98, 99)
      # $TmpFile = "TestDrive:\test.txt" serious problems here with Split-Path -IsAbsolute
      $TmpFile = New-TemporaryFile
      Remove-Item $TmpFile
      $File = $Bytes | ConvertFrom-ByteArray -Destination $TmpFile
      $Content = Get-Content $TmpFile
      Remove-Item $TmpFile
    }
    It "Should put the content in a file" {
      $Content | Should -Be "abc"
    }
    It "Should return a file object" {
      $File.GetType().Name | Should -Be "FileInfo"
    }
  }
}
