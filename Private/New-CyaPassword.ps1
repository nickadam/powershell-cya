function New-CyaPassword {
  param($Name="Default", $Password)

  $PasswordPath = Join-Path -Path (Get-CyaPasswordPath) -ChildPath $Name

  if(Test-Path $PasswordPath){
    Write-Error -Message "Password $Name already exists" -ErrorAction Stop
  }

  if(!$Password){
    $Password = Get-NewPassword
  }

  if(-not (Test-Path (Get-CyaPasswordPath))){
    mkdir -p (Get-CyaPasswordPath)
  }

  $EncryptedBin = Get-RandomString | ConvertTo-ByteArray | Get-EncryptedBin -Password $Password

  # Convert Ciphertext to base64
  $EncryptedBin.Ciphertext = [System.Convert]::ToBase64String($EncryptedBin.Ciphertext)

  # write to file
  $EncryptedBin | ConvertTo-Json | Out-File -Encoding Default $PasswordPath
}
