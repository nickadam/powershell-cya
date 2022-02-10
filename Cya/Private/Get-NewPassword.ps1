function Get-NewPassword {
  param(
    [SecureString]$Password = (Read-Host -AsSecureString "Enter new password"),
    [SecureString]$ConfirmPassword = (Read-Host -AsSecureString "Confirm new password")
  )

  $password1 = Get-SecureStringText -SecureString $Password
  $password2 = Get-SecureStringText -SecureString $ConfirmPassword

  if($password1 -ne $password2){
    Throw "Passwords do not match"
  }

  $Password
}
