@oauth
Feature: Ability to create OAuth session using clientsecret methods

In order to be call various APIs it is necessary to authenticate using OAuth

    Background: The OAuth module must be imported
        Given the OAuth module is imported

    @authtoken @unit
    Scenario: Get Access token using clientsecret (Unit)
        Given the OAuth API is mocked
        But an OAuth RefreshToken isn't specified
        When I request an auth code from the API
        And I request an access token from the API
        And an OAuth Session object should be returned
        And an OAuth Session object should be valid
        And an OAuth Session object permissions should match
            """
            Scope1 Scope2
            """

    @refreshtoken @unit
    Scenario: Get Access token using refresh token (Unit)
        Given the OAuth API is mocked
        And an OAuth RefreshToken is specified
        When I request an access token from the API
        And an OAuth Session object should be returned
        And an OAuth Session object should be valid
        And an OAuth Session object permissions should match
            """
            Scope1 Scope2
            """