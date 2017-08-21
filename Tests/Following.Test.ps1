[CmdletBinding()]
param()

$script:moduleRoot = Split-Path $PSScriptRoot -Parent
Import-Module $script:moduleRoot -Force

Connect-Spotify -ClientIdSecret (import-clixml .\Credential.xml) -KeepCredential | out-null

Describe 'Spotify Following Feature' {
    $Artist = Find-SpotifyArtist -Filter "justin Bieber" | select -first 1
    $Playlist = Find-SpotifyPlaylist -Filter "justin Bieber" | select -first 1
    $User = Get-SpotifyProfile -Id "1135956113" | select -first 1

    Context -Name 'Follow Artist' {
        {Follow-SpotifyItem -Type artist -Id $Artist.Id} | should not throw
        Assert-SpotifyFollowing -Type Artist -Id $Artist.id | should be $true
    }

    Context -Name 'Unfollow Artist' {
        {Unfollow-SpotifyItem -Type artist -Id $Artist.Id} | should not throw
        Assert-SpotifyFollowing -Type Artist -Id $Artist.id | should be $false
    }

    Context -Name 'Follow User' {
        {Follow-SpotifyItem -Type user -Id $user.Id} | should not throw
        Assert-SpotifyFollowing -Type User -Id $user.id | should be $true
    }

    Context -Name 'Unfollow User' {
        {Unfollow-SpotifyItem -Type user -Id $user.Id} | should not throw
        Assert-SpotifyFollowing -Type User -Id $user.id | should be $false
    }

    Context -Name 'Follow Playlist' {
        {Follow-SpotifyItem -Type playlist -Id $Playlist.Id -OwnerId $Playlist.owner.id} | should not throw
        Assert-SpotifyFollowing -Type Playlist -Id $Playlist.id -OwnerId $Playlist.owner.id | should be $true
    }

    Context -Name 'Unfollow Artist' {
        {Unfollow-SpotifyItem -Type playlist -Id $Playlist.Id -OwnerId $Playlist.owner.id} | should not throw
        Assert-SpotifyFollowing -Type Playlist -Id $Playlist.id -OwnerId $Playlist.owner.id | should be $false
    }
}
