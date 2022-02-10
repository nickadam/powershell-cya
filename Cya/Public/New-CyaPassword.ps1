function New-CyaPassword {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [String]$Name = "Default",
    [SecureString]$Password = (Get-NewPassword)
  )

  $PasswordPath = Join-Path -Path (Get-CyaPasswordPath) -ChildPath $Name

  if(Test-Path $PasswordPath){
    Throw "Password $Name already exists"
  }

  # make missing directories
  if(-not (Test-Path (Get-CyaPasswordPath))){
    mkdir -p (Get-CyaPasswordPath)
  }

  $Key = Get-SecureStringText $Password
  $EncryptedBin = Get-RandomString | ConvertTo-ByteArray | Get-EncryptedBin -Password $Key

  # Convert Ciphertext to base64
  $EncryptedBin.Ciphertext = [System.Convert]::ToBase64String($EncryptedBin.Ciphertext)

  # write to file
  $EncryptedBin | ConvertTo-Json | Out-File -Encoding Default $PasswordPath
}
