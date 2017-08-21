$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-LocalizedData -BindingVariable Strings -BaseDirectory $currentPath\..\Localized -FileName Strings.psd1 -UICulture en-US

function Get-SpotifyFollowedItem {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [ValidateSet("Artist")]
        [string]
        $Type,

        [parameter()]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter()]
        [string]
        $After,

        [parameter()]
        $Session = $Global:SpotifySession
    )
    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
        $Url = "$($Session.RootUrl)/me/following"

        $Query = @("type=$Type")

        if ($PSBoundParameters.ContainsKey("Limit")) {
            $Query += "limit=$Limit"
        }

        if ($PSBoundParameters.ContainsKey("After")) {
            $Query += "after=$after"
        }
        

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        (Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get).artists.items | Get-SpotifyArtist
    }
}

function Follow-SpotifyItem {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet("artist", "user", "playlist")]
        [string]
        $Type,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String[]]
        $Id,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    DynamicParam {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $ParameterName = 'OwnerId'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.ParameterSetName = "Playlist"
        $ParameterAttribute.Mandatory = $false
        $AttributeCollection.Add($ParameterAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        $ParameterName = 'Public'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.ParameterSetName = "Playlist"
        $ParameterAttribute.Mandatory = $false
        $AttributeCollection.Add($ParameterAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [boolean], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        

        return $RuntimeParameterDictionary
    }

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
        $Url = "$($Session.RootUrl)"

        if ($Type -eq "Playlist") {
            $Url += [string]::format("/users/{0}/playlists/{1}/followers", $PSBoundParameters["OwnerId"], $Id[0])

            $Body = @{}

            if ($PSBoundParameters["Public"]) {
                $Body.Add("public", $PSBoundParameters["Public"])
            }

            $Response = Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Put `
                -Body (ConvertTo-Json $Body)
        }
        else {
            $Url += "/me/following?type=$type&ids=$($id -join ',')"
            
            $Response = Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Put
        }
    }
}

function Unfollow-SpotifyItem {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet("artist", "user", "playlist")]
        [string]
        $Type,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String[]]
        $Id,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    DynamicParam {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        
        $ParameterName = 'OwnerId'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.ParameterSetName = "Playlist"
        $ParameterAttribute.Mandatory = $false
        $AttributeCollection.Add($ParameterAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        

        return $RuntimeParameterDictionary
    }

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
        $Url = $($Session.RootUrl)

        if ($Type -eq "Playlist") {
            $Url += [string]::format("/users/{0}/playlists/{1}/followers", $PSBoundParameters["OwnerId"], $Id[0])

            $Response = Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Delete
        }
        else {
            $Url += "/me/following?type=$type&ids=$($Id -join ',')"

            $Response = Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Delete
        }
    }
}

function Assert-SpotifyFollowing {
    [OutputType("Boolean")]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet("Artist", "User", "Playlist")]
        [string]
        $Type,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Id,

        [parameter()]
        [String]
        $UserId,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    DynamicParam {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        
        $ParameterName = 'OwnerId'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.ParameterSetName = "Playlist"
        $ParameterAttribute.Mandatory = $false
        $AttributeCollection.Add($ParameterAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        

        return $RuntimeParameterDictionary
    }

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
        If ($UserId.Count -eq 0) {
            $UserId = $Session.CurrentUser.Id
        }

        $Url = $($Session.RootUrl)

        $Query = @("ids=$($Id -join ',')")

        if ($Type -eq "Playlist") {
            $Url += [string]::format("/users/{0}/playlists/{1}/followers/contains", $PSBoundParameters["OwnerId"], $Id)

            $Query = "ids=$($Global:SpotifySession.CurrentUser.Id)"

            if ($Query.Count -gt 0) {
                $Url += "?$($Query -join '&')"
            }

            Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get
        }
        else {
            $Url += "/me/following/contains"

            $Query += "type=$type"

            

            if ($Query.Count -gt 0) {
                $Url += "?$($Query -join '&')"
            }

            Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get
        }
    }
}