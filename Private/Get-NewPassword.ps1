function Get-NewPassword {
  param(
    [Parameter(Mandatory)]
    [SecureString]${Enter new password},

    [Parameter(Mandatory)]
    [SecureString]${Confirm new password}
  )

  $password1 = Get-SecureStringText -SecureString ${Enter new password}
  $password2 = Get-SecureStringText -SecureString ${Confirm new password}

  if($password1 -ne $password2){
    Throw "Passwords do not match"
  }

  ${Enter new password}
}
