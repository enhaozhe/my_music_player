import 'package:flutter/material.dart';
import 'package:flute_music_player/flute_music_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import 'databaseHelper.dart';
import 'dialog.dart';
import 'songInfo.dart';
import 'loadSongsRoute.dart';
import 'playlistDatabase.dart';
import 'playlistItem.dart';
import 'dragBar.dart';

double _value = 0;
const double _item_height = 50.0;
enum PlayerState { stopped, playing, paused }

class SongList extends StatefulWidget {
  const SongList();

  @override
  _SongListState createState() => _SongListState();
}

//Todo: Add database for playlist
class _SongListState extends State<SongList> with WidgetsBindingObserver {
  final dbHelper = DatabaseHelper.instance;
  final playlistDb = PlaylistDatabase.instance;
  List<Song> _songs = new List<Song>();
  List<PlaylistItem> _playlist = new List<PlaylistItem>();
  Song _current = new Song(0, " ", " ", " ", 0, 0, " ", " ");

  MusicFinder audioPlayer;
  Duration duration;
  Duration position;

  var _playerState = PlayerState.stopped;
  IconData _icon = Icons.play_circle_outline;
  IconData _iconMenuBack = Icons.menu;
  IconData _iconShareDelete = Icons.share;
  IconData _playMode;
  String _title = "My Music Player";
  int _deleteCount = 0;
  List<Song> _deleteList;
  bool _deleteMode = false;
  List<bool> checkedList;
  int _playModeValue;
  int _currentInPlaylist;
  ScrollController _scrollController;
  ScrollController _playlistScrollController = new ScrollController();

