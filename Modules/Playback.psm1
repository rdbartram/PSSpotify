$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-LocalizedData -BindingVariable Strings -BaseDirectory $currentPath\..\Localized -FileName Strings.psd1 -UICulture en-US

function Get-SpotifyDevice {
    [cmdletbinding(DefaultParameterSetName = "Name")]
    param(
        [parameter(ParameterSetName = "id")]
        [string]
        $id,

        [parameter(ParameterSetName = "Name")]
        [string]
        $Name,

        [parameter()]
        [ValidateSet('Computer', 'Smartphone', 'Speaker')]
        [string]
        $Type,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Filter = @()

        if ($PSBoundParameters.ContainsKey("Type")) {
            $Filter += '$_.Type -eq $Type'
        }

        if ($PSBoundParameters.ContainsKey("Id")) {
            $Filter += '$_.Id -eq $Id'
        }

        if ($PSBoundParameters.ContainsKey("Name")) {
            $Filter += '$_.Name -eq $Name'
        }

        if ($Filter.Count -eq 0) {
            $Filter += '$true'
        }

        $Url = "$($Session.RootUrl)/me/player/devices"

        $Response = Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Get

        $Response.Devices | ? ([scriptblock]::Create($Filter -join ' -and '))
    }
}

function Get-SpotifyPlayer {
    [cmdletbinding()]
    param(
        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri "$($Session.RootUrl)/me/player" `
            -Method Get
    }
}

function Set-SpotifyPlayer {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName)]
        [Alias("Id")]
        [string]
        $DeviceId,

        [parameter()]
        [Switch]
        $Play,

        [parameter()]
        [ValidateSet('track', 'context', 'off')]
        [string]
        $Repeat,

        [parameter()]
        [ValidateRange(0, 100)]
        [int32]
        $Volume,

        [parameter()]
        [int32]
        $TrackPosition,

        [parameter()]
        [boolean]
        $Shuffle,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        if ($PSBoundParameters.ContainsKey("DeviceId")) {
            $Url = "$($Session.RootUrl)/me/player"

            $Body = @{
                device_ids = @($DeviceId)
            }

            if ($PSBoundParameters.ContainsKey("Play")) {
                $Body.Add("play", [boolean]$Play)
            }

            $Response = Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Put `
                -Body (ConvertTo-Json $Body)
        }

        if ($PSBoundParameters.ContainsKey("Repeat")) {
            $Url = "$($Session.RootUrl)/me/player/repeat?state=$State)"

            if ($PSBoundParameters.ContainsKey("DeviceId")) {
                $Url += "&device_id=$DeviceId"
            }

            Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Put
        }

        if ($PSBoundParameters.ContainsKey("Volume")) {
            $Url = "$($Session.RootUrl)/me/player/volume?volume_percent=$Volume"

            if ($PSBoundParameters.ContainsKey("DeviceId")) {
                $Url += "&device_id=$DeviceId"
            }

            Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Put
        }

        if ($PSBoundParameters.ContainsKey("TrackPosition")) {
            $Url = "$($Session.RootUrl)/me/player/seek?position_ms=$([timespan]::FromSeconds($Seconds).TotalMilliseconds)"

            if ($PSBoundParameters.ContainsKey("DeviceId")) {
                $Url += "&device_id=$DeviceId"
            }

            Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Put
        }

        if ($PSBoundParameters.ContainsKey("Shuffle")) {
            $Url = "$($Session.RootUrl)/me/player/shuffle?state=$Shuffle"

            if ($PSBoundParameters.ContainsKey("DeviceId")) {
                $Url += "&device_id=$DeviceId"
            }

            Invoke-RestMethod -Headers $Session.Headers `
                -Uri $Url `
                -Method Put
        }
    }
}

function Get-SpotifyCurrentTrack {
    [cmdletbinding()]
    param(
        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri "$($Session.RootUrl)/me/player/currently-playing" `
            -Method Get
    }
}

function Resume-Spotify {
    [cmdletbinding(DefaultParameterSetName = "OffsetUri")]
    param(
        [parameter()]
        [string]
        $DeviceId,

        [parameter(Mandatory, ParameterSetName = "OffsetId")]
        [parameter(Mandatory, ParameterSetName = "OffsetUri")]
        [string[]]
        $Context,

        [parameter(ParameterSetName = "OffsetId")]
        [uint32]
        $OffsetId,

        [parameter(ParameterSetName = "OffsetUri")]
        [uint32]
        $OffsetUri,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/me/player/play"

        $Query = @()
        $Body = @{}

        if ($PSBoundParameters.ContainsKey("DeviceId")) {
            $Query += "device_id=$DeviceId"
        }

        if ($PSBoundParameters.ContainsKey("Context")) {
            $Body.Add("uris", $Context)
        }

        if ($PSBoundParameters.ContainsKey("OffsetId")) {
            $Body.Add("offset", @{position = $OffsetId})
        }

        if ($PSBoundParameters.ContainsKey("OffsetUri")) {
            $Body.Add("offset", @{uri = $OffsetUri})
        }

        if ($Query.Count -gt 0) {
            $Url += "?$($Query -join '&')"
        }

        Write-Verbose (ConvertTo-Json $Body)

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Put `
            -Body (ConvertTo-Json $Body)
    }
}

function Pause-Spotify {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $DeviceId,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/me/player/pause"

        if ($PSBoundParameters.ContainsKey("DeviceId")) {
            $Url += "?device_id=$DeviceId"
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Put
    }
}

function Skip-SpotifyTrack {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $DeviceId,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/me/player/next"

        if ($PSBoundParameters.ContainsKey("DeviceId")) {
            $Url += "?device_id=$DeviceId"
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Post
    }
}

function Previous-SpotifyTrack {
    [cmdletbinding()]
    param(
        [parameter()]
        [string]
        $DeviceId,

        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        if (!$Session) {
            throw "Spotify Session not established. Please run Connect-Spotify."
        }

        $Url = "$($Session.RootUrl)/me/player/previous"

        if ($PSBoundParameters.ContainsKey("DeviceId")) {
            $Url += "?device_id=$DeviceId"
        }

        Invoke-RestMethod -Headers $Session.Headers `
            -Uri $Url `
            -Method Post
    }
}
