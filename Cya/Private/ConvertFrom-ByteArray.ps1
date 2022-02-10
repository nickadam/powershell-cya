function ConvertFrom-ByteArray {
  [CmdletBinding()]
  param(
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline)] [Object]$ByteArray,
    [Parameter(Position=1)] [String]$Destination,
    [Switch]$ToString
  )
  begin {
    $Bytes = @()
  }
  process{
    $Bytes += $ByteArray
  }
  end {
    if($ToString){
      [System.Text.Encoding]::UTF8.GetString($Bytes)
    }
    if($Destination){
      if(-not (Split-Path $Destination -IsAbsolute)){
        $Destination = Join-Path $PWD $Destination
      }
      [System.IO.File]::WriteAllBytes($Destination, $Bytes)
      Get-Item $Destination
    }
  }
}
