import 'package:flutter/material.dart';
import 'package:flute_music_player/flute_music_player.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'databaseHelper.dart';
import 'dialog.dart';

double _value = 0;
enum PlayerState { stopped, playing, paused }

class SongList extends StatefulWidget {
  const SongList();

  @override
  _SongListState createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  final dbHelper = DatabaseHelper.instance;
  List<Song> _songs = new List<Song>();
  Song _current = new Song(0, "  ", "  ", "  ", 0, 0, "  ", "  ");

  MusicFinder audioPlayer;
  Duration duration;
  Duration position;

  var _playerState = PlayerState.stopped;
  IconData _icon = Icons.play_circle_outline;

  static const List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.amber,
    Colors.deepOrangeAccent,
    Colors.deepPurple,
    Colors.green
  ];

  get durationText {
    if(duration == null){
      return "";
    }
    int minute = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    if(seconds >= 10) {
      return minute.toString() + ":" + seconds.toString();
    }
    return minute.toString() + ":0" + seconds.toString();
  }
  get positionText {
    if(position == null){
      return "";
    }
    int minute = position.inMinutes;
    int seconds = position.inSeconds % 60;
    if(seconds >= 10) {
      return minute.toString() + ":" + seconds.toString();
    }
    return minute.toString() + ":0" + seconds.toString();  }


  @override
  void initState() {
    super.initState();
    initPlayer();
  }

  _insert(Song s) async {

    // get a reference to the database
    // because this is an expensive operation we use async and await
    Database db = await DatabaseHelper.instance.database;
    //if record already existed, return.
    int sID = s.id;
    var queryResult = await db.rawQuery('SELECT * FROM songs_table WHERE _id=' + '$sID');
    if(queryResult != null && queryResult.length != 0 ){
      print("record existed");
      return;
    }
    // row to insert
    Map<String, dynamic> row = {
      DatabaseHelper.columnId : s.id,
      DatabaseHelper.columnTitle  : s.title,
      DatabaseHelper.columnArtist : s.artist,
      DatabaseHelper.columnAlbum : s.album,
      DatabaseHelper.columnUrl : s.uri,
      DatabaseHelper.columnAlbumArt : s.albumArt,
      DatabaseHelper.columnDuration : s.duration,
      DatabaseHelper.columnAlbumid : s.albumId
    };

    // do the insert and get the id of the inserted row
    int id = await db.insert(DatabaseHelper.table, row);
    //update song list.
    setState(() {
      _songs.add(s);
    });
    print("inserted : ");
    print(id);
    // show the results: print all rows in the db
    print(await db.query(DatabaseHelper.table));
  }

  void initPlayerHandler(){
    audioPlayer.setDurationHandler((d) => setState(() {
      duration = d;
    }));

    audioPlayer.setPositionHandler((p) => setState(() {
      position = p;
    }));

    audioPlayer.setCompletionHandler(() {
      onComplete();
      setState(() {
        position = duration;
      });
    });

    audioPlayer.setErrorHandler((msg) {
      setState(() {
        _playerState = PlayerState.stopped;
        duration = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    });
  }

  void initPlayer() async {
    audioPlayer = new MusicFinder();
    initPlayerHandler();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var res = await dbHelper.queryAllRows();
    List<Song> list =
    res.isNotEmpty ? res.map((c) => Song.fromMap(c)).toList() : [];
    setState(() {
      for(int i = 0; i < list.length; i++){
        _songs.add(list[i]);
      }
      int idx = prefs.getInt("song");
      print(idx);
      if(idx != null && _songs[idx] != null){
        _current = _songs[idx];
        print(_current.uri);
      }
    });
    print(await dbHelper.queryAllRows());
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.stop();
  }

  void _query() async {
    final allRows = await dbHelper.queryAllRows();
    print('query all rows:');
    allRows.forEach((row) => print(row));
  }

  void _update(Song s) async {
    // row to update
    Map<String, dynamic> row = {
      DatabaseHelper.columnId : s.id,
      DatabaseHelper.columnTitle  : s.title,
      DatabaseHelper.columnArtist : s.artist,
      DatabaseHelper.columnAlbum : s.album,
      DatabaseHelper.columnUrl : s.uri,
      DatabaseHelper.columnAlbumArt : s.albumArt,
      DatabaseHelper.columnDuration : s.duration,
      DatabaseHelper.columnAlbumid : s.albumId
    };
    final rowsAffected = await dbHelper.update(row);
    print('updated $rowsAffected row(s)');
  }

  void _delete() async {
    // Assuming that the number of rows is the id for the last row.
    final id = await dbHelper.queryRowCount();
    final rowsDeleted = await dbHelper.delete(id);
    print('deleted $rowsDeleted row(s): row $id');
  }

  //load all the songs from local
  loadSongs() async {
    var songs;
    songs = await MusicFinder.allSongs();
    songs = new List<Song>.from(songs);
    for(Song s in songs){
      _insert(s);
    }
  }

  onChanged(double value) {
    setState(() {
      _value = value;
      print(_value);
    });
  }

  void onComplete() {
    setState(() => _playerState = PlayerState.stopped);
    playNext();
  }

  // add a isLocal parameter to play a local file
  playLocal(String url) async {
    final result = await audioPlayer.play(url);
    if (result == 1) setState(() => _playerState = PlayerState.playing);
  }

  playPause(Song s) async {
    print(_playerState);
    print(s.uri);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //When switch songs
    if(_current != s){
      setState(() {
        stop();
        playLocal(s.uri);
        _icon = Icons.pause_circle_outline;
        _current = s;
        //store the index of songs.
        prefs.setInt("song", _songs.indexOf(s));
      });
      print("after" + _playerState.toString());
      return;
    }
    if(_playerState == PlayerState.playing){
      print("ready to pause");
      pause();
      setState(() {
        _icon = Icons.play_circle_outline;
        _current = s;
        //store the index of songs.
        prefs.setInt("song", _songs.indexOf(s));
      });
    }else{
      print("ready to play");
      playLocal(s.uri);
      setState(() {
        _icon = Icons.pause_circle_outline;
        _current = s;
        //store the index of songs.
        prefs.setInt("song", _songs.indexOf(s));
      });
    }
  }

  pause() async {
    final result = await audioPlayer.pause();
    if (result == 1) setState(() => _playerState = PlayerState.paused);
  }

  stop() async {
    final result = await audioPlayer.stop();
    if (result == 1) {
      setState(() {
        _playerState = PlayerState.stopped;
        position = new Duration(seconds: 0);
      });
    }
  }

  playNext(){
    print("next");
    int n = _songs.indexOf(_current);
    print(n);
    Song next = _songs[(n+1) % _songs.length];
    setState(() {
      _current = next;
      _icon = Icons.pause_circle_outline;
      audioPlayer = new MusicFinder();
      initPlayerHandler();
      _playerState = PlayerState.playing;
    });
    audioPlayer.play(_current.uri);
  }

  //Todo: Make selected song bigger
  @override
  Widget build(BuildContext context) {
    Widget _buildSongList() {
      return ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (BuildContext context, int index)
      {
        return new ListTile(
          //Todo: add delete when long pressed.\
          onTap: () => playPause(_songs[index]),
          leading: GestureDetector(
            child: new CircleAvatar(
              backgroundColor: _colors[index % _colors.length],
              child: Text(_songs[index].title.substring(0, 1)),
            ),
          ),
          title: Text(_songs[index].title, style: TextStyle(fontSize: 18.0), maxLines: 1,),
          subtitle: Text(_songs[index].artist, style: TextStyle(color: Colors.grey),),
          trailing: IconButton(
              icon: new Icon(Icons.more_vert),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                final update = await Dialogs.saveCancelDialog(context, _songs[index]);
                if(update == DialogOptions.Save) {
                  setState(() {
                    _songs[index].title = prefs.getString("songTitle");
                    _songs[index].artist = prefs.getString("songArtist");
                    _songs[index].album = prefs.getString("songAlbum");
                    _update(_songs[index]);
                  });
                }
                },
          ),
        );
      },
      );
    }

    final listView = Container(
        child: new Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        _buildSongList(),
        Container(
          //Todo: change the size
          height: 60.0,
          color: Colors.blue[100],
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.blue[200],
                  child: Text(
                    _current.title[0],
                    style: TextStyle(color: Colors.black),),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(positionText, style: TextStyle(fontSize: 12.0),),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.red,
                                inactiveTrackColor: Colors.black,
                                trackHeight: 2.0,
                                thumbColor: Colors.yellow,
                                showValueIndicator: ShowValueIndicator.always,
                                thumbShape:
                                RoundSliderThumbShape(enabledThumbRadius: 8.0),
                                overlayColor: Colors.purple.withAlpha(32),
                                overlayShape:
                                RoundSliderOverlayShape(overlayRadius: 8.0),
                              ),
                              child: Slider(
                                //Todo: make the change after drag is done.
                                  min: 0.0,
                                  max: _current.duration.toDouble()+1000,
                                  value: position?.inMilliseconds?.toDouble() ?? 0,
                                  onChanged: (double value) =>
                                      audioPlayer.seek((value / 1000).roundToDouble(),),
                              ),
                            ),
                          ),
                          Text(durationText, style: TextStyle(fontSize: 12.0),),
                        ],
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                            child: Text(
                                _current.artist + "  -  " + _current.title, maxLines: 1,)),
                        InkWell(
                          child: new Icon(_icon),
                          onTap: () {playPause(_current);},),
                        InkWell(
                          child: Icon(Icons.skip_next),
                          onTap: () => playNext(),
                        ),
                        Icon(Icons.list)
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        )
      ],
    ));

    final myAppBar = AppBar(
      title: Text("My Music Player"),
      leading: IconButton(
        icon: Icon(Icons.menu),
        onPressed: () => print("Menu is tapped"),
      ),
      bottom: new PreferredSize(
          child: Container(
            child: Material(
              color: Colors.blue[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.search,
                    ),
                    onPressed: () => print("Search is tapped"),
                    splashColor: Colors.red,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.sort,
                    ),
                    onPressed: () => print("Sort is tapped"),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                    ),
                    onPressed: () { print("Refresh is tapped"); loadSongs();},
                  ),
                ],
              ),
            ),
          ),
          preferredSize: const Size.fromHeight(50.0)),
      actions: <Widget>[
        Icon(Icons.share),
        Icon(Icons.more_vert),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: myAppBar,
      body: listView,
    );
  }
/*
  void onChangeEnd(double value) {
    audioFinder
  }*/
}
