Given 'the PSSpotify module is imported' {
    import-module $PSScriptRoot\..\PSSpotify.psd1 -Force -DisableNameChecking -Global
}

Given 'the Spotify API is (available|online)' {
    param($type, $InputData)
    $global:Data = ConvertFrom-StringData $InputData
    $global:Cred = (import-clixml $Data["CredPath"])
    $global:TokenEndpoint = $Data["TokenEndpoint"]
    $global:RootUrl = $Data["RootUrl"]
    $global:AuthorizationEndpoint = $Data["AuthorizationEndpoint"]
    $global:RedirectUri = $Data["RedirectUri"]
    $global:RefreshToken = $Data["RefreshToken"]
    $global:Perms = $Data["Perms"]
}

Given 'the Spotify API is mocked' {
    $global:Cred = New-Object PSCredential -ArgumentList 'user', (ConvertTo-SecureString 'password' -AsPlainText -Force)
    $global:TokenEndpoint = "https://localhost/MockApi/token"
    $global:RootUrl = "https://localhost/v1"
    $global:AuthorizationEndpoint = "https://localhost/authorize"
    $global:RedirectUri = "http://localhost:8001"
    $global:RefreshToken = "123"
    $global:AccessToken = "456"
    $global:AuthCode = "789"
    $global:Perms = "Scope1", "Scope2"

    mock -CommandName Invoke-RestMethod -ParameterFilter {$Uri -eq $global:TokenEndpoint} -MockWith {
        [pscustomobject]@{
            access_token  = $global:AccessToken
            refresh_token = $global:RefreshToken
            token_type    = "Bearer"
            expires_in    = 3600
            scope         = ($global:Perms -join ' ')
        }
    }

    mock Invoke-RestMethod -ParameterFilter {$Uri -eq "$global:RootUrl/me"} -MockWith { @{id = "test"} }

    mock -CommandName New-OAuthConfirmationWindow -MockWith {
        $global:AuthCode
    }
}

And 'a Spotify RefreshToken is specified' {
    $global:ConnectParams = @{
        ClientIdSecret        = $global:Cred
        RefreshToken          = $global:RefreshToken
        TokenEndpoint         = $global:TokenEndpoint
        RootAPIEndpoint       = $global:RootUrl
        RedirectUri           = $global:RedirectUri
        AuthorizationEndpoint = $global:AuthorizationEndpoint
    }
}

And 'KeepCredential is passed' {
    $global:ConnectParams.Add("KeepCredential", $true)
}

But "a Spotify RefreshToken isn't specified" {
    $global:ConnectParams = @{
        ClientIdSecret        = $global:Cred
        AuthorizationEndpoint = $global:AuthorizationEndpoint
        TokenEndpoint         = $global:TokenEndpoint
        RootAPIEndpoint       = $global:RootUrl
        RedirectUri           = $global:RedirectUri
    }
}

Then '(?<cmdletname>.+) should be called (?<times>\d+) times?' {
    param($cmdletname, $times)
    Assert-MockCalled $cmdletname -Times $times -Scope it
}

And '(?<cmdletname>.+) should be called (?<times>\d+) times?' {
    param($cmdletname, $times)
    Assert-MockCalled $cmdletname -Times $times -Scope it
}

When 'I connect to Spotify' {
    $session = Connect-Spotify @ConnectParams
}

Then 'a Spotify Session object should be returned' {
    $Session | Should -BeOfType PSSpotify.SessionInfo
}

And 'the Spotify Session should be valid' {
    $Session.headers.Authorization | should -BeLike "Bearer *"
    $Session.headers.contenttype | should -Be "application/json"
    $Session.expires -gt 0 | should -Be $true
    $Session.RefreshToken.Length -gt 0 | should -Be $true
    $Session.APIEndpoints.TokenEndpoint | should -Be $global:TokenEndpoint
    $Session.APIEndpoints.AuthorizationEndpoint | should -Be $global:AuthorizationEndpoint
    $Session.APIEndpoints.RedirectUri | should -Be $global:RedirectUri
    $Session.CurrentUser.Id | should -Not -BeNullOrEmpty
}

And 'the Spotify Session permissions should match' {
    param($Perm)
    $Session.Scope | should -BeLike "*$Perm*"
}

And 'a Spotify Credential object should be created' {
    $global:SpotifyCredential | should -Not -BeNullOrEmpty
}

When 'I assert the access token is valid' {
    $OldToken = $global:SpotifySession.Headers.Authorization
    mock Invoke-RestMethod -ParameterFilter {$Uri -eq "$global:RootUrl/me"} -MockWith { }
    $null = Assert-AuthToken -Session $global:SpotifySession
}

Then 'the access token should stay the same' {
    $OldToken -eq $global:SpotifySession.Headers.Authorization | should -Be $true
}

When 'I assert the access token is invalid' {
    $OldToken = $global:SpotifySession.Headers.Authorization
    mock Invoke-RestMethod -ParameterFilter {$Uri -eq "$global:RootUrl/me"} -MockWith { Write-Error -Exception "The access token expired" -Message '{Error:{Message: "The access token expired"}}' -ea stop }
    mock Connect-Spotify -MockWith {
        $Global:RefreshedSession = [PSSpotify.SessionInfo]@{
            Headers = @{Authorization = "Bearer 321"; "contenttype" = "application/json"}
        }
    }
    $null = Assert-AuthToken -Session $global:SpotifySession
}

Then 'the access token should be refreshed' {
    $OldToken -eq $Global:RefreshedSession.Headers.Authorization | should -Be $false
}
