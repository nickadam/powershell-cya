
$Private = Get-ChildItem -Path (Join-Path  -Path $PSScriptRoot -ChildPath  (Join-Path -Path "Private" -ChildPath "*.ps1"))
$Public = Get-ChildItem -Path (Join-Path  -Path $PSScriptRoot -ChildPath  (Join-Path -Path "Public" -ChildPath "*.ps1"))

($Private + $Public) | ForEach-Object {
  try {
    . $_.FullName
  } catch {
    Write-Error -Message "Failed to import $_"
  }
}

$ExportModule = @{
    Alias = @('ucya', 'pcya')
    Function = $Public.BaseName
    Variable = @()
}

$OnRemoveScript = {
  $ToProtect = Get-CyaConfig -Unprotected | Where-Object{($_.ProtectOnExit -eq $True)}
  if($ToProtect){
    $ToProtect | Protect-CyaConfig
  }
}

if(-not $Env:CYA_DISABLE_UNPROTECTED_MESSAGE){
  $Unprotected = Get-CyaConfig -Unprotected
  if($Unprotected){
    $Unprotected | Format-Table | Out-String | ForEach-Object { Write-Warning $_ }
    Write-Warning "The items above are Unprotected"
  }
}

New-Alias ucya -Value Unprotect-CyaConfig -Force
New-Alias pcya -Value Protect-CyaConfig -Force

$ExecutionContext.SessionState.Module.OnRemove += $OnRemoveScript
Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action $OnRemoveScript

Export-ModuleMember @ExportModule
