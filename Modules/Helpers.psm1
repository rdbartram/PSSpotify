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

function ConvertTo-Hashtable {
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process {
        if ($null -eq $InputObject) {
            return $null 
        }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable $object 
                }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject]) {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable $property.Value
            }

            $hash
        }
        else {
            $InputObject
        }
    }
}