@auth
Feature: Ability to create create OAuth sessions and ability to automatically recreate OAuth sessions for spotify when they expire.

A Session needs to be created with Spotify WebAPI in order to allow control of playback etc.
The Session generally expires after 3600 seconds. In order to make the experience seamless for the user, session need to automatically request new token.

    Background: The PSSpotify Module is imported
        Given the PSSpotify module is imported

    @authtoken @integration
    Scenario: Connect to spotify using ClientSecret (Integ)
        Given the Spotify API is available
            """
            CredPath = $PSScriptRoot\\..\\Credential.xml
            RefreshToken = {{key}}
            AuthorizationEndpoint = https://accounts.spotify.com/authorize
            TokenEndpoint = https://accounts.spotify.com/api/token
            RootUrl = https://api.spotify.com/v1
            RedirectUri = https://localhost:8001
            Perms = user-read-private
            """
        But a Spotify RefreshToken isn't specified
        When I connect to Spotify
        Then a Spotify Session object should be returned
        And the Spotify Session should be valid


    @refreshtoken @integration
    Scenario: Connect to spotify using ClientSecret refresh token (Integ)
        Given the Spotify API is available
            """
            CredPath = $PSScriptRoot\\..\\Credential.xml
            RefreshToken = {{key}}
            AuthorizationEndpoint = https://accounts.spotify.com/authorize
            TokenEndpoint = https://accounts.spotify.com/api/token
            RootUrl = https://api.spotify.com/v1
            RedirectUri = https://localhost:8001
            """
        And a Spotify RefreshToken is specified
        When I connect to Spotify
        Then a Spotify Session object should be returned
        And the Spotify Session should be valid

    @refreshtoken @unit
    Scenario: Connect to spotify using ClientSecret refresh token (Unit)
        Given the Spotify API is mocked
        And a Spotify RefreshToken is specified
        When I connect to Spotify
        Then Invoke-RestMethod should be called 1 time
        And New-OAuthConfirmationWindow should be called 0 times
        And a Spotify Session object should be returned
        And the Spotify Session should be valid

    @authtoken @unit
    Scenario: Connect to spotify using ClientSecret (Unit)
        Given the Spotify API is mocked
        But a Spotify RefreshToken isn't specified
        When I connect to Spotify
        Then Invoke-RestMethod should be called 1 time
        And New-OAuthConfirmationWindow should be called 1 times
        And a Spotify Session object should be returned
        And the Spotify Session should be valid

    @authtoken @unit
    Scenario: Connect to spotify using ClientSecret and save credential (Unit)
        Given the Spotify API is mocked
        But a Spotify RefreshToken isn't specified
        And KeepCredential is passed
        When I connect to Spotify
        Then Invoke-RestMethod should be called 1 time
        And New-OAuthConfirmationWindow should be called 1 times
        And a Spotify Session object should be returned
        And the Spotify Session should be valid
        And a Spotify Credential object should be created

    @authtoken @unit
    Scenario: Assert access token is valid and continue (unit)
        Given the Spotify API is mocked
        When I assert the access token is valid
        Then the access token should stay the same

    @refreshtoken @unit
    Scenario: Assert access oken is invalid and request another (unit)
        Given the Spotify API is mocked
        When I assert the access token is invalid
        Then the access token should be refreshed

