# PSSpotify
Module for controlling Spotify playback function, aswell as create and updating playlists. All  functions currently supported by the API are in this module.

## Versions

### 0.0.0.9
* Initial Release with following
    * Functions:
        * Add-SpotifyAlbumtoLibrary
        * Add-SpotifyTracktoLibrary
        * Add-SpotifyTracktoPlaylist
        * Assert-SpotifyAlbuminLibrary
        * Assert-SpotifyFollowing
        * Assert-SpotifyTrackinLibrary
        * Connect-Spotify
        * Find-SpotifyAlbum
        * Find-SpotifyArtist
        * Find-SpotifyItem
        * Find-SpotifyPlaylist
        * Find-SpotifyTrack
        * Follow-SpotifyItem
        * Get-SpotifyAlbum
        * Get-SpotifyArtist
        * Get-SpotifyArtistTopTracks
        * Get-SpotifyCategory
        * Get-SpotifyCurrentTrack
        * Get-SpotifyDevice
        * Get-SpotifyFeaturedPlaylists
        * Get-SpotifyFollowedItem
        * Get-SpotifyLibrary
        * Get-SpotifyNewReleases
        * Get-SpotifyPlayer
        * Get-SpotifyPlaylist
        * Get-SpotifyProfile
        * Get-SpotifyRecentlyPlayed
        * Get-SpotifyRecommendation
        * Get-SpotifyRecommendationGenres
        * Get-SpotifyRelatedArtists
        * Get-SpotifyTrack
        * Get-SpotifyUsersTopArtist
        * Get-SpotifyUsersTopTrack
        * New-OAuthConfirmationWindow
        * New-SpotifyPlaylist
        * Pause-Spotify
        * Previous-SpotifyTrack
        * Randomize-SpotifyPlaylistTrackOrder
        * Remove-SpotifyAlbumfromLibrary
        * Remove-SpotifyTrackfromLibrary
        * Remove-SpotifyTrackfromPlaylist
        * Resume-Spotify
        * Set-SpotifyPlayer
        * Set-SpotifyPlaylist
        * Set-SpotifyPlaylistTrackPosition
        * Skip-SpotifyTrack
        * Unfollow-SpotifyItem

## Examples

### Connecting to Spotify and allowing automate token refresh

Storing the clientid and secret in an XML is only for convenience. If not given, PowerShell will simply prompt you for them. The keepCredential parameter simply means the ClientID and Secret will be kept in memory for as long as the PowerShell window is open.

```powershell
Connect-Spotify -ClientIdSecret (import-clixml .\Credential.xml) -KeepCredential
```

### Connecting to Spotify using refresh token and using custom RedirectURI

When connecting using only clientid and secret, oAuth will prompt the user to confirm they want to connect to Spotify. To supress this behaviour you'll need to pass a previously generated refresh token.

A part of the oAuth process is knowing which endpoints are authorized to make authentication requests. The redirectURI therefore must be configured in the Spotify Developer portal as seen in the setup section.

```powershell
Connect-Spotify -ClientIdSecret $Global:SpotifyCredential -RefreshToken $refreshToken -RedirectURI "https://myApi:8001/Auth"
```

### Switch playback to another device and set volume

To change the device to my phone and increase the volume is as simple as follows

```powershell
Get-SpotifyDevice -Name OnePlus3T | Set-SpotifyPlayer -Volume 40
```

### Find Album and play it

There are 4 seperate commands for finding songs, artists, albums and playlists. Once you have the items you want to play, simply pass them to the context of resume and away you go.

```powershell
$Album = Find-SpotifyAlbum -Filter "Mylo Xyloto"

Resume-SpotifyPlayback -context $Album.uri
```

## Setup

### Spotify Developer Portal

To get the module working you will need to configure the oAuth authentication on the Spotify Developer website. https://developer.spotify.com 

Once you've create the application you'll need to make note of the clientid, clientsecret and redirecturi.

These are necessary when connecting to the API.

![Alt text](/Media/SpotifyDev.JPG?raw=true "Spotify Console")