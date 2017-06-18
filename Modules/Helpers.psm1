function ConvertTo-Epoch {
    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline)]
        [DateTime]
        $Date
    )

    $Start = (Get-Date -Date "01/01/1970")
    [uint64](New-TimeSpan -Start $Start -End $Date).TotalMilliseconds
}