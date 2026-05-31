[CmdletBinding(PositionalBinding = $false)]
param(
  [string] $RemoteHost = "remote-target",
  [string] $RemoteRoot = "/home/hedu17/UVM_TEST",
  [string] $Dir = ".",
  [string] $Target = "help",
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $MakeArgs
)

$ErrorActionPreference = "Stop"

$expandedMakeArgs = @()
foreach ($arg in @($MakeArgs)) {
  if ($null -ne $arg) {
    $expandedMakeArgs += ($arg -split "," | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  }
}

$allMakeArgs = @($Target) + @($expandedMakeArgs)
$allMakeArgs = $allMakeArgs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

function Quote-Remote {
  param([string] $Value)
  return "'" + ($Value -replace "'", "'\''") + "'"
}

$remoteDir = if ($Dir -eq "." -or [string]::IsNullOrWhiteSpace($Dir)) {
  $RemoteRoot
} else {
  ($RemoteRoot.TrimEnd("/") + "/" + $Dir.TrimStart("./").Replace("\", "/"))
}

$quotedMakeArgs = ($allMakeArgs | ForEach-Object { Quote-Remote $_ }) -join " "
$cshCommand = "source ~/.cshrc; make $quotedMakeArgs"
$remoteCommand = "cd $(Quote-Remote $remoteDir) && csh -fc $(Quote-Remote $cshCommand)"

$sshOptions = @(
  "-o", "StrictHostKeyChecking=no",
  "-o", "UserKnownHostsFile=NUL",
  "-o", "GlobalKnownHostsFile=NUL"
)

& ssh @sshOptions $RemoteHost $remoteCommand
exit $LASTEXITCODE
