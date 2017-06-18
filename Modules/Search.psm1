$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-LocalizedData -BindingVariable Strings -BaseDirectory $currentPath\..\Localized -FileName Strings.psd1 -UICulture en-US

function Find-SpotifyItem {
    [cmdletbinding(DefaultParameterSetName = "SpecificCountry")]
    param(
        [parameter(Mandatory)]
        [string]
        $Filter,

        [parameter()]
        [ValidateSet('artist', 'playlist', 'album', 'track')]
        [string[]]
        $Type,

        [parameter(ParameterSetName = "MyCountry")]
        [switch]
        $LimitToMyCountry,

        [parameter(ParameterSetName = "SpecificCountry")]
        [string]
        $CountryCode,

        [parameter()]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter()]
        [int32]
        $Offset,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/search"
        $Query = @("q=$([System.Web.HttpUtility]::UrlEncode($Filter))")

        if ($PSBoundParameters.ContainsKey("Type")) {
            $Query += "type=$($Type -join ',')"
        }

        if ($PSBoundParameters.ContainsKey("Limit")) {
            $Query += "limit=$Limit"
        }

        if ($PSBoundParameters.ContainsKey("Offset")) {
            $Query += "offset=$Offset"
        }
        
        if ($PSBoundParameters.ContainsKey("LimitToMyCountry")) {
            $Query += "market=from_token"
        }

        if ($PSBoundParameters.ContainsKey("CountryCode")) {
            $Query += "market=$CountryCode"
        }

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get
    }
}

function Find-SpotifyArtist {
    [cmdletbinding(DefaultParameterSetName = "SpecificCountry")]
    param(
        [parameter(Mandatory)]
        [string]
        $Filter,

        [parameter(ParameterSetName = "MyCountry")]
        [switch]
        $LimitToMyCountry,

        [parameter(ParameterSetName = "SpecificCountry")]
        [string]
        $CountryCode,

        [parameter()]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter()]
        [int32]
        $Offset,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        Find-SpotifyItem @PSBoundParameters -Type artist  | select -ExpandProperty artists | select -ExpandProperty items
    }
}

function Find-SpotifyTrack {
    [cmdletbinding(DefaultParameterSetName = "SpecificCountry")]
    param(
        [parameter(Mandatory)]
        [string]
        $Filter,

        [parameter(ParameterSetName = "MyCountry")]
        [switch]
        $LimitToMyCountry,

        [parameter(ParameterSetName = "SpecificCountry")]
        [string]
        $CountryCode,

        [parameter()]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter()]
        [int32]
        $Offset,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        Find-SpotifyItem @PSBoundParameters -Type track  | select -ExpandProperty tracks | select -ExpandProperty items
    }
}

function Find-SpotifyAlbum {
    [cmdletbinding(DefaultParameterSetName = "SpecificCountry")]
    param(
        [parameter(Mandatory)]
        [string]
        $Filter,

        [parameter(ParameterSetName = "MyCountry")]
        [switch]
        $LimitToMyCountry,

        [parameter(ParameterSetName = "SpecificCountry")]
        [string]
        $CountryCode,

        [parameter()]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter()]
        [int32]
        $Offset,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        Find-SpotifyItem @PSBoundParameters -Type album  | select -ExpandProperty albums | select -ExpandProperty items
    }
}

function Find-SpotifyPlaylist {
    [cmdletbinding(DefaultParameterSetName = "SpecificCountry")]
    param(
        [parameter(Mandatory)]
        [string]
        $Filter,

        [parameter(ParameterSetName = "MyCountry")]
        [switch]
        $LimitToMyCountry,

        [parameter(ParameterSetName = "SpecificCountry")]
        [string]
        $CountryCode,

        [parameter()]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter()]
        [int32]
        $Offset,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        Find-SpotifyItem @PSBoundParameters -Type playlist  | select -ExpandProperty playlists | select -ExpandProperty items
    }
}

