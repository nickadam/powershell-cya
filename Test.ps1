. .\Cya.ps1

$Test = "Get-SecureStringText from pipeline"
$Expected = "this is a string"
$Actual = ConvertTo-SecureString -String "this is a string" -AsPlainText | Get-SecureStringText
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Get-RandomString -Length"
$Expected = 128
$Actual = (Get-RandomString -Length 128).length
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Get-RandomString"
$Expected = 64
$Actual = (Get-RandomString).length
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Get-Base64FromFile -File"
$Expected = "VGhpcyBpcyBhIHRlc3QNCg=="
$TempFile = New-TemporaryFile
"This is a test" | Out-File -Encoding Default $TempFile
$Actual = Get-Base64FromFile -File $TempFile
Remove-Item $TempFile
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Get-Sha256Hash -File"
$Expected = "07849dc26fcbb2f3bd5f57bdf214bae374575f1bd4e6816482324799417cb379"
$TempFile = New-TemporaryFile
"This is a test" | Out-File -Encoding Default $TempFile
$Actual = Get-Sha256Hash -File $TempFile
Remove-Item $TempFile
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Get-Sha256Hash -File -Salt"
$Expected = "b51e131083f00ccde8806c220dd40d82e9414f071a5d7f84dba1722d8e1ebe88"
$TempFile = New-TemporaryFile
"This is a test" | Out-File -Encoding Default $TempFile
$Actual = Get-Sha256Hash -File $TempFile -Salt "This is a salt"
Remove-Item $TempFile
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Get-Sha256Hash -String"
$Expected = "4e9518575422c9087396887ce20477ab5f550a4aa3d161c5c22a996b0abb8b35"
$Actual = Get-Sha256Hash -String "This is a string"
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Get-Sha256Hash -String -Salt"
$Expected = "a67ffa434b436d8cf1ca7e33b51863866c8bd277e97604383745abd558cb1dfe"
$Actual = Get-Sha256Hash -String "This is a string" -Salt "This is a salt"
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}
