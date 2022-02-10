function Get-RandomString {
  param($Length=64)
  $chars = "ABCDEFGHKLMNOPRSTUVWXYZabcdefghiklmnoprstuvwxyz0123456789".toCharArray()
  $String = ""
  while($String.Length -lt $Length){
    $String += $chars | Get-Random
  }
  $String
}