  final key = new GlobalKey<ScaffoldState>();

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
    audioPlayer = new MusicFinder();
    initPlayerHandler();
    initPlayer();
    _scrollController = new ScrollController();
    WidgetsBinding.instance.addObserver(this);
  }

  void initPlayerHandler() {
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

  Map<String, dynamic> getRow(Song s ){
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
    return row;
  }

  Map<String, dynamic> getPlaylistRow(Song s, bool flag){
    int isAdded = flag ? 1:2;
    Map<String, dynamic> row = {
      PlaylistDatabase.columnId: s.id,
      PlaylistDatabase.columnTitle: s.title,
      PlaylistDatabase.columnArtist: s.artist,
      PlaylistDatabase.columnAlbum: s.album,
      PlaylistDatabase.columnUrl: s.uri,
      PlaylistDatabase.columnAlbumArt: s.albumArt,
      PlaylistDatabase.columnDuration: s.duration,
      PlaylistDatabase.columnAlbumid: s.albumId,
      PlaylistDatabase.columnIsAdded: isAdded
    };
    return row;
  }

  void initPlayer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Song list.
    var res = await dbHelper.queryAllRows();
    List<Song> list =
        res.isNotEmpty ? res.map((c) => Song.fromMap(c)).toList() : [];
    print("list size = " + list.length.toString());
    //Playlist
    var playlistCount = await playlistDb.queryRowCount();
    var playlistRes = await playlistDb.queryAllRows();
    print("Playlist DB Record number: " + playlistCount.toString());
    List<PlaylistItem> playlist = playlistRes.isNotEmpty
        ? playlistRes.map((c) => PlaylistItem.fromMap(c)).toList()
        : [];
    setState(() {
      //retrieve play mode
      int savedPlayMode = prefs.getInt("play mode");
      switch(savedPlayMode){
        case 2:
          _playMode = Icons.shuffle;
          _playModeValue = 2;
          break;
        case 3:
          _playMode = Icons.repeat_one;
          _playModeValue = 3;
          break;
        default:
          _playMode = Icons.sort;
          _playModeValue = 1;
          break;
      }
      print("Play mode is : " + _playModeValue.toString());

      _playlistScrollController.addListener((){
        //Scroll to the current song.
        for(int i = 0; i < _playlist.length; i++) {
          if(_playlist[i].song == _current) {
            _playlistScrollController.animateTo(i * _item_height, duration: new Duration(seconds: 2), curve: Curves.ease);
          }
        }
      });

      for (int i = 0; i < list.length; i++) {
        _songs.add(list[i]);
        print("songList added : " + _songs[i].uri);
      }

      //TODO: Don't clear list every time update list.
      _songs.sort((a, b) {
        if (a.artist.compareTo(b.artist) == 0) {
          return a.title.compareTo(b.title);
        } else {
          return a.artist.compareTo(b.artist);
        }
      });
      //Todo: play list isn't in order, check database. insert doesn't function correctly
      //if the database is empty, copy song list.
      if (playlistCount == 0) {
        for (int i = 0; i < list.length; i++) {
          _playlist.add(new PlaylistItem(_songs[i], false));
          playlistDb.insert(getPlaylistRow(_songs[i], false));
          print("songList added : " + _playlist[i].song.uri);
        }
      } else {
        //read from database otherwise.
        for (int i = 0; i < playlist.length; i++) {
          _playlist.add(playlist[i]);
          print("playList added : " + _playlist[i].song.id.toString() + " is added :" +_playlist[i].isAdded.toString());
        }
      }

      print("songsList size = " + _songs.length.toString());
      int idx = prefs.getInt("song");
      print("stored index = " + idx.toString());
      if ((idx != null && idx >= 0) && _songs.length > idx) {
        _current = _songs[idx];
        duration = new Duration(milliseconds: _current.duration);
        position = new Duration(milliseconds: prefs.getInt("position"));
      } else {
        duration = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      }
      checkedList = new List<bool>();

    });
    //Todo: update _currentInPlaylist when play another song
    for(int i = 0 ; i < _playlist.length; i++){
      if(_playlist[i].song.id == _current.id){
        _currentInPlaylist = i;
      }
      //print(s.song.id.toString() + " : " + _current.id.toString());
    }
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
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      print("suspended");
      storeSharedData();
    }
    print(state.toString());
  }

  void storeSharedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("song", _songs.indexOf(_current));
    prefs.setInt("position", position.inMilliseconds);
    prefs.setInt("play mode", _playModeValue);

  }

  void _update(Song s) async {
    // row to update
    final rowsAffected = await dbHelper.update(getRow(s));
    print('updated $rowsAffected row(s)');
  }

  void _delete(Song s) async {
    // Assuming that the number of rows is the id for the last row.
    int rowsDeleted;
    print("list length = " + _deleteList.length.toString());
    print("to be deleted: " + s.title);
    rowsDeleted = await dbHelper.delete(s.id);
    setState(() {
      if (_songs.contains(_current)) {
        stop();
        _current = new Song(0, " ", " ", " ", 0, 0, " ", " ");
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
    await Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (BuildContext context) => new LoadSongsRoute(songs)));
    var res = await dbHelper.queryAllRows();
    setState(() {
      _songs.clear();
      initPlayer();
    });
  }

  onChanged(double value) {
    setState(() {
      _value = value;
      print(_value);
    });
  }

  void onComplete() {
    setState(() => _playerState = PlayerState.stopped);
    if(_playMode == Icons.repeat_one) {
      playNext(3);
    }else if(_playMode == Icons.shuffle){
      playNext(2);
    }else{
      playNext(1);
    }
  }

  // add a isLocal parameter to play a local file
  playLocal(String url) async {
    final result = await audioPlayer.play(url, isLocal: true);
    if (result == 1) setState(() => _playerState = PlayerState.playing);
  }

  playPause(Song s) async {
    print(_playerState);
    print(s.uri);
    //SharedPreferences prefs = await SharedPreferences.getInstance();
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
  //Todo: save playlist to database when state changes. Check play mode when click Play next
  playNext(int mode) {
    print("play next");
    int n = _songs.indexOf(_current);
    print(n);
    Song next;
    switch(mode){
      case 1:  //in order mode
        next = _playlist[(n + 1) % _playlist.length].song;
        break;
      case 2:  //shuffle mode
        var rng = new Random();
        int rn = rng.nextInt(_playlist.length-1);
        print("generated : " + rn.toString());
        next = _playlist[rn].song;
        break;
      case 3:  //cycle mode
        next = _current;
    }
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

  void shareOrDelete() {
    if (_iconShareDelete == Icons.share) {
      print("share is pressed");
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: Center(
                child: Text(
              "Remove Following Songs?",
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            )),
            content: Container(height: 200.0, child: buildDeleteList()),
            actions: <Widget>[
              FlatButton(
                child: Text("No"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              RaisedButton(
                child: Text(
                  "Yes",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  for (Song s in _deleteList) {
                    _delete(s);
                  }
                  key.currentState.showSnackBar(new SnackBar(
                      content: (_deleteList.length == 1)
                          ? new Text("1 item is deleted!")
                          : new Text(_deleteList.length.toString() +
                              " items are deleted!")));
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

  void checkBoxFunc(int index, bool value) {
    setState(() {
      checkedList[index] = value;
      _deleteCount = value ? _deleteCount + 1 : _deleteCount - 1;
      _title = _deleteCount.toString() + " Selected";
      if (value) {
        _deleteList.add(_songs[index]);
      } else {
        _deleteList.remove(_songs[index]);
      }
      print(_deleteList);
    });
  }

  void _edit(int index) async {
    Navigator.pop(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final update = await Dialogs.saveCancelDialog(context, _songs[index]);
    if (update == DialogOptions.Save) {
      setState(() {
        _songs[index].title = prefs.getString("songTitle");
        _songs[index].artist = prefs.getString("songArtist");
        _songs[index].album = prefs.getString("songAlbum");
        _update(_songs[index]);
        _songs.clear();
        initPlayer();
        key.currentState
            .showSnackBar(new SnackBar(content: (Text("Changes are Saved!"))));
      });
    }
  }

  //Playlist UI
  void buildPlaylist() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return new Column(
            children: <Widget>[
              Column(
                children: <Widget>[
                  ListTile(
                    title: Text("play mode"),
                  ),
                  Divider(
                    height: 1,
                    color: Colors.grey[500],
                  )
                ],
              ),
              Flexible(
                child: ListView.builder(
                    shrinkWrap: true,
                    controller: _playlistScrollController,
                    itemCount: _playlist.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        key: UniqueKey(),
                        child: Container(
                          height: _item_height,
                          padding: EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            color: _playlist[index].isAdded ? Colors.blue : null
                          ),
                          child: ListTile(
                            selected: index == _currentInPlaylist,
                            contentPadding: EdgeInsets.all(0),
                            dense: true,
                            leading: Padding(
                              padding: const EdgeInsets.fromLTRB(25, 0, 0, 0),
                              child: Text(
                                (index + 1).toString(),
                                style: TextStyle(
                                    color: index == _currentInPlaylist
                                        ? Colors.blue
                                        : Colors.black),
                              ),
                            ),
                            title: Text(
                              _playlist[index].song.title,
                              maxLines: 1,
                            ),
                            trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    print(_playlist[index].song.title + " is removed");
                                    _playlist.removeAt(index);
                                    //Todo: update the list after removal.
                                  });
                                }),
                          ),
                        ),
                      );
                    }),
              )
            ],
          );
        });

  }

  //Remove all added songs.
  void resetPlaylist(){
    setState(() {
      for(PlaylistItem i in _playlist){
        if(i.isAdded){
          _playlist.remove(i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget moreOrDeleteButton(int index) {
      if (_deleteMode) {
        return Checkbox(
          value: checkedList[index],
          onChanged: (bool value) {
            setState(() {
              print("is checked : " + value.toString());
              checkBoxFunc(index, value);
            });
          },
        );
      } else {
        return IconButton(
          color: _songs[index] == _current ? Colors.blue : Colors.black,
          icon: new Icon(Icons.more_vert),
          onPressed: () {
            showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return new Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        title: Center(
                          child: Text(
                            _songs[index].artist + " - " + _songs[index].title,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      Divider(
                        height: 1.0,
                        color: Colors.grey[500],
                      ),
                      ListTile(
                        leading: Icon(Icons.edit),
                        title: Text("Edit"),
                        dense: true,
                        onTap: () => _edit(index),
                      ),
                      Divider(
                        height: 1.0,
                        color: Colors.grey[500],
                      ),
                      ListTile(
                        leading: Icon(Icons.info_outline),
                        dense: true,
                        title: Text("Info"),
                        onTap: () =>
                            SongInfo.showSongInfo(context, _songs[index]),
                      ),
                    ],
                  );
                });
          },
        );
      }
    }

    print("if in delete mode : " + _deleteMode.toString());
    Widget _buildSongList() {
      return ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: _songs.length,
        itemBuilder: (BuildContext context, int index) {
          if (index == _songs.length - 1) {
            return Padding(
              key: UniqueKey(),
              padding: const EdgeInsets.all(16.0),
              child: new Center(
                child: Text(
                  _songs.length.toString() + " Songs",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          } else {
            return Container(
              key: UniqueKey(),
              child: GestureDetector(
                onLongPress: () =>
                    (_deleteMode) ? quitDeleteMode() : deleteMode(),
                child: new ListTile(
                  selected: _songs[index] == _current,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  dense: true,
                  //check icon to see if in delete mode.
                  onTap: () {
                    if (!_deleteMode) {
                      playPause(_songs[index]);
                    } else {
                      setState(() {
                        checkBoxFunc(index, !checkedList[index]);
                      });
                    }
                  },
                  leading: _deleteMode ? null : IconButton(
                      icon: Icon(Icons.add_box),
                      //shift the position of icon so it looks in center
                      padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                      onPressed: () {
                          print("Current Index : " + _currentInPlaylist.toString());
                          int idx = _currentInPlaylist+1;
                          for(int i = idx; i < _playlist.length; i++){
                            if(_playlist[i].isAdded){
                              idx++;
                            }else{
                              break;
                            }
                          }
                          setState(() {
                            _playlist.insert(idx,new PlaylistItem(_songs[index], true));
                          });
                          print(_songs[index].uri + " is inserted at " + idx.toString());
                          },),
                  title: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    _songs[index].title,
                                    style: TextStyle(
                                        fontSize: 17.0,
                                        color: _songs[index] == _current
                                            ? Colors.blue
                                            : Colors.black),
                                    maxLines: 1,
                                  ),
                                  Text(
                                    _songs[index].artist,
                                    style: TextStyle(
                                        fontSize: 13.0,
                                        color: _songs[index] == _current
                                            ? Colors.blue
                                            : Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          moreOrDeleteButton(index),
                        ],
                      ),
                      new Divider(
                        height: 1.0,
                        color: Colors.grey[500],
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        },
      );
    }

    String songArtist =
        (_current.title == " ") ? "" : _current.artist + " - " + _current.title;

    final listView = Container(
        child: new Column(
      children: <Widget>[
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(child: _buildSongList()),
                ],
              )),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  //TODO: Add function to this scroll bar.
                  InkWell(
                    child: Text("A", style: TextStyle(color: Colors.grey)),
                    onTap: () => _scrollController.animateTo(0,
                        duration: new Duration(seconds: 1), curve: Curves.ease),
                  ),
                  InkWell(
                    child: Text("B", style: TextStyle(color: Colors.grey)),
                    onTap: () => print("B is tapped"),
                  ),
                  InkWell(
                    child: Text("C", style: TextStyle(color: Colors.grey)),
                    onTap: () => print("A is tapped"),
                  ),
                  Text("D", style: TextStyle(color: Colors.grey)),
                  Text("E", style: TextStyle(color: Colors.grey)),
                  Text("F", style: TextStyle(color: Colors.grey)),
                  Text("G", style: TextStyle(color: Colors.grey)),
                  Text("H", style: TextStyle(color: Colors.grey)),
                  Text("I", style: TextStyle(color: Colors.grey)),
                  Text("J", style: TextStyle(color: Colors.grey)),
                  Text("K", style: TextStyle(color: Colors.grey)),
                  Text("L", style: TextStyle(color: Colors.grey)),
                  Text("M", style: TextStyle(color: Colors.grey)),
                  Text("N", style: TextStyle(color: Colors.grey)),
                  Text("O", style: TextStyle(color: Colors.grey)),
                  Text("P", style: TextStyle(color: Colors.grey)),
                  Text("Q", style: TextStyle(color: Colors.grey)),
                  Text("R", style: TextStyle(color: Colors.grey)),
                  Text("S", style: TextStyle(color: Colors.grey)),
                  Text("T", style: TextStyle(color: Colors.grey)),
                  Text("U", style: TextStyle(color: Colors.grey)),
                  Text("V", style: TextStyle(color: Colors.grey)),
                  Text("W", style: TextStyle(color: Colors.grey)),
                  Text("X", style: TextStyle(color: Colors.grey)),
                  Text("Y", style: TextStyle(color: Colors.grey)),
                  Text("Z", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 60.0,
            color: Colors.blue[100],
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  //Todo: Add functions when select mode.
                  child: PopupMenuButton(
                      icon: Icon(_playMode),
                      itemBuilder: (BuildContext context) => [
                            PopupMenuItem(
                              value: 1,
                              child: ListTile(
                                selected: _playMode == Icons.sort,
                                leading: Icon(Icons.sort),
                                title: Text("In Order"),
                                onTap: () {
                                  if(_playMode != Icons.sort) {
                                    resetPlaylist();
                                    setState(() {
                                      _playModeValue = 1;
                                      _playMode = Icons.sort;
                                    });
                                  }
                                  },
                              )
                            ),
                            PopupMenuItem(
                              value: 2,
                              child: ListTile(
                                selected: _playMode == Icons.shuffle,
                                leading: Icon(Icons.shuffle),
                                title: Text("Shuffle"),
                                onTap: () {
                                  if(_playMode != Icons.shuffle){
                                    resetPlaylist();
                                    setState(() {
                                      _playModeValue = 2;
                                      _playMode = Icons.shuffle;
                                    });
                                  }
                                  },
                              )
                            ),
                            PopupMenuItem(
                              value: 3,
                                child: ListTile(
                                  selected: _playMode == Icons.repeat_one,
                                  leading: Icon(Icons.repeat_one),
                                  title: Text("Single Cycle"),
                                  onTap: () {
                                    if(_playMode != Icons.repeat_one){
                                      resetPlaylist();
                                      setState(() {
                                        _playModeValue = 3;
                                        _playMode = Icons.repeat_one;
                                      });
                                    }
                                    },
                                ))
                          ]),
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
                                  showValueIndicator: ShowValueIndicator.always,
                                  thumbShape: RoundSliderThumbShape(
                                      enabledThumbRadius: 8.0),
                                  overlayColor: Colors.purple.withAlpha(32),
                                  overlayShape: RoundSliderOverlayShape(
                                      overlayRadius: 8.0),
                                ),
                                child: Slider(
                                  min: 0.0,
                                  max: _current.duration.toDouble() + 2000,
                                  value:
                                      position?.inMilliseconds?.toDouble() ?? 0,
                                  onChanged: (double value) => audioPlayer.seek(
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
                          GestureDetector(
                            child: Icon(_icon),
                            onTap: () => playPause(_current),
                          ),
                          GestureDetector(
                            child: Icon(Icons.skip_next),
                            onTap: () => playNext(_playModeValue),
                          ),
                          GestureDetector(
                            child: Icon(Icons.list),
                            onTap: () => buildPlaylist(),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
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
                    onPressed:
                        !_deleteMode ? () => print("Search is tapped") : null,
                    splashColor: Colors.red,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.sort,
                    ),
                    onPressed:
                        !_deleteMode ? () => print("Sort is tapped") : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                    ),
                    onPressed: !_deleteMode ? () => loadSongs() : null,
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

  Widget buildDeleteList() {
    return ListView.builder(
        itemCount: _deleteCount,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            children: <Widget>[
              Text(_deleteList[index].title),
              Divider(
                height: 1.0,
                color: Colors.grey[500],
              )
            ],
          );
        });
  }
}
