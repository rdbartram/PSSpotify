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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }
    process {
        (Find-SpotifyItem @PSBoundParameters -Type artist).artists.items | Get-SpotifyArtist
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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
        (Find-SpotifyItem @PSBoundParameters -Type track).tracks.items | Get-SpotifyTrack
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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
        (Find-SpotifyItem @PSBoundParameters -Type album).albums.items | Get-SpotifyAlbum
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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
        (Find-SpotifyItem @PSBoundParameters -Type playlist).playlists.items | select id, @{N = "userid"; e = {$_.owner.id}} | Get-SpotifyPlaylist
    }
}

function Get-SpotifyArtist {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]
        $Id,

        [parameter()]
        $Session = $Global:SpotifySession,

        [parameter()]
        [switch]
        $Simplified
    )

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
        $Artist = Invoke-RestMethod -Headers $Session.Headers `
            -Uri "$($Session.RootUrl)/artists/$Id" `
            -Method Get

        $a = New-Object PSSpotify.Artist -Property @{
            markets     = $Artist.available_markets
            ExternalUrl = $Artist.href
            id          = $Artist.id
            name        = $Artist.name
            type        = $Artist.type
            uri         = $Artist.uri
        }
        if ([bool]$Simplified -eq $false) {
            $a.Popularity = $Artist.popularity
            $a.Images = $Artist.Images
            $a.Followers = $Artist.Followers.total
            $a.Genres = $Artist.Genres
        }

        $a
    }
}

function Get-SpotifyAlbum {
    [cmdletbinding(DefaultParameterSetName = "Album")]
    param(
        [parameter(Mandatory, ParameterSetName = "Album", ValueFromPipelineByPropertyName)]
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
        $Session = $Global:SpotifySession,

        [parameter()]
        [switch]
        $Simplified
    )

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
        if ($PSBoundParameters.ContainsKey("Id")) {
            $Url = "$($Session.RootUrl)/albums/$Id"

            $Query = @()

            if ($PSBoundParameters.ContainsKey("CountryCode")) {
                $Query += "market=$CountryCode"
            }

            if ($Query.Count -gt 0) {
                $Url += "?$($Query -join '&')"
            }

            $Output = Invoke-RestMethod -Headers $Session.Headers `
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
         
            $Output = (Invoke-RestMethod -Headers $Session.Headers `
                    -Uri $Url `
                    -Method Get).items
        }

        Foreach ($Album in $Output) {

            $a = New-Object PSSpotify.Album -Property @{
                markets     = $Album.available_markets
                ExternalUrl = $Album.href
                id          = $Album.id
                name        = $Album.name
                popularity  = $Album.popularity
                type        = $Album.type
                uri         = $Album.uri
                Images      = $Album.Images
                Label       = $Album.Label
            }
            
            if ([bool]$Simplified -eq $false) {
                $a.Genres = $Album.Genres
                $a.Tracks = ($Album.Tracks.items | ? {$_.id -ne $null} | Get-SpotifyTrack -Simplified)
                $a.Artists = ($Album.Artists | ? {$_.id -ne $null} | Get-SpotifyArtist -Simplified)
                $a.ReleaseDate = $Album.release_date
                $a.ReleaseDatePrecision = $Album.release_date_precision
                $a.Copyrights = [PSSpotify.CopyRight[]]$Album.copyrights
                $a.AlbumType = $Album.album_type
            }

            $a
        }
    }
}

function Get-SpotifyTrack {
    [cmdletbinding(DefaultParameterSetName = "Track")]
    param(
        [parameter(Mandatory, ParameterSetName = "Track", ValueFromPipelineByPropertyName)]
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
        $Session = $Global:SpotifySession,

        [parameter()]
        [switch]
        $Simplified
    )

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }
    
    process {
        if ($PSBoundParameters.ContainsKey("Id")) {
            $Url = "$($Session.RootUrl)/tracks/$Id"

            $Query = @()

            if ($PSBoundParameters.ContainsKey("CountryCode")) {
                $Query += "market=$CountryCode"
            }

            if ($Query.Count -gt 0) {
                $Url += "?$($Query -join '&')"
            }

            $Output = Invoke-RestMethod -Headers $Session.Headers `
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
         
            $Output = (Invoke-RestMethod -Headers $Session.Headers `
                    -Uri $Url `
                    -Method Get).items
        }

        if ($PSBoundParameters.ContainsKey("PlaylistId")) {
            $Url = "$($Session.RootUrl)/users/$UserId/playlists/$PlaylistId/tracks"

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
         
            $Output = (Invoke-RestMethod -Headers $Session.Headers `
                    -Uri $Url `
                    -Method Get).items.track
            
        }

        Foreach ($Track in $Output) {
            $t = New-Object PSSpotify.Track -Property @{
                Album       = ($Track.Album | ? {$_.id -ne $null} | Get-SpotifyAlbum -Simplified)
                Artists     = ($Track.Artists | ? {$_.id -ne $null} | Get-SpotifyArtist -Simplified)
                markets     = $Track.available_markets
                discnumber  = $Track.disc_number
                durationms  = $Track.duration_ms
                explict     = $Track.explict
                ExternalUrl = $Track.href
                id          = $Track.id
                name        = $Track.name
                previewurl  = $Track.preview_url
                tracknumber = $Track.track_number
                type        = $Track.type
                uri         = $Track.uri
            }
            if ([bool]$Simplified -eq $false) {
                $t.Popularity = $Track.popularity
                $t.ExternalIds = $Track.External_Ids
            }

            $t
        }
    }
}

function Get-SpotifyArtistTopTracks {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Id,

        [parameter()]
        [string]
        $CountryCode,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session

        if ([string]::IsNullOrEmpty($CountryCode)) {
            $CountryCode = $Global:SpotifySession.CurrentUser.Country
        }
    }

    process {
        $Url = "$($Session.RootUrl)/artists/$Id/top-tracks"

        $Query = @("country=$CountryCode")

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        (Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get).tracks | Get-SpotifyTrack
    }
}

function Get-SpotifyRelatedArtists {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $Id,

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
        $Url = "$($Session.RootUrl)/artists/$Id/related-artists"

        $Query = @()

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        (Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get).artists | Get-SpotifyArtist
    }
}