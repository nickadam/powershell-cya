
$Private = Get-ChildItem -Path (Join-Path $PSScriptRoot "Private" "*.ps1")
$Public = Get-ChildItem -Path (Join-Path $PSScriptRoot "Public" "*.ps1")

($Private + $Public) | ForEach-Object {
  try {
    . $_.FullName
  } catch {
    $FullName = $_.FullName
    Write-Error -Message "Failed to import $_"
  }
}

$ExportModule = @{
    Alias = @()
    Function = $Public.BaseName
    Variable = @()
}

$OnRemoveScript = {
  Get-CyaConfig -Unprotected | Where-Object{($_.ProtectOnExit -eq $True)} | Protect-CyaConfig
}

if(-not $Env:CYA_DISABLE_UNPROTECTED_MESSAGE){
  $Unprotected = Get-CyaConfig -Unprotected
  if($Unprotected){
    $Unprotected | Format-Table | Out-String | ForEach-Object {Write-Host $_}
    Write-Warning "The items above are Unprotected"
  }
}

$ExecutionContext.SessionState.Module.OnRemove += $OnRemoveScript
Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action $OnRemoveScript

Export-ModuleMember @ExportModule
