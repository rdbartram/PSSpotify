@playlist
Feature: Provide CRU actions for playlists

Users need to be able to create, get and set playlists aswell as items in said playlists

    Background: The PSSpotify Module is imported
        Given the PSSpotify module is imported

    @unit
    Scenario Outline: Create new playlist, check it exists, set some information and delete (Unit)
        Given the Spotify API is mocked
        And a Spotify RefreshToken is specified
        When I connect to Spotify
        And create playlist <name> which ispublic:<IsPublic> and Collaborative:<Collaborative>
        Then playlist <name> should exist and be ispublic:<IsPublic> and Collaborative:<Collaborative>
        And when I set playlist <name> description to <description>
        Then playlist <name> should have <description> as description

        Examples: Test Playlists
            | Name  | Description     | IsPublic | Collaborative |
            | Test1 | MyTest Playlist | true     | true          |
            | Test2 | MyTest Playlist | false    | false         |
            | Test3 | MyTest Playlist | true     | false         |
            | Test4 | MyTest Playlist | false    | true          |