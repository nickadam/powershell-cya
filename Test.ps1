. .\Cya.ps1

$Test = "Get-ProtectionStatus EnvVar Protected"
$Expected = "Protected"
$TempVar = [PSCustomObject]@{"Name" = "cyatestvar"; "Value" = "this is a string"}
$Cipherbundle = $TempVar | ConvertTo-Cipherbundle -Key "this is a key"
$Env:cyatestvar = "this is a different string"
$Actual = ($Cipherbundle | Get-ProtectionStatus).Status
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Get-ProtectionStatus EnvVar Unprotected"
$Expected = "Unprotected"
$TempVar = [PSCustomObject]@{"Name" = "cyatestvar"; "Value" = "this is a string"}
$Cipherbundle = $TempVar | ConvertTo-Cipherbundle -Key "this is a key"
$Env:cyatestvar = "this is a string"
$Actual = ($Cipherbundle | Get-ProtectionStatus).Status
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Get-ProtectionStatus File Protected"
$Expected = "Protected"
$TempFile = New-TemporaryFile
"This is a test" | Out-File -Encoding Default $TempFile
$Cipherbundle = $TempFile | ConvertTo-Cipherbundle -Key "this is a key"
"This is a different file" | Out-File -Encoding Default $TempFile
$Actual = ($Cipherbundle | Get-ProtectionStatus).Status
Remove-Item $TempFile
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Get-ProtectionStatus File Unprotected"
$Expected = "Unprotected"
$TempFile = New-TemporaryFile
"This is a test" | Out-File -Encoding Default $TempFile
$Cipherbundle = $TempFile | ConvertTo-Cipherbundle -Key "this is a key"
$Actual = ($Cipherbundle | Get-ProtectionStatus).Status
Remove-Item $TempFile
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Confirm-CipherbundleFileHash Fails"
$Expected = $False
$TempFile = New-TemporaryFile
"This is a test" | Out-File -Encoding Default $TempFile
$Cipherbundle = $TempFile | ConvertTo-Cipherbundle -Key "this is a key"
"This is a different file" | Out-File -Encoding Default $TempFile
$Actual = Confirm-CipherbundleFileHash -Cipherbundle $Cipherbundle
Remove-Item $TempFile
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Confirm-CipherbundleFileHash"
$Expected = $True
$TempFile = New-TemporaryFile
"This is a test" | Out-File -Encoding Default $TempFile
$Cipherbundle = $TempFile | ConvertTo-Cipherbundle -Key "this is a key"
$Actual = Confirm-CipherbundleFileHash -Cipherbundle $Cipherbundle
Remove-Item $TempFile
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "ConvertTo-Cipherbundle ConvertFrom-Cipherbundle Many Files"
$Expected = "This is a test This is another test"
$TempFile = New-TemporaryFile
$TempFile2 = New-TemporaryFile
"This is a test" | Out-File -Encoding Default $TempFile
"This is another test" | Out-File -Encoding Default $TempFile2
$Cipherbundles = $TempFile, $TempFile2 | ConvertTo-Cipherbundle -Key "this is a key"
Remove-Item $TempFile
Remove-Item $TempFile2
$Cipherbundles | ConvertFrom-Cipherbundle -Key "this is a key" | Out-Null
$Actual = (Get-Content $TempFile) + " " + (Get-Content $TempFile2)
Remove-Item $TempFile
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "ConvertTo-Cipherbundle ConvertFrom-Cipherbundle File"
$Expected = "This is a test"
$TempFile = New-TemporaryFile
"This is a test" | Out-File -Encoding Default $TempFile
$Cipherbundle = $TempFile | ConvertTo-Cipherbundle -Key "this is a key"
Remove-Item $TempFile
$Cipherbundle | ConvertFrom-Cipherbundle -Key "this is a key" | Out-Null
$Actual = Get-Content $TempFile
Remove-Item $TempFile
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "ConvertTo-Cipherbundle ConvertFrom-Cipherbundle empty string"
$Expected = $null
$Actual = "" | ConvertTo-Cipherbundle -Key "this is a key" | ConvertFrom-Cipherbundle -Key "this is a key"
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "ConvertTo-Cipherbundle ConvertFrom-Cipherbundle String"
$Expected = "this is a string"
$Actual = [PSCustomObject]@{"Name" = "test"; "Value" = "this is a string"} | ConvertTo-Cipherbundle -Key "this is a key" | ConvertFrom-Cipherbundle -Key "this is a key"
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


$Test = "Get-EncryptedAnsibleVaultString Get-DecryptedAnsibleVaultString"
$Expected = "this is a string"
$Actual = Get-DecryptedAnsibleVaultString -CipherTextString (Get-EncryptedAnsibleVaultString -String "this is a string" -Key "this is a key") -Key "this is a key"
if($Actual -ne $Expected){
  Write-Error "$Test failed."
  "Expected - $Expected"
  "Actual - $Actual"
  " "
}


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
