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

class _SongListState extends State<SongList> with WidgetsBindingObserver{
  final dbHelper = DatabaseHelper.instance;
  List<Song> _songs;
  Song _current = new Song(
      0,
      " ",
      " ",
      " ",
      0,
      0,
      " ",
      " ");

  MusicFinder audioPlayer;
  Duration duration;
  Duration position;

  var _playerState = PlayerState.stopped;
  IconData _icon = Icons.play_circle_outline;
  IconData _iconMenuBack = Icons.menu;
  IconData _iconShareDelete = Icons.share;
  String _title = "My Music Player";
  int _deleteCount = 0;
  List<Song> _deleteList;
  bool _deleteMode = false;
  List<bool> checkedList;

  final key = new GlobalKey<ScaffoldState>();

  static const List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.amber,
    Colors.deepOrangeAccent,
    Colors.deepPurple,
    Colors.green
  ];

  get durationText {
    if (duration == null) {
      return "";
    }
    int minute = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    if (seconds >= 10) {
      return minute.toString() + ":" + seconds.toString();
    }
    return minute.toString() + ":0" + seconds.toString();
  }

  get positionText {
    if (position == null) {
      return "";
    }
    int minute = position.inMinutes;
    int seconds = position.inSeconds % 60;
    if (seconds >= 10) {
      return minute.toString() + ":" + seconds.toString();
    }
    return minute.toString() + ":0" + seconds.toString();
  }

  @override
  void initState() {
    super.initState();
    _songs = new List<Song>();
    audioPlayer = new MusicFinder();
    initPlayerHandler();
    initPlayer();
    WidgetsBinding.instance.addObserver(this);
  }

  _insert(Song s) async {
    // get a reference to the database
    // because this is an expensive operation we use async and await
    Database db = await DatabaseHelper.instance.database;
    //if record already existed, return.
    int sID = s.id;
    var queryResult =
    await db.rawQuery('SELECT * FROM songs_table WHERE id=' + '$sID');
    if (queryResult != null && queryResult.length != 0) {
      print("record existed");
      return;
    }
    // row to insert
    Map<String, dynamic> row = {
      DatabaseHelper.columnId: s.id,
      DatabaseHelper.columnTitle: s.title,
      DatabaseHelper.columnArtist: s.artist,
      DatabaseHelper.columnAlbum: s.album,
      DatabaseHelper.columnUrl: s.uri,
      DatabaseHelper.columnAlbumArt: s.albumArt,
      DatabaseHelper.columnDuration: s.duration,
      DatabaseHelper.columnAlbumid: s.albumId
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

  void initPlayerHandler() {
    audioPlayer.setDurationHandler((d) =>
        setState(() {
          duration = d;
        }));

    audioPlayer.setPositionHandler((p) =>
        setState(() {
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var res = await dbHelper.queryAllRows();
    List<Song> list =
    res.isNotEmpty ? res.map((c) => Song.fromMap(c)).toList() : [];
    print("list size = " + list.length.toString());
    setState(() {
      for (int i = 0; i < list.length; i++) {
        _songs.add(list[i]);
        print("songList added : " + _songs[i].uri);
      }
      print("songsList size = " + _songs.length.toString());
      int idx = prefs.getInt("song");
      print("stored index = " + idx.toString());
      if (idx != null && _songs.length > idx) {
        _current = _songs[idx];
        duration = new Duration(milliseconds: _current.duration);
        position = new Duration(milliseconds: prefs.getInt("position"));
      }else{
        duration = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      }
      checkedList = new List<bool>();
    });
    print(await dbHelper.queryAllRows());
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.stop();
    WidgetsBinding.instance.removeObserver(this);
  }

  //Store data before killing the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.inactive || state == AppLifecycleState.paused){
      print("suspended");
      storeSharedData();
    }
    print(state.toString());
  }

  void storeSharedData() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("song", _songs.indexOf(_current));
    prefs.setInt("position", position.inMilliseconds);
  }

  void _query() async {
    final allRows = await dbHelper.queryAllRows();
    print('query all rows:');
    allRows.forEach((row) => print(row));
  }

  void _update(Song s) async {
    // row to update
    Map<String, dynamic> row = {
      DatabaseHelper.columnId: s.id,
      DatabaseHelper.columnTitle: s.title,
      DatabaseHelper.columnArtist: s.artist,
      DatabaseHelper.columnAlbum: s.album,
      DatabaseHelper.columnUrl: s.uri,
      DatabaseHelper.columnAlbumArt: s.albumArt,
      DatabaseHelper.columnDuration: s.duration,
      DatabaseHelper.columnAlbumid: s.albumId
    };
    final rowsAffected = await dbHelper.update(row);
    print('updated $rowsAffected row(s)');
  }

  void _delete(Song s) async {
    // Assuming that the number of rows is the id for the last row.
    int rowsDeleted;
    print("list length = " + _deleteList.length.toString());
      print("to be deleted: " + s.title);
      rowsDeleted = await dbHelper.delete(s.id);
      setState(() {
        if(_songs.contains(_current)){
          stop();
          _current = new Song(
              0, " ", " ", " ", 0, 0, " ", " ");
          duration = new Duration(seconds: 0);
          position = new Duration(seconds: 0);
        }
        _songs.remove(s);
      });
      print("rows deleted : " + rowsDeleted.toString());
    print('deleted $rowsDeleted row(s)');
  }

  //load all the songs from local
  loadSongs() async {
    var songs;
    songs = await MusicFinder.allSongs();
    songs = new List<Song>.from(songs);
    for (Song s in songs) {
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
    final result = await audioPlayer.play(url, isLocal: true);
    if (result == 1) setState(() => _playerState = PlayerState.playing);
  }

  playPause(Song s) async {
    print(_playerState);
    print(s.uri);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //When switch songs
    if (_current != s) {
      setState(() {
        stop();
        playLocal(s.uri);
        _icon = Icons.pause_circle_outline;
        _current = s;
      });
      print("after" + _playerState.toString());
      return;
    }
    if (_playerState == PlayerState.playing) {
      print("ready to pause");
      pause();
      setState(() {
        _icon = Icons.play_circle_outline;
        _current = s;
      });
    } else {
      print("ready to play");
      playLocal(s.uri);
      setState(() {
        _icon = Icons.pause_circle_outline;
        _current = s;
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

  playNext() {
    print("next");
    int n = _songs.indexOf(_current);
    print(n);
    Song next = _songs[(n + 1) % _songs.length];
    setState(() {
      _current = next;
      _icon = Icons.pause_circle_outline;
      audioPlayer = new MusicFinder();
      initPlayerHandler();
      _playerState = PlayerState.playing;
    });
    audioPlayer.play(_current.uri);
  }

  deleteMode() {
    setState(() {
      _deleteMode = true;
      _deleteList = new List<Song>();
      _iconMenuBack = Icons.arrow_back;
      _iconShareDelete = Icons.delete;
      _title = _deleteCount.toString() + " Selected";
      checkedList = new List<bool>.filled(_songs.length, false);
    });
  }

  void quitDeleteMode() {
    setState(() {
      _deleteMode = false;
      _deleteList.clear();
      _iconMenuBack = Icons.menu;
      _iconShareDelete = Icons.share;
      _title = "My Music Player";
      _deleteCount = 0;
    });
  }

  void shareOrDelete(){
    if (_iconShareDelete == Icons.share) {
      print("share is pressed");
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: Center(child: Text("Remove Following Songs?", style: TextStyle(fontSize: 16.0),)),
            content: Container(
              height: 200.0,
              child: buildDeleteList(),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text("No"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              RaisedButton(
                child: Text("Yes", style: TextStyle(color: Colors.white),),
                onPressed: () {
                  for(Song s in _deleteList) {
                    _delete(s);
                  }
                  key.currentState.showSnackBar(
                      new SnackBar(
                          content: (_deleteList.length == 1) ? new Text("1 item is deleted!"): new Text(_deleteList.length.toString() + " items are deleted!")));
                  Navigator.of(context).pop();
                  quitDeleteMode();
                  },
              )
            ],
          );
        },
      );
      print("delete is pressed");
    }
  }

  void checkBoxFunc(int index, bool value){
    setState(() {
      checkedList[index] = value;
      _deleteCount = value ? _deleteCount+1 : _deleteCount-1;
      _title = _deleteCount.toString() + " Selected";
      if(value){
        _deleteList.add(_songs[index]);
      }else{
        _deleteList.remove(_songs[index]);
      }
      print(_deleteList);
    });
  }

  //Todo: Make selected song bigger
  @override
  Widget build(BuildContext context) {
    Widget moreOrDeleteButton(int index){
      if(_deleteMode){
        return Checkbox(
          value: checkedList[index],
          onChanged: (bool value) {
            setState(() {
              print("is checked : " + value.toString());
              checkBoxFunc(index, value);
            });
          },
        );
      }else{
        return IconButton(
          icon: new Icon(Icons.more_vert),
          onPressed: () async {
              SharedPreferences prefs =
              await SharedPreferences.getInstance();
              final update =
              await Dialogs.saveCancelDialog(context, _songs[index]);
              if (update == DialogOptions.Save) {
                setState(() {
                  _songs[index].title = prefs.getString("songTitle");
                  _songs[index].artist =
                      prefs.getString("songArtist");
                  _songs[index].album = prefs.getString("songAlbum");
                  _update(_songs[index]);
                });
              }
          },
        );
      }
    }

    print("if in delete mode : " + _deleteMode.toString());
    Widget _buildSongList() {
      return ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (BuildContext context, int index) {
          return new Column(
            children: <Widget>[
              GestureDetector(
                onLongPress: () =>
                (_deleteMode)
                    ? quitDeleteMode()
                    : deleteMode(),
                child: new ListTile(
                  //check icon to see if in delete mode.
                  onTap: () { if(!_deleteMode) {
                    playPause(_songs[index]);
                    }else{
                    setState(() {
                      checkBoxFunc(index, !checkedList[index]);
                    });
                  }
          },
                  leading: GestureDetector(
                    child: new CircleAvatar(
                      backgroundColor: _colors[index % _colors.length],
                      child: Text(_songs[index].title.substring(0, 1)),
                    ),
                  ),
                  title: Text(
                    _songs[index].title,
                    style: TextStyle(fontSize: 18.0),
                    maxLines: 1,
                  ),
                  subtitle: Text(
                    _songs[index].artist,
                    style: TextStyle(color: Colors.grey),
                  ),
                  trailing: moreOrDeleteButton(index),
                ),
              ),
              new Divider(
                height: 1.0,
                color: Colors.grey[500],
              )
            ],
          );
        },
      );
    }

    String songArtist = (_current.title == " ") ? "" : _current.artist + " - " + _current.title;

    final listView = Container(
        child: new Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            _buildSongList(),
            Container(
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
                        style: TextStyle(color: Colors.black),
                      ),
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
                              Text(
                                positionText,
                                style: TextStyle(fontSize: 12.0),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.red,
                                    inactiveTrackColor: Colors.black,
                                    trackHeight: 2.0,
                                    thumbColor: Colors.yellow,
                                    showValueIndicator: ShowValueIndicator
                                        .always,
                                    thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: 8.0),
                                    overlayColor: Colors.purple.withAlpha(32),
                                    overlayShape:
                                    RoundSliderOverlayShape(overlayRadius: 8.0),
                                  ),
                                  child: Slider(
                                    min: 0.0,
                                    max: _current.duration.toDouble() + 1000,
                                    value:
                                    position?.inMilliseconds?.toDouble() ?? 0,
                                    onChanged: (double value) =>
                                        audioPlayer.seek(
                                          (value / 1000).roundToDouble(),
                                        ),
                                  ),
                                ),
                              ),
                              Text(
                                durationText,
                                style: TextStyle(fontSize: 12.0),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                                child: Text(
                                  songArtist,
                                  maxLines: 1,
                                )),
                            InkWell(
                              child: new Icon(_icon),
                              onTap: () {
                                playPause(_current);
                              },
                            ),
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
      title: Text(_title),
      leading: IconButton(
        icon: Icon(_iconMenuBack),
        onPressed: () {
          if (_iconMenuBack == Icons.menu) {
            print("Menu is tapped");
          } else {
            quitDeleteMode();
            print("back is tapped");
          }
        },
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
                    onPressed: !_deleteMode ? ()=> print("Search is tapped") : null,
                    splashColor: Colors.red,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.sort,
                    ),
                    onPressed: !_deleteMode ? ()=> print("Sort is tapped") : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                    ),
                    onPressed: !_deleteMode ? ()=> loadSongs() : null,
                  ),
                ],
              ),
            ),
          ),
          preferredSize: const Size.fromHeight(50.0)),
      actions: <Widget>[
        IconButton(
          icon: Icon(_iconShareDelete),
          onPressed: () => shareOrDelete(),
        ),
      ],
    );

    return Scaffold(
      key: key,
      backgroundColor: Colors.white,
      appBar: myAppBar,
      body: listView,
    );
  }

  Widget buildDeleteList(){
    return ListView.builder(
        itemCount: _deleteCount,
        itemBuilder: (BuildContext context, int index){
          return Column(
            children: <Widget>[
              Text(_deleteList[index].title),
              Divider(height: 1.0, color: Colors.grey[500],)
            ],
          );
    });
  }
}
