Given 'the OAuth module is imported' {
    import-module $PSScriptRoot\..\PSSpotify.psd1 -Force -DisableNameChecking -Global
}

Given 'the OAuth API is available' {
    param($InputData)
    $global:Data = ConvertFrom-StringData $InputData
    $global:Cred = (import-clixml $Data["CredPath"])
    $global:TokenEndpoint = $Data["TokenEndpoint"]
    $global:AuthorizationEndpoint = $Data["AuthorizationEndpoint"]
    $global:RedirectUri = $Data["RedirectUri"]
    $global:RefreshToken = $Data["RefreshToken"]
    $global:Perms = $Data["Perms"]
}

Given 'the OAuth API is mocked' {
    $global:Cred = New-Object PSCredential -ArgumentList 'user', (ConvertTo-SecureString 'password' -AsPlainText -Force)
    $global:TokenEndpoint = "https://localhost/MockApi/token"
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

    mock -CommandName New-OAuthConfirmationWindow -MockWith {
        $global:AuthCode
    }
}

And 'an OAuth RefreshToken is specified' {
    $AccessTokenParams = @{
        TokenEndpoint  = $global:TokenEndpoint
        ClientidSecret = $global:Cred
        RefreshToken   = $global:RefreshToken
    }
}

But "an OAuth RefreshToken isn't specified" {
    $AuthCodeParams = @{
        AuthorizationEndpoint = $global:AuthorizationEndpoint
        RedirectUri           = $global:RedirectUri
        ClientidSecret        = $global:Cred
        Permissions           = $global:Perms
    }
    $AccessTokenParams = @{
        TokenEndpoint     = $global:TokenEndpoint
        ClientidSecret    = $global:Cred
        AuthorizationCode = $global:AuthCode
        RedirectUri       = $global:RedirectUri
    }
}

When 'I request an access token from the API' {
    $session = Get-AccessToken @AccessTokenParams
}

When 'I request an auth code from the API' {
    $AccessTokenParams["AuthorizationCode"] = Get-AuthorizationCode @AuthCodeParams
}

Then 'an OAuth Session object should be returned' {
    $Session | Should -Not -BeNullOrEmpty
}

And 'an OAuth Session object should be valid' {
    $Session.access_token | should -BeOfType string
    $Session.expires_in | should -BeOfType int
    $Session.token_Type | should -Be "Bearer"
    $Session.Scope | should -BeOfType string
}

And 'an OAuth Session object permissions should match' {
    param($Perm)
    $Session.Scope | should -BeLike "*$Perm*"
}