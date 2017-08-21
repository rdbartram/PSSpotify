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

        [parameter(Mandatory, ParameterSetName = "Category")]
        [string]
        $CategoryId,

        [parameter(ParameterSetName = "My")]
        [switch]
        $My,

        [parameter(ParameterSetName = "My")]
        [string]
        $Name,

        [parameter(ParameterSetName = "User")]
        [string]
        $CountryCode,

        [parameter(ParameterSetName = "User")]
        [string]
        $Fields,

        [parameter(ParameterSetName = "User")]
        [parameter(ParameterSetName = "My")]
        [parameter(Mandatory, ParameterSetName = "Category")]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter(ParameterSetName = "User")]
        [parameter(ParameterSetName = "My")]
        [parameter(ParameterSetName = "Category")]
        [int32]
        $Offset,

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
        $Url = $($Session.RootUrl)

        if ($PSBoundParameters.ContainsKey("My")) {
            $Url += "/me/playlists"
        }

        if ($PSBoundParameters.ContainsKey("UserId")) {
            $Url += "/users/$UserId/playlists"
        }

        if ($PSBoundParameters.ContainsKey("CategoryId")) {
            $Url += "/browse/categories/$CategoryId/playlists"
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

        $Output = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get

        if ($My) {
            $Output = $Output.items | ? {[string]::IsNullOrEmpty($Name) -or $_.name -eq $Name}
        }

        Foreach ($Playlist in $Output) {
            $Playlist | Convertto-PlaylistObject @PSBoundParameters
        }
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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
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

        $P = $Response | Convertto-PlaylistObject

        if ($PSBoundParameters.ContainsKey("Tracks")) {
            $P | Add-SpotifyTracktoPlaylist -Tracks $Tracks
        }

        $P
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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
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
    [cmdletbinding(DefaultParameterSetName = "id")]
    param(
        [parameter(Mandatory, ParameterSetName = "id")]
        [string]
        $UserId,

        [parameter(Mandatory, ParameterSetName = "id")]
        [String]
        $Id,

        [parameter(Mandatory, ParameterSetName = "InputObject", ValueFromPipeline)]
        [PSSpotify.Playlist]
        $InputObject,

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
        [switch]
        $PassThru,

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
        if ($InputObject) {
            $id = $InputObject.Id
            $UserId = $InputObject.Owner.id
        }

        $Url = "$($Session.RootUrl)/users/$UserId/playlists/$id"

        $Body = @{}

        if ($PSBoundParameters.ContainsKey("Name")) {
            $Body.Add("name", $Name)
        }

        if ($PSBoundParameters.ContainsKey("Tracks")) {
            $TrackUrl = "$Url/tracks?uris=$($tracks -join ',')"

            $Response = Invoke-RestMethod -Headers $Session.Headers `
                -Uri $TrackUrl `
                -Method Put `
                -Body (ConvertTo-Json @{uris = $Tracks})
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

        if ($PSBoundParameters.ContainsKey("description")) {
            $Body.Add("description", $description)
        }

        $Response = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Put `
            -Body (ConvertTo-Json $Body)
        
        if ($PSBoundParameters.ContainsKey("PassThru")) {
            Get-SpotifyPlaylist -Id $id -UserId $UserId
        }
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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
        $Url = "$($Session.RootUrl)/users/$UserId/playlists/$Id/tracks"

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
            -Method delete `
            -Body (ConvertTo-Json $Body)
    }
}

Function Convertto-PlaylistObject {
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        $InputObject,

        [parameter()]
        [switch]
        $Simplified,

        [parameter(ValueFromRemainingArguments)]
        $Trash
    )

    process {
        $p = New-Object PSSpotify.Playlist -Property @{
            ExternalUrl   = $InputObject.href
            id            = $InputObject.id
            name          = $InputObject.name
            type          = $InputObject.type
            uri           = $InputObject.uri
            Images        = $InputObject.Images
            Owner         = Get-SpotifyProfile -Id $InputObject.Owner.Id
            SnapshotId    = $InputObject.snapshot_id
            collaborative = $InputObject.collaborative
            public        = $InputObject.Public
        }

        if ([bool]$Simplified -eq $false) {
            $p.description = $InputObject.description
            $p.Followers = $InputObject.Followers
        }

        $p
    }

}