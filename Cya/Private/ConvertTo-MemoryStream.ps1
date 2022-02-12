function ConvertTo-MemoryStream {
  [CmdletBinding()]
  [OutputType([IO.MemoryStream])]
  param(
    [Parameter(Mandatory)]
    [String]$String,
    [Switch]$FromBase64
  )

  if($FromBase64){
    $Bytes = [Convert]::FromBase64String($String)
  }else{
    $Bytes = [Text.Encoding]::UTF8.GetBytes($String)
  }

  $MemoryStream = [IO.MemoryStream]::New()

  $Bytes | ForEach-Object {
    $MemoryStream.WriteByte($_)
  }

  $MemoryStream.Seek(0, [IO.SeekOrigin]::Begin) | Out-Null

  $MemoryStream
}
