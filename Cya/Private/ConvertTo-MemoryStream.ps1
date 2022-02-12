function ConvertTo-MemoryStream {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [String]$String,
    [Switch]$FromBase64
  )

  if($FromBase64){
    $Bytes = [System.Convert]::FromBase64String($String)
  }else{
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
  }

  $MemoryStream = [System.IO.MemoryStream]::New()

  $Bytes | ForEach-Object {
    $MemoryStream.WriteByte($_)
  }

  $MemoryStream.Seek(0, [IO.SeekOrigin]::Begin) | Out-Null

  $MemoryStream
}
