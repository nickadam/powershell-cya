function Invoke-ChoicePrompt {
  param(
    [String]$Caption,
    [String]$Message,
    [Array]$Choices,
    [Int]$Default=0
  )
  $Choices = $Choices | ForEach-Object {"&" + $_}
  $Options = [System.Management.Automation.Host.ChoiceDescription[]] $Choices
  $Index = (Get-Host).UI.PromptForChoice($Caption, $Message, $Options, $Default)
  $Choices[$Index] -replace "^&", ""
}
