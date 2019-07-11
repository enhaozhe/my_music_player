import 'package:meta/meta.dart';

class Song {
  final String directory;
  final String songName;
  final String singer;
  final String songLength;
  final String lyrics;
  final image;

  const Song({
    this.directory,
    this.songName,
    this.singer,
    this.songLength,
    this.lyrics,
    this.image
}) : assert(songName != null);

}