function Get-SpotifyArtist {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]
        $Id,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri "$($Session.RootUrl)/artists/$Id" `
            -Method Get
    }
}

function Get-SpotifyAlbum {
    [cmdletbinding(DefaultParameterSetName = "Album")]
    param(
        [parameter(Mandatory, ParameterSetName = "Album")]
        [string]
        $Id,

        [parameter(Mandatory, ParameterSetName = "Artist")]
        [string]
        $ArtistId,

        [parameter(ParameterSetName = "Artist")]
        [ValidateSet('album', 'single', 'appears_on', 'compilation')]
        [string[]]
        $Type,

        [parameter(ParameterSetName = "Artist")]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter(ParameterSetName = "Artist")]
        [int32]
        $Offset,

        [parameter()]
        [string]
        $CountryCode,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        if ($PSBoundParameters.ContainsKey("Id")) {
            $Url = "$($Session.RootUrl)/albums/$Id"

            $Query = @()

            if ($PSBoundParameters.ContainsKey("CountryCode")) {
                $Query += "market=$CountryCode"
            }

            if ($Query.Count -gt 0) {
                $Url += "?$($Query -join '&')"
            }

            Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get
        }

        if ($PSBoundParameters.ContainsKey("ArtistId")) {
            $Url = "$($Session.RootUrl)/artists/$ArtistId/albums"

            $Query = @()

            if ($PSBoundParameters.ContainsKey("Type")) {
                $Query += "album_type=$($Type -join ',')"
            }

            if ($PSBoundParameters.ContainsKey("Limit")) {
                $Query += "limit=$Limit"
            }

            if ($PSBoundParameters.ContainsKey("Offset")) {
                $Query += "offset=$Offset"
            }

            if ($PSBoundParameters.ContainsKey("CountryCode")) {
                $Query += "market=$CountryCode"
            }

            if ($Query.Count -gt 0) {
                $Url += "?$($Query -join '&')"
            }
         
            Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get | select -ExpandProperty items
        }
    }
}

function Get-SpotifyTrack {
    [cmdletbinding(DefaultParameterSetName = "Track")]
    param(
        [parameter(Mandatory, ParameterSetName = "Track")]
        [string]
        $Id,

        [parameter(Mandatory, ParameterSetName = "Album")]
        [string]
        $AlbumId,

        [parameter(Mandatory, ParameterSetName = "Playlist")]
        [string]
        $PlaylistId,

        [parameter(Mandatory, ParameterSetName = "Playlist")]
        [string]
        $UserId,

        [parameter(ParameterSetName = "Playlist")]
        [string]
        $Fields,

        [parameter(ParameterSetName = "Playlist")]
        [parameter(ParameterSetName = "Album")]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter(ParameterSetName = "Playlist")]
        [parameter(ParameterSetName = "Album")]
        [int32]
        $Offset,

        [parameter()]
        [string]
        $CountryCode,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        if ($PSBoundParameters.ContainsKey("Id")) {
            $Url = "$($Session.RootUrl)/tracks/$Id"

            $Query = @()

            if ($PSBoundParameters.ContainsKey("CountryCode")) {
                $Query += "market=$CountryCode"
            }

            if ($Query.Count -gt 0) {
                $Url += "?$($Query -join '&')"
            }

            Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get
        }

        if ($PSBoundParameters.ContainsKey("AlbumId")) {
            $Url = "$($Session.RootUrl)/albums/$AlbumId/tracks"

            $Query = @()

            if ($PSBoundParameters.ContainsKey("Limit")) {
                $Query += "limit=$Limit"
            }

            if ($PSBoundParameters.ContainsKey("Offset")) {
                $Query += "offset=$Offset"
            }

            if ($PSBoundParameters.ContainsKey("CountryCode")) {
                $Query += "market=$CountryCode"
            }

            if ($Query.Count -gt 0) {
                $Url += "?$($Query -join '&')"
            }
         
            Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get | select -ExpandProperty items
        }

        if ($PSBoundParameters.ContainsKey("PlaylistId")) {
            $Url = "$($Session.RootUrl)/users/$UserId/Playlists/$PlaylistId/tracks"

            $Query = @()

            if ($PSBoundParameters.ContainsKey("Limit")) {
                $Query += "limit=$Limit"
            }

            if ($PSBoundParameters.ContainsKey("Offset")) {
                $Query += "offset=$Offset"
            }

            if ($PSBoundParameters.ContainsKey("CountryCode")) {
                $Query += "market=$CountryCode"
            }

            if ($PSBoundParameters.ContainsKey("Fields")) {
                $Query += "fields=$Fields"
            }

            if ($Query.Count -gt 0) {
                $Url += "?$($Query -join '&')"
            }
         
            Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get | select -ExpandProperty items
        }
    }
}

function Get-SpotifyArtistTopTracks {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]
        $Id,

        [parameter()]
        [string]
        $CountryCode,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/artists/$Id/top-tracks"

        $Query = @()

        if ($PSBoundParameters.ContainsKey("CountryCode")) {
            $Query += "country=$CountryCode"
        }

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get | select -ExpandProperty tracks
    }
}

function Get-SpotifyRelatedArtists {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]
        $Id,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/artists/$Id/related-artists"

        $Query = @()

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get | select -ExpandProperty artists
    }
}