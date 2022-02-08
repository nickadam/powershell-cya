# Ciphertext Your Assets

function Get-EncryptedAnsibleVaultString {
  param($String, $Key)
  if($String){
    $Password = ConvertTo-SecureString -String $Key -AsPlainText
    Get-EncryptedAnsibleVault -Value $String -Password $Password
  }
}

function Get-DecryptedAnsibleVaultString {
  param($CipherTextString, $Key)
  if($CipherTextString){
    $Password = ConvertTo-SecureString -String $Key -AsPlainText
    $TempFile = New-TemporaryFile
    $CipherTextString | Out-File -Encoding Default $TempFile
    Get-DecryptedAnsibleVault -Path $TempFile -Password $Password
    Remove-Item $TempFile
  }
}

$OnRemoveScript = {
  Get-CyaConfig -Unprotected | Where{($_.Type -eq "File") -and ($_.ProtectOnExit -eq $True)} | ForEach {
    $CyaConfig = $_
    if(Test-Path $CyaConfig.Item){
      rm $CyaConfig.Item
    }
  }
}

$ExecutionContext.SessionState.Module.OnRemove += $OnRemoveScript
Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action $OnRemoveScript
