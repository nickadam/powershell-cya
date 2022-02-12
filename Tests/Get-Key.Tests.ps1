BeforeAll {
  $ScriptName = Split-Path $PSCommandPath -Leaf
  $PrivateDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Private")
  $PublicDirectory = Join-Path (Split-Path $PSCommandPath | Split-Path) (Join-Path "Cya" "Public")

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
  Remove-Item $TmpFile
  mkdir $TmpFile
  $Env:CYAPATH = $TmpFile
  $Password = ConvertTo-SecureString -String "password" -AsPlainText -Force
}

Describe "Get-Key" {
  Context "Password param" {
    BeforeAll {
      New-CyaPassword -Password $Password
      $result = Get-Key -Password $Password
    }
    It "Should write a random string" {
      $result.length | Should -Be 64
    }
  }

  Context "Bad Password param" {
    BeforeAll {
      New-CyaPassword -Password $Password -Name "BadPass"
      $BadPassword = ConvertTo-SecureString -String "passwrd" -AsPlainText -Force
    }
    It "Should write a random string" {
      { Get-Key -Password $BadPassword -CyaPassword "BadPass" } | Should -Throw
    }
  }

  Context "Password param CyaPassword param" {
    BeforeAll {
      New-CyaPassword -Password $Password -Name "MyPass1"
      New-CyaPassword -Password $Password -Name "MyPass2"
      $Key1 = Get-Key -Password $Password -CyaPassword "MyPass1"
      $Key2 = Get-Key -Password $Password -CyaPassword "MyPass2"
    }
    It "Should write a random string different from others" {
      $Key1 -ne $Key2 | Should -Be $True
    }
  }

  AfterAll {
    Remove-Item $Env:CYAPATH -Force -Recurse
    $Env:CYAPATH = $OriginalCyaPath
  }
}
