$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-LocalizedData -BindingVariable Strings -BaseDirectory $currentPath\..\Localized -FileName Strings.psd1 -UICulture en-US

function Get-SpotifyFeaturedPlaylists {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $Locale,

        [parameter()]
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
        [datetime]
        $Timestamp = (get-date),

        [parameter()]
        $Session = $Global:SpotifySession
    )

    begin {
        if (!$Session) {
            Write-Error $Strings["SessionNotFound"] -TargetObject $Session -RecommendedAction "Connect-Spotify"
        }

        Assert-AuthToken -Session $Session
    }

    process {
        $Url = "$($Session.RootUrl)/browse/featured-playlists"

        $Query = @()

        if ($PSBoundParameters.ContainsKey("CountryCode")) {
            $Query += "country=$CountryCode"
        }

        if ($PSBoundParameters.ContainsKey("Locale")) {
            $Query += "locale=$Locale"
        }

        if ($PSBoundParameters.ContainsKey("Limit")) {
            $Query += "limit=$Limit"
        }

        if ($PSBoundParameters.ContainsKey("Offset")) {
            $Query += "offset=$Offset"
        }

        $query += [string]::format("Timestamp={0}", [System.Web.HttpUtility]::UrlEncode($Timestamp.ToString("O").Split('.')[0]))

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        (Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get).playlists.items | select id, @{N = "userid"; e = {$_.owner.id}} | Get-SpotifyPlaylist
    }
}

function Get-SpotifyNewReleases {
    [cmdletbinding()]
    param(
        [parameter()]
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
        $Url = "$($Session.RootUrl)/browse/new-releases"

        $Query = @()

        if ($PSBoundParameters.ContainsKey("CountryCode")) {
            $Query += "country=$CountryCode"
        }

        if ($PSBoundParameters.ContainsKey("Limit")) {
            $Query += "limit=$Limit"
        }

        if ($PSBoundParameters.ContainsKey("Offset")) {
            $Query += "offset=$Offset"
        }

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        (Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get).albums.Items | Get-SpotifyAlbum
    }
}

function Get-SpotifyCategory {
    [cmdletbinding(DefaultParameterSetName = "List")]
    param(
        [parameter(Mandatory, ParameterSetName = "Id")]
        [string]
        $Id,

        [parameter()]
        [string]
        $Locale,

        [parameter()]
        [string]
        $CountryCode,

        [parameter(ParameterSetName = "List")]
        [ValidateRange(1, 50)]
        [int32]
        $Limit,

        [parameter(ParameterSetName = "List")]
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
        $Url = "$($Session.RootUrl)/browse/categories"

        $Query = @()

        if ($PSBoundParameters.ContainsKey("CountryCode")) {
            $Query += "country=$CountryCode"
        }

        if ($PSBoundParameters.ContainsKey("Locale")) {
            $Query += "locale=$Locale"
        }

        if ($PSBoundParameters.ContainsKey("Limit")) {
            $Query += "limit=$Limit"
        }

        if ($PSBoundParameters.ContainsKey("Offset")) {
            $Query += "offset=$Offset"
        }

        if ($PSBoundParameters.ContainsKey("Id")) {
            $Url += "/$Id"
        }

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        $Categories = (Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get).categories

        

        if (($Categories | gm | select -ExpandProperty Name) -contains "items") {
            $categories = $Categories.Items
        }
        
        $Categories | % {
            New-Object PSSpotify.Category -Property @{
                Name  = $_.Name
                Url   = $_.href
                Id    = $_.Id
                Icons = $_.icons
            }
        }
    }
}

