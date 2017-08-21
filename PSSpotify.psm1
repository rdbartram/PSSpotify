$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-LocalizedData -BindingVariable Strings -BaseDirectory $currentPath\Localized -FileName Strings.psd1 -UICulture en-US

add-type -Language CSharp -TypeDefinition (Get-Content $currentPath\Types\Types.cs -Raw)
