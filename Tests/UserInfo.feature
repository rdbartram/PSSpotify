@profile
Feature: Get information and statistics pertaining to user

Information such as the user profile is important when determining the correct country to set when retrieving tracks.
Statistics are also useful to see what a users top tracks/artists are and what they've recently played

    Background: The PSSpotify Module is imported
        Given the PSSpotify module is imported

    Scenario Outline: Get user profile (Integ)
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
        And get <user> userprofile online
        Then a Spotify UserProfile object should be returned
        And the Spotify UserProfile should have id <user>

        Scenarios: Current logged on user
            | user    |
            | current |

            Scenarios: other users
            | user         |
            | justinbieber |

    @unit
    Scenario Outline: Get user profile (Unit)
        Given the Spotify API is mocked
        And a Spotify RefreshToken is specified
        When I connect to Spotify
        And get <user> userprofile mocked
        Then a Spotify UserProfile object should be returned
        And the Spotify UserProfile should have id <user>

        Scenarios: Current logged on user
            | user    |
            | current |

            Scenarios: other users
            | user         |
            | justinbieber |

    @unit @stats
    Scenario Outline: Get user top played artists (Unit)
        Given the Spotify API is mocked
        And a Spotify RefreshToken is specified
        When I connect to Spotify
        And mock users top <number> played artists
        Then users top <number> played artists should be returned
        And mock users top <number> played artists with limit of <return> and skip of <skip>
        Then return users top <return> played artists but skip the first <skip>

        Examples: Get x artists
            | Number | Skip | Return |
            | 1      | 0    | 1      |
            | 2      | 1    | 1      |
            | 3      | 1    | 2      |


    @unit @stats
    Scenario Outline: Get user top played tracks (Unit)
        Given the Spotify API is mocked
        And a Spotify RefreshToken is specified
        When I connect to Spotify
        And mock users top <number> played tracks
        Then users top <number> played tracks should be returned
        And mock users top <number> played tracks with limit of <return> and skip of <skip>
        Then return users top <return> played tracks but skip the first <skip>

        Examples: Get x tracks
            | Number | Skip | Return |
            | 1      | 0    | 1      |
            | 2      | 1    | 1      |
            | 3      | 1    | 2      |