[CmdletBinding()]
param()

$script:moduleRoot = Split-Path $PSScriptRoot -Parent
Import-Module $script:moduleRoot -Force

Connect-Spotify -ClientIdSecret (import-clixml .\Credential.xml) -KeepCredential | out-null

Describe 'Spotify Following Feature' {
    $Playlist = Find-SpotifyPlaylist -Filter "justin Bieber" | select -first 1
    $Tracks = Find-SpotifyTrack -Filter "Justin Bieber" -Limit 5

    Context -Name 'Get specific Playlist' {
        {
            $P = Get-SpotifyPlaylist -Id $Playlist.id -UserId $Playlist.owner.id
            $P.owner.id -eq $Playlist.owner.id -and `
                $P.id -eq $Playlist.id -and `
                $P.Type -eq "Playlist" `
        } | should be $true
    }

    Context -Name 'Get My Playlists' {
        {
            $P = Get-SpotifyPlaylist -My
            $P[0].type -eq "Playlist"
        } | should be $true
    }

    Context -Name 'New Playlist' {
        {New-SpotifyPlaylist -Name "Pester" -Description "MyPlaylist"} | should not throw
        {
            $P = Get-SpotifyPlaylist -My | ? { $_.Name -eq "Pester" }

            $P.Name -eq "Pester" -and `
                $P.Description -eq "MyPlaylist"
        } | should be $true
    }

    Context -Name 'Add Tracks to Playlist' {
        {$P = Get-SpotifyPlaylist -My | ? { $_.Name -eq "Pester" }; $P | Add-SpotifyTracktoPlaylist -Tracks $Tracks.uri} | should not throw
        {
            $P = Get-SpotifyPlaylist -My | ? { $_.Name -eq "Pester" }

            (Compare-Object (Get-SpotifyTrack -PlaylistId $P.id -UserId $P.owner.id) $Tracks) -eq $null
        } | should be $true
    }

    Context -Name 'Set Track Position' {
        { $P = Get-SpotifyPlaylist -My | ? { $_.Name -eq "Pester" }; Set-SpotifyPlaylistTrackPosition -Id $P.id -UserId $P.owner.id -StartPosition 3 -NumberofTracks 2 -EndPosition 1 } | should not throw
        {
            $P = Get-SpotifyPlaylist -My | ? { $_.Name -eq "Pester" }

            $PTracks = Get-SpotifyTrack -PlaylistId $P.id -UserId $P.owner.id

            $PTracks[0] -eq $Tracks[3] -and $PTracks[1] -eq $Tracks[4]
        } | should be $true
    }

    Context -Name 'Randomise track order' {
        { $P = Get-SpotifyPlaylist -My | ? { $_.Name -eq "Pester" }; $oTracks = Get-SpotifyTrack -PlaylistId $P.id -UserId $P.owner.id; Randomize-SpotifyPlaylistTrackOrder -Id $P.id -UserId $P.owner.id } | should not throw
        {
            $RTracks = Get-SpotifyTrack -PlaylistId $P.id -UserId $P.owner.id

            $otracks | % {
                $_ -ne $RTracks[$otracks.indexof($_)]
            }
        } | should be $true
    }

    Context -Name 'Remove track from Playlist' {
        { $P = Get-SpotifyPlaylist -My | ? { $_.Name -eq "Pester" }; Remove-SpotifyTrackfromPlaylist -Id $P.id -UserId $P.owner.id -Tracks $Tracks[4].uri } | should not throw
        {
            $P = Get-SpotifyPlaylist -My | ? { $_.Name -eq "Pester" };
            $PTracks = Get-SpotifyTrack -PlaylistId $P.id -UserId $P.owner.id;
            $PTracks.contains($Tracks[4]) -eq $false
        } | should be $true
    }
}