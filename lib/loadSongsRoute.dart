import 'package:flutter/material.dart';
import 'package:flute_music_player/flute_music_player.dart';
import 'package:sqflite/sqflite.dart';

import 'databaseHelper.dart';

class LoadSongsRoute extends StatefulWidget {
  final List<Song> list;

  LoadSongsRoute(this.list);

  @override
  _LoadSongsRoute createState() => _LoadSongsRoute(list);
}

class _LoadSongsRoute extends State<LoadSongsRoute> {
  List<Song> list;
  bool _value;
  int numOfUnselected = 0;
  int selected;

  _LoadSongsRoute(this.list);

  List<bool> checkList;

  @override
  void initState() {
    super.initState();
    checkList = new List<bool>.filled(list.length, true);
    _value = numOfUnselected == 0;
    selected = list.length;
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
    print("inserted : ");
    print(id);
    // show the results: print all rows in the db
    print(await db.query(DatabaseHelper.table));
  }

  Widget buildBody() {
    return ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: list.length,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            children: <Widget>[
              ListTile(
                onTap: () {
                  setState(() {
                    (checkList[index]) ? numOfUnselected++ : numOfUnselected--;
                    (checkList[index]) ? selected-- : selected++;
                    _value = numOfUnselected == 0;
                    checkList[index] = !checkList[index];
                  });
                },
                leading: Checkbox(
                    value: checkList[index],
                    onChanged: (bool value) {
                      setState(() {
                        (checkList[index])
                            ? numOfUnselected++
                            : numOfUnselected--;
                        (checkList[index]) ? selected-- : numOfUnselected++;
                        checkList[index] = value;
                      });
                    }),
                title: Text(
                  list[index].title + " - " + list[index].artist,
                  maxLines: 1,
                ),
              ),
              Divider(
                height: 1.0,
                color: Colors.grey[500],
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Load Local Songs"),
        bottom: new PreferredSize(
            child: Row(
              children: <Widget>[
                Checkbox(
                    value: _value,
                    onChanged: (bool value) {
                      setState(() {
                        _value = value;
                        if (value) {
                          checkList = new List<bool>.filled(list.length, true);
                        } else {
                          checkList = new List<bool>.filled(list.length, false);
                        }
                      });
                    }),
                Text("Select All")
              ],
            ),
            preferredSize: Size.fromHeight(40.0)),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
              child: Column(
            children: <Widget>[
              Expanded(child: buildBody()),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: Text(selected.toString() + " selected", style: TextStyle(color: Colors.grey),)),
                    ),
                  ),
                ],
              ),
            ],
          )),
          RaisedButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            color: Colors.blue,
            child: Text("Add Songs"),
            onPressed: () {
              for (int i = 0; i < checkList.length; i++) {
                if (checkList[i]) {
                  _insert(list[i]);
                }
              }
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }
}
