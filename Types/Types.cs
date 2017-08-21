using System;
using System.Collections;

namespace PSSpotify
{
    public class SessionInfo {
        public Headers Headers;
        public string RootUrl;
        public int Expires;
        public string RefreshToken;
        public APIEndpoints APIEndpoints;
        public UserProfile CurrentUser;
    }

    public abstract class Object {
        public string Id;
        public string Uri;
        public string ExternalUrl;
        public string Type;
    }

    public abstract class MusicObject : Object {
        public string Name;
        public string[] Markets;
    }

    public class UserProfile : Object {
        public DateTime Birthdate;
        public string Country;
        public string DisplayName;
        public string Email;
        public int Followers;
        public string[] Images;
        public string Product;

        public override string ToString(){
            return DisplayName;
        }
    }

    public class APIEndpoints {
        public string AuthorizationEndpoint;
        public string TokenEndpoint;
        public string RedirectUri;

        public override string ToString(){
            return string.Format("AuthEndpoint: {0}; TokenEndpoint: {1}; RedirectUri: {2}",AuthorizationEndpoint, TokenEndpoint, RedirectUri);
        }
    }

    public class Headers {
        public string Authorization;
        public string ContentType;

        static public implicit operator System.Collections.Hashtable(Headers headers)
        {
            var dict = new System.Collections.Hashtable();
            dict.Add("Authorization", headers.Authorization);
            dict.Add("content-type", headers.ContentType);

            return dict;
        }

        public override string ToString(){
            return string.Format("Authorization: {0}; content-type: {1}",Authorization, ContentType);
        }
    }

    public class Genre {
        public string Name;

        public Genre (string name) {
            Name = name;
        }
    }

    public class Track : TrackSimplified {

        public string[] ExternalIds;
        public int Popularity;

        public override string ToString() {
            return Name;
        }
    }

    public class TrackSimplified : MusicObject {
        public AlbumSimplified Album;
        public ArtistSimplified[] Artists;
        public int DiscNumber;
        public int DurationMs;
        public bool explict;
        public string PreviewUrl;
        public int TrackNumber;
        public bool IsPlayable;
        public LinkedTrack LinkedFrom;

        public override string ToString() {
            return Name;
        }
    }

    public class LinkedTrack : Object {
    }

    public class Album : AlbumSimplified {
        public string[] Genres;
        public int Popularity;
        public string ReleaseDate;
        public string ReleaseDatePrecision;
        public TrackSimplified[] Tracks;
        public CopyRight[] CopyRights;

        public override string ToString() {
            return Name;
        }
    }

    public class AlbumSimplified : MusicObject {
        public string AlbumType;
        public Artist[] Artists;
        public string Label;
        public Image[] Images;

        public override string ToString() {
            return Name;
        }
    }

    public class CopyRight {
        public string text;
        public string type;

        public override string ToString() {
            return text;
        }
    }

    public class Image {
        public int height;
        public string url;
        public int width;

        public override string ToString() {
            return url;
        }
    }

    public class Artist : ArtistSimplified {
        public int Followers;
        public string[] Genres;
        public Image[] Images;
        public int Popularity;

        public override string ToString() {
            return Name;
        }
    }

    public class ArtistSimplified : MusicObject {
        public override string ToString() {
            return Name;
        }
    }

    public class PlaylistSimplified : MusicObject {
        public bool Collaborative;
        public bool Public;
        public Image[] Images;
        public UserProfile Owner;
        public string SnapshotId;

        public override string ToString() {
            return Name;
        }
    }

    public class Playlist : PlaylistSimplified {
        public string Description;
        public FollowersObject Followers;

        public override string ToString() {
            return Name;
        }
    }

    public class FollowersObject {
        public string href;
        public int Total;

        public override string ToString() {
            return Total.ToString();
        }
    }

    public class LibraryTrackObject {
        public DateTime Added;
        public Track Track;

        public override string ToString() {
            return Track.Name;
        }
    }

    public class LibraryAlbumObject {
        public DateTime Added;
        public Album Album;

        public override string ToString() {
            return Album.Name;
        }
    }

    public class Category {
        public string Url;
        public Image[] Icons;
        public string Id;
        public string Name;

        public override string ToString() {
            return Name;
        }
    }

    public class Device {
        public string id;
        public bool IsActive;
        public bool IsRestricted;
        public string Name;
        public string Type;
        public int VolumePercent;

        public override string ToString() {
            return string.Format("{0} | {1}", Name,Type);
        }
    }

    public class Player {
        public Device Device;
        public string RepeatState;
        public string ShuffleState;
        public MusicObject[] Queue;
        public DateTime TimeStamp;
        public TimeSpan Progress;
        public bool IsPlaying;
        public Track CurrentTrack;

        public override string ToString() {
            return string.Format("State: {0} | Elapsed: {1} | Track: {2} | Device: {3}", IsPlaying == true ? "Playing" : "Paused" ,Progress.ToString(), CurrentTrack.Name, Device.Name);
        }
    }

    public class CurrentTrack {
        public MusicObject[] Queue;
        public DateTime TimeStamp;
        public TimeSpan Progress;
        public bool IsPlaying;
        public Track Track;

        public override string ToString() {
            return string.Format("State: {0} | Elapsed: {1} | Track: {2}", IsPlaying == true ? "Playing" : "Paused" ,Progress.ToString(), Track.Name);
        }
    }
}