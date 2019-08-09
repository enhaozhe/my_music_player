import 'package:flute_music_player/flute_music_player.dart';

class PlaylistItem {
  Song song;
  bool isAdded;

  PlaylistItem(this.song, this.isAdded);

  PlaylistItem.fromMap(Map m) {
    song = new Song(
        m["songID"],
        m["artist"],
        m["title"],
        m["album"],
        m["albumId"],
        m["duration"],
        m["uri"],
        m["albumArt"]);
    isAdded = (m['isAdded'] == 1)?true:false;
  }
}