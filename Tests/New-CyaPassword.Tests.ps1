BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) "Private"
  $PublicDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) "Public"

  # import all private scripts
  $Items = Get-ChildItem -Path (Join-Path $PrivateDirectory "*.ps1")
  $Items += Get-ChildItem -Path (Join-Path $PublicDirectory "*.ps1")
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

Describe "New-CyaPassword" {
  Context "Password param" {
    BeforeAll {
      New-CyaPassword -Password (ConvertTo-SecureString -String "password" -AsPlainText -Force)
      $CyaPasswordPath = Join-Path -Path (Get-CyaPasswordPath) -ChildPath "Default"
      $EncryptedBin = Get-Content $CyaPasswordPath | ConvertFrom-Json
      $result = $EncryptedBin.Ciphertext
    }
    It "Should write the password to the CyaPasswordPath Default file" {
      $result.length | Should -Be 108
    }
  }

  Context "Password param Name param" {
    BeforeAll {
      New-CyaPassword -Password (ConvertTo-SecureString -String "password" -AsPlainText -Force) -Name "MyPass"
      $CyaPasswordPath = Join-Path -Path (Get-CyaPasswordPath) -ChildPath "MyPass"
      $EncryptedBin = Get-Content $CyaPasswordPath | ConvertFrom-Json
      $result = $EncryptedBin.Ciphertext
    }
    It "Should write the password to the CyaPasswordPath Name file" {
      $result.length | Should -Be 108
    }
  }

  AfterAll {
    $Env:CYAPATH = $OriginalCyaPath
  }
}
