Then 'a Spotify UserProfile object should be returned' {
    $Profile | Should -BeOfType PSSpotify.UserProfile
}

And 'the Spotify UserProfile should have id (?<user>.+)' {
    param($user)

    if ($user -eq "current") {
        $user = $global:SpotifySession.CurrentUser.Id
    }

    $Profile.id | should -Be $user
}

And 'get (?<user>.+) userprofile (?<online>online|mocked)' {
    param($user, $online)

    $param = @{}
    if ($user -ne "current") {
        $param.add("id", $user)
    }
    else {
        $user = $global:SpotifySession.CurrentUser.Id
    }

    if ($online -ne "online") {
        mock Invoke-RestMethod -ParameterFilter {
            $Uri -eq "$global:RootUrl/me" -or 
            $Uri -like "$global:RootUrl/users/*"
        } -MockWith ([scriptblock]::create("[PSSpotify.UserProfile]@{id = '$user'}"))
    }

    $Profile = Get-SpotifyProfile @param
}

And 'mock users top (?<number>.+) played artists' {
    param($number)

    $mockscript = @()

    for ($i = 0; $i -lt $number; $i++) {
        $id = get-random -Maximum 999
        $mockscript += "([pscustomobject]@{Items = [pscustomobject]@{Id = '$id'}})"
    }

    mock Invoke-RestMethod ([scriptblock]::create("@(" + ($mockscript -join ",") + ")"))
    
    mock Get-SpotifyArtist {
        param([parameter(ValueFromPipelineByPropertyName)]$id)
        new-object PSSpotify.Artist -Property @{
            id = $id
        }
    }
}

Then 'users top (?<number>.+) played artists should be returned' {
    param($number)
    
    $Artists = Get-SpotifyUsersTopArtist -limit $number
    $Artists[0] | should -BeOfType PSSpotify.Artist
    $Artists.count | should -Be $number
}

And 'mock users top (?<number>.+) played tracks' {
    param($number)
    
    $mockscript = @()

    for ($i = 0; $i -lt $number; $i++) {
        $id = get-random -Maximum 999
        $mockscript += "[pscustomobject]@{Items = [pscustomobject]@{Id = '$id'}}"
    }
    mock Invoke-RestMethod ([scriptblock]::create($mockscript -join ';'))
    
    mock Get-SpotifyTrack {
        param([parameter(ValueFromPipelineByPropertyName)]$id)
        new-object PSSpotify.Track -Property @{
            id = $id
        }
    }
}

Then 'users top (?<number>.+) played tracks should be returned' {
    param($number)
    
    $Tracks = Get-SpotifyUsersTopTrack -limit $number
    $Tracks[0] | should -BeOfType PSSpotify.Track
    $Tracks.count | should -Be $number
}

Then 'return users top (?<return>.+) played tracks but skip the first (?<skip>.+)' {
    param($Return, $Skip)

    $Tracks = Get-SpotifyUsersTopTrack -limit $return -offset $Skip
    $Tracks[0] | should -BeOfType PSSpotify.Track
    $Tracks.count | should -Be $return
    Compare-Object ($MockedTracks | select -First $Return -Skip $Skip) $Tracks | should -BeNullOrEmpty
}

Then 'return users top (?<return>.+) played artists but skip the first (?<skip>.+)' {
    param($Return, $Skip)

    $Artists = Get-SpotifyUsersTopArtist -limit $return -offset $Skip
    $Artists[0] | should -BeOfType PSSpotify.Artist
    $Artists.count | should -Be $return
    Compare-Object ($MockedArtists | select -First $Return -Skip $Skip) $Artists | should -BeNullOrEmpty
}

And 'mock users top (?<number>.+) played artists with limit of (?<return>.+) and skip of (?<skip>.+)' {
    param($number, $return, $skip)

    $MockedArtists = @()
    $mockscript = @()

    for ($i = 0; $i -lt $number; $i++) {
        $id = get-random -Maximum 999
        $mockscript += "([pscustomobject]@{Items = [pscustomobject]@{Id = '$id'}})"
        $MockedArtists += ([pscustomobject]@{Items = [pscustomobject]@{Id = $id}})
    }
    mock Invoke-RestMethod -ParameterFilter {
        $uri -like "*limit=$return*" -and
        $uri -like "*offset=$skip*"
    } -MockWith ([scriptblock]::create("@(" +($mockscript -join ',') + ") | select -first $return -skip $skip"))
}

And 'mock users top (?<number>.+) played tracks with limit of (?<return>.+) and skip of (?<skip>.+)' {
    param($number, $return, $skip)
    
    $MockedTracks = @()
    $mockscript = @()

    for ($i = 0; $i -lt $number; $i++) {
        $id = get-random -Maximum 999
        $mockscript += "([pscustomobject]@{Items = [pscustomobject]@{Id = '$id'}})"
        $MockedTracks += ([pscustomobject]@{Items = [pscustomobject]@{Id = $id}})
    }
    mock Invoke-RestMethod -ParameterFilter {
        $uri -like "*limit=$return*" -and
        $uri -like "*offset=$skip*"
    } -MockWith ([scriptblock]::create("@(" +($mockscript -join ',') + ") | select -first $return -skip $skip"))
}
