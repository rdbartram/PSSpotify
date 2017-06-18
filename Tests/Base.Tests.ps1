[CmdletBinding()]
param()

$script:moduleRoot = Split-Path $PSScriptRoot -Parent

Describe 'Script Analyzer Check' {
    Context -Name 'No errors or warnings from Script Analyzer' {
        Invoke-ScriptAnalyzer -Path $script:moduleRoot -recurse | should be $null
    }
}
