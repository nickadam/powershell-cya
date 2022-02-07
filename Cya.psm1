Get-ChildItem -Path (Join-Path $PSScriptRoot "Private" "*.ps1") | ForEach {
  try {
    . $_.FullName
  } catch {
    $FullName = $_.FullName
    Write-Error -Message "Failed to import $FullName"
  }
}
