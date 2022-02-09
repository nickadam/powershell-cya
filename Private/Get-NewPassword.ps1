function Get-NewPassword {
  param(
    [Parameter(Mandatory)]
    [SecureString]$Password,

    [Parameter(Mandatory)]
    [SecureString]$ConfirmPassword
  )

  $password1 = Get-SecureStringText -SecureString $Password
  $password2 = Get-SecureStringText -SecureString $ConfirmPassword

  if($password1 -ne $password2){
    Throw "Passwords do not match"
  }

  return $Password
}
