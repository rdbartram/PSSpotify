$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-LocalizedData -BindingVariable Strings -BaseDirectory $currentPath\..\Localized -FileName Strings.psd1 -UICulture en-US

function Get-SpotifyPlaylist {
    [cmdletbinding(DefaultParameterSetName = "My")]
    param(
        [parameter(ParameterSetName = "User")]
        [string]
        $Id,

        [parameter(Mandatory, ParameterSetName = "User")]
        [string]
        $UserId,

        [parameter(ParameterSetName = "My")]
        [switch]
        $My,

        [parameter(ParameterSetName = "User")]
        [string]
        $CountryCode,

        [parameter(ParameterSetName = "User")]
        [string]
        $Fields,

        [parameter(ParameterSetName = "User")]
        [parameter(ParameterSetName = "My")]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter(ParameterSetName = "User")]
        [parameter(ParameterSetName = "My")]
        [int32]
        $Offset,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = $($Session.RootUrl)

        if ($PSBoundParameters.ContainsKey("My")) {
            $Url += "/me/playlists"
        }

        if ($PSBoundParameters.ContainsKey("UserId")) {
            $Url += "/users/$UserId/playlists"
        }

        $Query = @()

        if ($PSBoundParameters.ContainsKey("Id")) {
            $Url += "/$Id"

            if ($PSBoundParameters.ContainsKey("CountryCode")) {
                $Query += "market=$CountryCode"
            }

            if ($PSBoundParameters.ContainsKey("Fields")) {
                $Query += "fields=$Fields"
            }
        }
        else {
            if ($PSBoundParameters.ContainsKey("Limit")) {
                $Query += "limit=$Limit"
            }

            if ($PSBoundParameters.ContainsKey("Offset")) {
                $Query += "offset=$Offset"
            }
        }

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get | select -ExpandProperty items
    }
}

function New-SpotifyPlaylist {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $UserId = $Global:SpotifySession.CurrentUser.id,

        [parameter(Mandatory)]
        [String]
        $Name,

        [parameter()]
        [bool]
        $IsPublic,

        [parameter()]
        [bool]
        $IsCollaborative,

        [parameter()]
        [string]
        $Description,

        [parameter()]
        [string[]]
        $Tracks,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/users/$UserId/playlists"

        $Body = @{
            name = $Name
        }

        if ($PSBoundParameters.ContainsKey("IsPublic")) {
            $Body.Add("public", $IsPublic)
        }
        if ($PSBoundParameters.ContainsKey("IsCollaborative")) {
            $Body.Add("collaborative", $IsCollaborative)
            if ($IsCollaborative) {
                $Body["public"] = $false
            }
        }

        $Response = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Post `
            -Body (ConvertTo-Json $Body)

        if ($PSBoundParameters.ContainsKey("Tracks")) {
            $response | Add-SpotifyTracktoPlaylist -Tracks $Tracks
        }
    }
}

function Add-SpotifyTracktoPlaylist {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $UserId = $Global:SpotifySession.CurrentUser.id,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Id,

        [parameter(Mandatory)]
        [string[]]
        $Tracks,

        [parameter()]
        [int32]
        $Position,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/users/$UserId/playlists/$Id/tracks"

        $Body = @{uris = $Tracks}

        if ($PSBoundParameters.ContainsKey("Position")) {
            $Body.Add("position", $Position)
        }

        $Response = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Post `
            -Body (ConvertTo-Json $Body)
    }
}

