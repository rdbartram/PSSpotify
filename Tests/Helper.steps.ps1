Given 'DateTime is (?<datetime>.+)' {
    param($datetime)

    $datetime = [datetime]::Parse($datetime)
    $datetime | should -BeOfType datetime
}

When 'I convert DateTime to Epoch' {
    $convertedepoch = $datetime | convertto-epoch 
}

Then 'Epoch is (?<Epoch>.+)' {
    param($epoch)

    $convertedepoch | should -be $epoch
}

Given '(?<object>.+) is a (?<type>.+)' {
    param ($object, $type)

    invoke-command ([scriptblock]::create($object)) -ov object | should -BeOfType $type
}

When 'I convert (?<type>.+) to hashtable' {
    $Hash = $object | ConvertTo-Hashtable
}

Then 'Valid Hashtable is returned' {
    @($object) | % {
        $obj = $_
        $index = @($object).IndexOf($obj)
        $_ | gm | ? {$_.membertype -eq "noteproperty"} | select -ExpandProperty name| % {
            @($hash)[$index][$_] | should -be $obj."$_"
        }
    }
}