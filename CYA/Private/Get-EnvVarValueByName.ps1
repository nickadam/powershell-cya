function Get-EnvVarValueByName {
  param($Name)
  [System.Environment]::GetEnvironmentVariable($Name)
}
