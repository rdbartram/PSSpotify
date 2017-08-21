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

    begin {
        Assert-AuthToken -Session $Session
    }

    process {
        $Url = $($Session.RootUrl)

        if ([string]::IsNullOrEmpty($Id)) {
            $Url += "/me"
        }
        else {
            $Url += "/users/$Id"
        }

        $Profile = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get
        
        if ($Profile) {
            trap {
            }
            $UserProfile = New-Object PSSpotify.UserProfile -Property @{
                Country     = $Profile.country
                DisplayName = $Profile.display_name
                ExternalUrl = $Profile.href
                Followers   = $Profile.followers.total
                Id          = $Profile.id
                Images      = $Profile.Images
                Type        = $Profile.type
                Uri         = $Profile.uri
            }

            if (($Profile | gm).name.contains("birthdate")) {
                $UserProfile.Birthdate = $Profile.birthdate
                $UserProfile.Email = $Profile.email
                $UserProfile.Product = $Profile.product
            }

            $UserProfile
        }
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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {

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

        $RecentlyPlayed = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get

        $RecentlyPlayed.items.track | % {
            Get-SpotifyTrack -Id $_.id
        }

        $UniqueItems = $RecentlyPlayed.items.context.uri | select -Unique

        $UniqueItems | % {
            $_ -imatch 'spotify:?(user:(\d+):)?(album|track|playlist)?:(.+)$' | Out-Null
            $primaryMatch = $matches

            switch -Regex ($_) {
                'spotify:track:' {
                    Get-SpotifyTrack -Id $primaryMatch[4]
                }

                'spotify:album:' {
                    Get-SpotifyAlbum -Id $primaryMatch[4]
                }

                'spotify:user:.+:playlist' {
                    Get-SpotifyPlaylist -Id $primaryMatch[4] -UserId $primaryMatch[2]
                }
            }
        }
    }
}

function Get-SpotifyUsersTopArtist {
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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }

    process {
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
        
        (Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get).items | Get-SpotifyArtist
    }
}

function Get-SpotifyUsersTopTrack {
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

    begin {
        if (!$Session) {
            throw $Strings["SessionNotFound"]
        }

        Assert-AuthToken -Session $Session
    }
    
    process {
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

        (Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Get).items | Get-SpotifyTrack
    }
}