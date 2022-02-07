function Get-CyaConfigPath {
  $Base = Join-Path -Path $Home -ChildPath ".cya"
  if($Env:CYAPATH){
    $Base = $Env:CYAPATH
  }
  return Join-Path -Path $Base -ChildPath "configs"
}
