And 'create playlist (?<name>.+) which ispublic:(?<IsPublic>.+) and Collaborative:(?<Collaborative>.+)' {
    param($name, $ispublic, $Collaborative)
    $Params = @{Name = $name}

    if ([boolean]::Parse("$ispublic")) {
        $Params.add("IsPublic", $true)
    }

    if ([boolean]::Parse("$Collaborative")) {
        $Params.add("IsCollaborative", $true)
    }

    $global:mockedapiplaylist = [PSCustomObject]@{
        id            = "123"
        Name          = $Name
        description   = ""
        collaborative = [boolean]::Parse($Collaborative)
        public        = [boolean]::Parse($IsPublic)
        Owner         = @{
            Id = "456"
        }
    }

    mock Invoke-RestMethod -ParameterFilter {
        $uri -match "users/.+/playlists" -and $method -eq "post"
    } -MockWith { $global:mockedapiplaylist }

    mock Invoke-RestMethod -ParameterFilter {
        $uri -match "users/456/playlists/123" -and $method -eq "get"
    } -MockWith { $global:mockedapiplaylist }
        
    mock Get-SpotifyProfile -ParameterFilter {$id -eq "456"} -MockWith { param($id)
        [PSSpotify.UserProfile]@{
            Id = $id
        }
    }

    $Playlist = New-SpotifyPlaylist @params
}

Then 'playlist (?<name>.+) should exist and be ispublic:(?<IsPublic>.+) and Collaborative:(?<Collaborative>.+)' {
    param($name, $ispublic, $Collaborative)

    $Playlist = Get-SpotifyPlaylist -Id $Playlist.id -UserId $Playlist.Owner.Id

    $Playlist | should -BeOfType PSSpotify.Playlist
    $Playlist.Name | Should -Be $name
    $Playlist.Public.tostring() | Should -Be $ispublic
    $Playlist.Collaborative.tostring() | Should -Be $Collaborative
}

And 'when I set playlist (?<name>.+) description to (?<description>.+)' {
    param ($name, $description)

    mock Invoke-RestMethod -ParameterFilter {
        $uri -match "users/.+/playlists/$($global:mockedapiplaylist.id)" -and $method -eq "Put"
    } -MockWith { param ($Body)
        $data = $body | ConvertFrom-Json
        $global:mockedapiplaylist.description = $data.description
    }

    $Playlist = $Playlist | Set-SpotifyPlaylist -Description $description -PassThru
}

Then 'playlist (?<name>.+) should have (?<description>.+) as description' {
    param($name, $description)

    $Playlist = Get-SpotifyPlaylist -Id $Playlist.id -UserId $Playlist.Owner.Id

    $Playlist | should -BeOfType PSSpotify.Playlist
    $Playlist.description | Should -Be $description
}