function Get-SpotifyRecommendation {
    [cmdletbinding()]
    param(
        [parameter()]
        [string[]]
        $SeedArtist,

        [parameter()]
        [string[]]
        $SeedTrack,

        [parameter()]
        [string]
        $CountryCode,

        [parameter()]
        [ValidateRange(1, 100)]
        [int32]
        $Limit,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Max_acousticness,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Min_acousticness,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Target_acousticness,
        
        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Max_danceability,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Min_danceability,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Target_danceability,
        
        [parameter()]
        [int32]
        $Max_duration_ms,

        [parameter()]
        [int32]
        $Min_duration_ms,

        [parameter()]
        [int32]
        $Target_duration_ms,
        
        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Max_energy,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Min_energy,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Target_energy,
        
        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Max_instrumentalness,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Min_instrumentalness,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Target_instrumentalness,
        
        [parameter()]
        [int32]
        $Max_key,

        [parameter()]
        [int32]
        $Min_key,

        [parameter()]
        [int32]
        $Target_key,
        
        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Max_liveness,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Min_liveness,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Target_liveness,
        
        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Max_loudness,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Min_loudness,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Target_loudness,
        
        [parameter()]
        [ValidateRange(0, 1)]
        [int32]
        $Max_mode,

        [parameter()]
        [ValidateRange(0, 1)]
        [int32]
        $Min_mode,

        [parameter()]
        [ValidateRange(0, 1)]
        [int32]
        $Target_mode,
        
        [parameter()]
        [ValidateRange(0, 100)]
        [int32]
        $Max_popularity,

        [parameter()]
        [ValidateRange(0, 100)]
        [int32]
        $Min_popularity,

        [parameter()]
        [ValidateRange(0, 100)]
        [int32]
        $Target_popularity,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Max_speechiness,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Min_speechiness,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Target_speechiness,

        [parameter()]
        [double]
        $Max_tempo,

        [parameter()]
        [double]
        $Min_tempo,

        [parameter()]
        [double]
        $Target_tempo,

        [parameter()]
        [int32]
        $Max_time_signature,

        [parameter()]        
        [int32]
        $Min_time_signature,

        [parameter()]        
        [int32]
        $Target_time_signature,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Max_valence,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Min_valence,

        [parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Target_valence,
        
        [parameter()]
        $Session = $Global:SpotifySession
    )

    DynamicParam {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $ParameterName = 'SeedGenre'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false
        $AttributeCollection.Add($ParameterAttribute)
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute(Get-SpotifyRecommendationGenres)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributeCollection)
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
        $Url = "$($Session.RootUrl)/recommendations"

        $Query = @()

        if ($PSBoundParameters.ContainsKey("CountryCode")) {
            $Query += "market=$CountryCode"
        }

        if ($PSBoundParameters.ContainsKey("Limit")) {
            $Query += "limit=$Limit"
        }

        $TotalSeeds = $SeedArtist.count + $SeedTrack.Count + $PSBoundParameters["SeedGenre"].count

        if ($TotalSeeds -eq 0 -or $TotalSeeds -gt 5) {
            throw "number of seeds may not exceed 5 in any combination"
        }

        if ($PSBoundParameters.ContainsKey("SeedArtist")) {
            $Query += "seed_artists=$($SeedArtist -join ',')"
        }

        if ($PSBoundParameters.ContainsKey("SeedTrack")) {
            $Query += "seed_tracks=$($SeedTrack -join ',')"
        }

        if ($PSBoundParameters.ContainsKey("SeedGenre")) {
            $Query += "seed_genres=$($PSBoundParameters["SeedGenre"] -join ',')"
        }

        @("acousticness", "danceability", "duration_ms", "energy", "instrumentalness", "key", "liveness", "loudness", "mode", "popularity", "speechiness", "tempo", "time_signature", "valence").foreach( {
                $type = $_
                @("max", "min", "target").ForEach( {
                        if ($PSBoundParameters.ContainsKey("$($_)_$type")) {
                            $Query += "$($_)_$type=$((Get-Variable -Name "$($_)_$type" -ValueOnly) -join ',')"
                        }})
            })

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        (Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get).tracks | Get-SpotifyTrack
    }
}

function Get-SpotifyRecommendationGenres {
    [cmdletbinding()]
    param(
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
        $Url = "$($Session.RootUrl)/recommendations/available-genre-seeds"


        [PSSpotify.Genre[]](Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get).Genres
    }
}