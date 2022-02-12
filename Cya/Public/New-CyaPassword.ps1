function New-CyaPassword {
  <#
  .SYNOPSIS
  Creates CyaPasswords.

  .DESCRIPTION
  A CyaPassword is a key encrypted using AES256 with a password you supply.
  The key, once decrypted by your password, is used to encrypt and decrypt
  CyaConfigs. CyaPasswords provide a way to use different passwords with
  different CyaConfigs.

  .PARAMETER Name
  [String] The name of the CyaPassword

  .PARAMETER Password
  [SecureString] Your password to decrypt the CyaPassword

  .OUTPUTS
  $Null

  .NOTES
    Author: Nick Vissari

  .EXAMPLE
  New-CyaPassword

  cmdlet New-CyaPassword at command pipeline position 1
  Supply values for the following parameters:
  Name: sample
  Enter new password: *************
  Confirm new password: *************


  Description
  -----------
  Prompts for missing params

  .EXAMPLE
  New-CyaPassword -Name sample -Password (ConvertTo-SecureString -AsPlainText -Force "dont do this")


  Description
  -----------
  Inscure way to set a password using plain text string. Don't do this. The
  password will end up in your command history.

  #>

  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [String]$Name = "Default",
    [SecureString]$Password = (Get-NewPassword)
  )

  process {
    $PasswordPath = Join-Path -Path (Get-CyaPasswordPath) -ChildPath $Name

    if(Test-Path $PasswordPath){
      Throw "Password $Name already exists"
    }

    # make missing directories
    if(-not (Test-Path (Get-CyaPasswordPath))){
      mkdir -p (Get-CyaPasswordPath) | Out-Null
    }

    $Key = Get-SecureStringText $Password
    $Ciphertext = Get-RandomString | ConvertTo-EncryptedBin -Key $Key

    # write to file
    $Ciphertext | Out-File -Encoding Default $PasswordPath
  }
}