function Set-SpotifyPlaylistTrackPosition {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $UserId = $Global:SpotifySession.CurrentUser.id,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Id,

        [parameter(Mandatory)]
        [int32]
        $StartPosition,

        [parameter()]
        [int32]
        $NumberofTracks,

        [parameter()]
        [int32]
        $EndPosition,

        [parameter(ValueFromPipelineByPropertyName)]
        [Alias("snapshot_id")]
        [String]
        $SnapshotId,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/users/$UserId/playlists/$id/tracks"

        $Body = @{
            range_start   = $StartPosition
            insert_before = $EndPosition
        }

        if ($PSBoundParameters.ContainsKey("NumberofTracks")) {
            $Body.Add("range_length", $NumberofTracks)
        }

        if ($PSBoundParameters.ContainsKey("SnapshotId")) {
            $Body.Add("snapshot_id", $SnapshotId)
        }


        $Response = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Put `
            -Body (ConvertTo-Json $Body)
    }
}

function Set-SpotifyPlaylist {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $UserId = $Global:SpotifySession.CurrentUser.id,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Id,

        [parameter()]
        [String]
        $Name,

        [parameter()]
        [bool]
        $IsPublic,

        [parameter()]
        [bool]
        $IsCollaborative,

        [parameter()]
        [string]
        $Description,

        [parameter()]
        [string[]]
        $Tracks,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/users/$UserId/playlists/$id"

        $Body = @{}

        if ($PSBoundParameters.ContainsKey("Name")) {
            $Body.Add("name", $Name)
        }

        if ($PSBoundParameters.ContainsKey("Tracks")) {
            $Response = Invoke-RestMethod -Headers $Session.Headers `
                -Uri "$Url/tracks" `
                -Method Put `
                -Body (ConvertTo-Json @{Uris = $Tracks})
        }

        if ($PSBoundParameters.ContainsKey("IsPublic")) {
            $Body.Add("public", $IsPublic)
        }
        if ($PSBoundParameters.ContainsKey("IsCollaborative")) {
            $Body.Add("collaborative", $IsCollaborative)
            if ($IsCollaborative) {
                $Body["public"] = $false
            }
        }

        $Response = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Put `
            -Body (ConvertTo-Json $Body)
    }
}

function Randomize-SpotifyPlaylistTrackOrder {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $UserId = $Global:SpotifySession.CurrentUser.id,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Id,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Tracks = Get-SpotifyTrack -PlaylistId $Id -UserId $UserId

        Set-SpotifyPlaylist @PSBoundParameters -Tracks ($Tracks.uri | Get-Random -Count $Tracks.Count)
    }
}

function Remove-SpotifyTrackfromPlaylist {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $UserId = $Global:SpotifySession.CurrentUser.id,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]
        $Id,

        [parameter(Mandatory, ParameterSetName = "Uris")]
        [string[]]
        $Tracks,

        [parameter(Mandatory, ParameterSetName = "UrisandPosition")]
        [hashtable]
        $TracksatPosition,

        [parameter(Mandatory, ParameterSetName = "Positions")]
        [int32[]]
        $TrackPositions,

        [parameter(Mandatory, ParameterSetName = "Positions", ValueFromPipelineByPropertyName)]
        [parameter(ParameterSetName = "Uris", ValueFromPipelineByPropertyName)]
        [parameter(ParameterSetName = "UrisandPosition", ValueFromPipelineByPropertyName)]
        [Alias("snapshot_id")]
        [String]
        $SnapshotId,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/users/$UserId/playlists/$Id"

        $Body = @{}

        if ($PSBoundParameters.ContainsKey("Tracks")) {
            $FormattedTracks = @()
            $Tracks.foreach( {
                    $FormattedTracks += [PSCustomObject]@{
                        uri = $_
                    }
                })
            $Body.Add("tracks", $FormattedTracks)
        }

        if ($PSBoundParameters.ContainsKey("TracksatPosition")) {
            $tracks = @()

            $TracksatPosition.Keys.foreach( {
                    $Tracks += [PSCustomObject]@{
                        uri       = $_
                        positions = $TracksatPosition[$_]
                    }
                })
            $Body.Add("tracks", $Tracks)
        }

        if ($PSBoundParameters.ContainsKey("TrackPositions")) {
            $Body.Add("positions", $TrackPositions)
        }

        if ($PSBoundParameters.ContainsKey("SnapshotId")) {
            $Body.Add("snapshot_id", $SnapshotId)
        }

        $Response = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Post `
            -Body (ConvertTo-Json $Body)
    }
}