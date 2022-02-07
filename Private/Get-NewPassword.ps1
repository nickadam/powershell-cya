function Get-NewPassword {
  $password1 = ""
  while(-not $password1){
    Write-Host -NoNewline "Enter new password: "
    $Password = Read-Host -AsSecureString
    $password1 = Get-SecureStringText -SecureString $Password
  }

  $password2 = ""
  while(-not $password2){
    Write-Host -NoNewline "Confirm new password: "
    $confirm = Read-Host -AsSecureString
    $password2 = Get-SecureStringText -SecureString $confirm
  }

  if($password1 -ne $password2){
    Write-Error -Message "Passwords do not match" -ErrorAction Stop
  }
  return $Password
}
