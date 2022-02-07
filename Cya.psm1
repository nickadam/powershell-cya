Get-ChildItem -Path (Join-Path $PSScriptRoot "Private" "*.ps1") | ForEach {
  try {
    . $_.FullName
  } catch {
    $FullName = $_.FullName
    Write-Error -Message "Failed to import $_"
  }
}

$ExportModule = @{
    Alias = @()
    Function = @()
    Variable = @()
}

Export-ModuleMember @ExportModule
