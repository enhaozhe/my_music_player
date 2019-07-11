import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'storage.dart';
import 'song.dart';
import 'songWidget.dart';


Song currentSong = new Song(songName: "It Will Rain", singer: "Bruno Mars");
double _value = 0;

class SongList extends StatefulWidget {
  const SongList();

  @override
  _SongListState createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  final _songs = <SongWidget>[];
  Song _current = currentSong;

  //Singer -> list of songs
  Map<String, List<Song>> songList = new Map();

  static const _songNames = <String>["It Will Rain", "Talking to the Moon"];

  static const _singers = <String>[
    "Bruno Mars",
    "Bruno Mars",
  ];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _songNames.length; i++) {
      _songs.add(SongWidget(
        song: new Song(songName: _songNames[i], singer: _singers[i]),
      ));
    }
  }

  Widget _buildSongList() {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        return new ListTile(
          onTap: () => print(_songs[index].song.songName + " is tapped"),
          leading: GestureDetector(
            child: Row(
              children: <Widget>[
                new CircleAvatar(
                  child: Text(_songs[index].song.songName.substring(0,1)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0 ,0 ,0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(_songs[index].song.songName, style: TextStyle(fontSize: 18.0, ),),
                      Text(_songs[index].song.singer, style: TextStyle(color: Colors.grey),),
                    ],
                  ),
                )
              ],
            ),
          ),

        );
      },

      itemCount: _songs.length,
    );
  }

  selectedSong(int index) {
    setState(() {
      _current = _songs[index].song;
    });
  }

  onChanged(double value) {
    setState(() {
      _value = value;
      print(_value);
    });
  }

  //Todo: Make selected song bigger
  @override
  Widget build(BuildContext context) {
    final listView = Container(
        child: new Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        _buildSongList(),
        Container(
          height: 50.0,
          color: Colors.blue[100],
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.ac_unit,
                  size: 40.0,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
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
                            value: _value,
                            onChanged: onChanged),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                            child: Text(currentSong.singer +
                                "  -  " +
                                currentSong.songName)),
                        Icon(Icons.play_circle_outline),
                        Icon(Icons.skip_next),
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
                    onPressed: () => print("Refresh is tapped"),
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
}

/*
_read() async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'my_int_key';
  final value = prefs.getInt(key) ?? 0;
  print('read: $value');
}

_save() async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'my_int_key';
  final value = 42;
  prefs.setInt(key, value);
  print('saved $value');
}*/
