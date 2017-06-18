$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-LocalizedData -BindingVariable Strings -BaseDirectory $currentPath\..\Localized -FileName Strings.psd1 -UICulture en-US

function Get-SpotifyProfile {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $Id,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = $($Session.RootUrl)

        if ([string]::IsNullOrEmpty($Id)) {
            $Url += "/me"
        }
        else {
            $Url += "/users/$Id"
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get
    }
}

function Get-SpotifyRecentlyPlayed {
    [cmdletbinding(DefaultParameterSetName = "After")]
    param(
        [parameter()]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter(ParameterSetName = "Before")]
        [DateTime]
        $Before,

        [parameter(ParameterSetName = "After")]
        [DateTime]
        $After,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/me/player/recently-played"
        $Query = @()

        if ($PSBoundParameters.ContainsKey("Limit")) {
            $Query += "limit=$Limit"
        }

        if ($PSBoundParameters.ContainsKey("Before")) {
            $Query += "before=$($Before | ConvertTo-Epoch)"
        }
        
        if ($PSBoundParameters.ContainsKey("After")) {
            $Query += "after=$($After | ConvertTo-Epoch))"
        }

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get | select -ExpandProperty items
    }
}

function Get-SpotifyTopArtist {
    [cmdletbinding()]
    param(
        [parameter()]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter()]
        [int32]
        $Offset,

        [parameter()]
        [ValidateSet('short_term', 'medium_term', 'long_term')]
        [String]
        $TimeRange,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/me/top/artists"
        $Query = @()

        if ($PSBoundParameters.ContainsKey("Limit")) {
            $Query += "limit=$Limit"
        }

        if ($PSBoundParameters.ContainsKey("Offset")) {
            $Query += "offset=$Offset"
        }
        
        if ($PSBoundParameters.ContainsKey("TimeRange")) {
            $Query += "time_range=$TimeRange"
        }

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get | select -ExpandProperty items
    }
}

function Get-SpotifyTopTrack {
    [cmdletbinding()]
    param(
        [parameter()]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter()]
        [int32]
        $Offset,

        [parameter()]
        [ValidateSet('short_term', 'medium_term', 'long_term')]
        [String]
        $TimeRange,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/me/top/tracks"
        $Query = @()

        if ($PSBoundParameters.ContainsKey("Limit")) {
            $Query += "limit=$Limit"
        }

        if ($PSBoundParameters.ContainsKey("Offset")) {
            $Query += "offset=$Offset"
        }
        
        if ($PSBoundParameters.ContainsKey("TimeRange")) {
            $Query += "time_range=$TimeRange"
        }

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get | select -ExpandProperty items
    }
}