function ConvertFrom-MemoryStream {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [System.IO.MemoryStream]$MemoryStream,
    [Switch]$ToBase64
  )

  try {
    $MemoryStream.Seek(0, [IO.SeekOrigin]::Begin) | Out-Null
  } catch {
    Throw
  }

  $Bytes = @()
  do {
    try {
      $Byte = $MemoryStream.ReadByte()
    } catch {
      Throw
    }
    if($Byte -ne -1){
      $Bytes += $Byte
    }
  } while($Byte -ne -1)

  $MemoryStream.Dispose()

  if($ToBase64){
    [System.Convert]::ToBase64String($Bytes)
  }else{
    [System.Text.Encoding]::UTF8.GetString($Bytes)
  }
}
