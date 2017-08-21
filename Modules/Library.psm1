$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-LocalizedData -BindingVariable Strings -BaseDirectory $currentPath\..\Localized -FileName Strings.psd1 -UICulture en-US

function Get-SpotifyLibrary {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [ValidateSet("Tracks", "Albums")]
        [string]
        $Type,

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
        $Url = "$($Session.RootUrl)/me/$Type"

        $Query = @()

        if ($PSBoundParameters.ContainsKey("CountryCode")) {
            $Query += "market=$CountryCode"
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
        
        $Items = (Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url.ToLower() `
                -Method Get).items

        switch ($Type) {
            'Albums' {
                $Items | % { 
                    New-Object PSSpotify.LibraryAlbumObject -Property @{
                        Album = $_.album | Get-SpotifyAlbum
                        Added = $_.added_at
                    }
                }
            }
            'Tracks' {
                $Items | % { 
                    New-Object PSSpotify.LibraryTrackObject -Property @{
                        Track = $_.track | Get-SpotifyTrack
                        Added = $_.added_at
                    }
                }
            }
        }
    }
}

function Add-SpotifyTracktoLibrary {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
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
        $Url = "$($Session.RootUrl)/me/tracks"

        $Body = @{ids = $Tracks}

        $Response = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method put `
            -Body (ConvertTo-Json $Body)
    }
}

function Add-SpotifyAlbumtoLibrary {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Albums,

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
        $Url = "$($Session.RootUrl)/me/albums"

        $Body = @{ids = $Albums}

        $Response = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method put `
            -Body (ConvertTo-Json $Body)
    }
}

function Remove-SpotifyTrackfromLibrary {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
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

        $Url = "$($Session.RootUrl)/me/tracks"

        $Body = @{ids = $Tracks}

        $Response = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Delete `
            -Body (ConvertTo-Json $Body)
    }
}

function Remove-SpotifyAlbumfromLibrary {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $Albums,

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

        $Url = "$($Session.RootUrl)/me/albums"

        $Body = @{ids = $Tracks}

        $Response = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Delete `
            -Body (ConvertTo-Json $Body)
    }
}

function Assert-SpotifyTrackinLibrary {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
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
        $Url = "$($Session.RootUrl)/me/tracks/contains"

        $Query = @(ids = $Tracks)

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get
    }
}

function Assert-SpotifyAlbuminLibrary {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
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
        $Url = "$($Session.RootUrl)/me/albums/contains"

        $Query = @(ids = $Tracks)

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get
    }
}