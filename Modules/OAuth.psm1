Add-Type -AssemblyName System.Web
function Get-AuthorizationCode {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]
        $AuthorizationEndpoint,

        [parameter(Mandatory)]
        [pscredential]
        $ClientIdSecret,

        [parameter(Mandatory)]
        [string[]]
        $Permissions = "-",

        [parameter(Mandatory)]
        [string]
        $RedirectUri
    )

    begin {
        $redirectUriEncoded = [System.Web.HttpUtility]::UrlEncode($redirectUri)
    }

    process {
        [void]$(
            $url = [string]::Format("{0}?response_type=code&redirect_uri={1}&client_id={2}&scope={3}", `
                    $AuthorizationEndpoint, `
                    $redirectUriEncoded, `
                    $ClientIdSecret.UserName, `
                ($Permissions -join '%20'))

            $AuthCode = New-OAuthConfirmationWindow -Url $url

            $PSCmdlet.WriteObject($AuthCode)
        )
    }
}
function Get-AccessToken {
    [cmdletbinding(DefaultParameterSetName = "AuthCode")]
    param(
        [parameter(Mandatory)]
        [string]
        $TokenEndpoint,

        [parameter(Mandatory)]
        [pscredential]
        $ClientIdSecret,

        [parameter(Mandatory, ParameterSetName = "RefreshToken")]
        [string]
        $RefreshToken,

        [parameter(Mandatory, ParameterSetName = "AuthCode")]
        [string]
        $AuthorizationCode,

        [parameter(Mandatory, ParameterSetName = "AuthCode")]
        [string]
        $RedirectUri
    )
    process {
        [void]$(
            $Body = ""

            if ($PSBoundParameters.ContainsKey("RefreshToken")) {
                $GrantType = "refresh_token"

                $Body = "grant_type=$GrantType&refresh_token=$RefreshToken"
            }
            else {
                $GrantType = "authorization_code"
                $redirectUriEncoded = [System.Web.HttpUtility]::UrlEncode($redirectUri)

                $Body = "grant_type=$GrantType&redirect_uri=$redirectUriEncoded&code=$AuthorizationCode"
            }
            $body += [string]::format("&client_id={0}&client_secret={1}", `
                    $ClientIdSecret.UserName, `
                    [System.Web.HttpUtility]::UrlEncode($ClientIdSecret.GetNetworkCredential().Password)
            )

            $Authorization = Invoke-RestMethod -Uri $TokenEndpoint `
                -Method Post -ContentType "application/x-www-form-urlencoded" `
                -Body $body `
                -ErrorAction STOP

            $PSCmdlet.WriteObject($Authorization)
        )
    }
}
function New-OAuthConfirmationWindow {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]
        $Url
    )
    [void]$(
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