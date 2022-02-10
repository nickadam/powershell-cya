function ConvertFrom-ByteArray {
  [CmdletBinding(SupportsShouldProcess)]
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
      if($PSCmdlet.ShouldProcess($Destination, 'WriteAllBytes')){
        [System.IO.File]::WriteAllBytes($Destination, $Bytes)
        Get-Item $Destination
      }
    }
  }
}
