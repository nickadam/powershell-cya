function ConvertTo-ByteArray {
  [CmdletBinding(DefaultParameterSetName="FromFile")]
  [OutputType([byte[]])]
  param(
    [Parameter(Position=0, Mandatory=$true, ParameterSetName="FromPipeline", ValueFromPipeline, DontShow)] [Object]$Item,
    [Parameter(Position=0, Mandatory=$true, ParameterSetName="FromString")] [String]$String,
    [Parameter(Position=0, Mandatory=$true, ParameterSetName="FromFile")] [String]$File
  )
  process{
    switch($PSCmdlet.ParameterSetName){
      FromPipeline {
        if($Item.GetType().Name -eq "FileInfo"){
          [System.IO.File]::ReadAllBytes($Item.FullName)
        }
        if($Item.GetType().Name -eq "String"){
          [System.Text.Encoding]::UTF8.GetBytes($Item)
        }
      }
      FromString { [System.Text.Encoding]::UTF8.GetBytes($String) }
      FromFile {
        $File = Get-Item $File
        if($File){
          [System.IO.File]::ReadAllBytes($File)
        }
      }
    }
  }
}
