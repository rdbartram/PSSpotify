$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-LocalizedData -BindingVariable Strings -BaseDirectory $currentPath\..\Localized -FileName Strings.psd1 -UICulture en-US

$ValidPermissions = @(
    "user-read-recently-played",
    "user-read-private",
    "user-read-email",
    "user-read-playback-state",
    "user-modify-playback-state",
    "user-top-read",
    'playlist-modify-public',
    'playlist-modify-private',
    'playlist-read-private',
    'playlist-read-collaborative',
    'user-read-birthdate'
)

function Connect-Spotify {
    [OutputType("PSSpotify.SessionInfo")]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [PSCredential]
        $ClientIdSecret,

        [parameter()]
        [string]
        $RedirectUri = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData["RedirectUri"],

        [parameter()]
        [switch]
        $KeepCredential
    )

    DynamicParam {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $ParameterName = 'Permissions'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false
        $AttributeCollection.Add($ParameterAttribute)
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidPermissions)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributeCollection)
        $PSBoundParameters["Permissions"] = $ValidPermissions
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }

    process {
        $AuthCode = Get-AuthorizationCode -ClientIdSecret $ClientIdSecret -Permissions $PSBoundParameters["Permissions"] -RedirectUri $redirectUri

        $AccessToken = Get-AccessToken -ClientIdSecret $ClientIdSecret -AuthorizationCode $AuthCode -RedirectUri $RedirectUri

        $Session = [PSCustomObject]@{
            Headers      = @{Authorization = "$($AccessToken.token_type) $($AccessToken.access_token)"; "content-type" = "application/json"}
            RootUrl      = "https://api.spotify.com/v1"
            Expires      = $AccessToken.expires_in
            RefreshToken = $AccessToken.refresh_token
        }

        $Profile = Get-SpotifyProfile -Session $Session

        $Session | Add-Member -MemberType NoteProperty -Name CurrentUser -Value $Profile
        
        $Session.PSObject.TypeNames.Insert(0, "PSSpotify.SessionInfo")
        $Global:SpotifySession = $Session

        if ($KeepCredential) {
            $Global:SpotifyCredential = $ClientIdSecret
        }

        $Session
    }
}

function Get-AuthorizationCode {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [pscredential]
        $ClientIdSecret,

        [parameter()]
        [string]
        $RedirectUri = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData["RedirectUri"]
    )

    DynamicParam {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $ParameterName = 'Permissions'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false
        $AttributeCollection.Add($ParameterAttribute)
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidPermissions)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributeCollection)
        $PSBoundParameters["Permissions"] = "-"
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }

    begin {
        $redirectUriEncoded = [System.Web.HttpUtility]::UrlEncode($redirectUri)
    }

    process {
        [void]$(
            $url = [string]::Format("https://accounts.spotify.com/authorize?response_type=code&redirect_uri={0}&client_id={1}&scope={2}", `
                    $redirectUriEncoded, `
                    $ClientIdSecret.UserName, `
                ($PSBoundParameters["Permissions"] -join '%20'))

            Add-Type -AssemblyName System.Windows.Forms
            $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width = 440; Height = 640}
            $web = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width = 420; Height = 600; Url = $Url }

            $DocComp = {
                $ReturnUrl = $web.Url.AbsoluteUri
                if ($ReturnUrl -match "error=[^&]*|code=[^&]*") {
                    $form.Close()
                }
            }

            $web.ScriptErrorsSuppressed = $true
            $web.Add_DocumentCompleted($DocComp)
            $form.Controls.Add($web)
            $form.Add_Shown( {$form.Activate()})
            $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
            $form.ShowDialog()


            $queryOutput = [System.Web.HttpUtility]::ParseQueryString($web.Url.Query)

            $output = @{}

            foreach ($key in $queryOutput.Keys) {
                $output["$key"] = $queryOutput[$key]
            }

            $PSCmdlet.WriteObject($output["Code"])
        )
    }
}

function Get-AccessToken {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [pscredential]
        $ClientIdSecret,

        [parameter(Mandatory)]
        [string]
        $AuthorizationCode,

        [parameter()]
        [string]
        $RedirectUri = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData["RedirectUri"]
    )

    begin {
        $redirectUriEncoded = [System.Web.HttpUtility]::UrlEncode($redirectUri)
    }

    process {
        [void]$(
            $body = [string]::format("grant_type=authorization_code&redirect_uri={0}&client_id={1}&client_secret={2}&code={3}", `
                    $redirectUriEncoded, `
                    $ClientIdSecret.UserName, `
                    [System.Web.HttpUtility]::UrlEncode($ClientIdSecret.GetNetworkCredential().Password), `
                    $AuthorizationCode
            )

            $Authorization = Invoke-RestMethod https://accounts.spotify.com/api/token `
                -Method Post -ContentType "application/x-www-form-urlencoded" `
                -Body $body `
                -ErrorAction STOP

            $PSCmdlet.WriteObject($Authorization)
        )
    }
}

function Assert-AuthToken {
    [cmdletbinding()]
    param(
        [parameter()]
        $Session = $Global:SpotifySession
    )

    process {
        try {
            Get-SpotifyProfile -Session $Session
        } catch {
            $Error = ConvertFrom-Json $_.ErrorDetails.Message
            if ($Error.Error.Message -eq "The access token expired") {
                [void]$(
                    $ClientIdSecret = $Global:SpotifyCredential

                    if ($ClientIdSecret -eq $null) {
                        $ClientIdSecret = get-credential
                    }

                    $body = [string]::format("grant_type=refresh_token&client_id={1}&client_secret={2}&refresh_token={0}", `
                            $Global:SpotifySession.RefreshToken, `
                            $ClientIdSecret.UserName, `
                            [System.Web.HttpUtility]::UrlEncode($ClientIdSecret.GetNetworkCredential().Password)
                    )

                    $Authorization = Invoke-RestMethod https://accounts.spotify.com/api/token `
                        -Method Post -ContentType "application/x-www-form-urlencoded" `
                        -Body $body `
                        -ErrorAction STOP

                    $Session = [PSCustomObject]@{
                        Headers      = @{Authorization = "$($Authorization.token_type) $($Authorization.access_token)"}
                        RootUrl      = "https://api.spotify.com/v1"
                        Expires      = $Authorization.expires_in
                        RefreshToken = $Global:SpotifySession.RefreshToken
                    }
                    $Session.PSObject.TypeNames.Insert(0, "PSSpotify.SessionInfo")
                    $Global:SpotifySession = $Session
                )
            }
        }
    }
}