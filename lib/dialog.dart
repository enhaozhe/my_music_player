import 'package:flute_music_player/flute_music_player.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DialogOptions {Save , Cancel}
bool flag = false;

class Dialogs {
  static Future<DialogOptions> saveCancelDialog(BuildContext context, Song song) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final controllerTitle = TextEditingController(text: song.title);
    final controllerArtist = TextEditingController(text: song.artist);
    final controllerAlbum = TextEditingController(text: song.album);

    Widget titleText = new TextField(
      controller: controllerTitle,
    );

    Widget artistText = new TextField(
      controller: controllerArtist,
    );

    Widget albumText = new TextField(
      controller: controllerAlbum,
    );
    final action = await showDialog(
            context: context,
            builder: (BuildContext context){
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                title: Text("Edit Song Info"),
                content: Container(
                  height: 220.0,
                  child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Song Title", style: TextStyle(fontWeight: FontWeight.bold),),
                          titleText,
                          Text("Artist", style: TextStyle(fontWeight: FontWeight.bold)),
                          artistText,
                          Text("Album", style: TextStyle(fontWeight: FontWeight.bold)),
                          albumText
                        ],
                      ),
                ),
                actions: <Widget>[
                  FlatButton(
                    child: Text("Cancel"),
                    onPressed: () {
                      flag = false;
                      Navigator.of(context).pop(DialogOptions.Cancel);
                      print("cancel is pressed");
                    },
                  ),
                  RaisedButton(
                    child: Text("Save", style: TextStyle(color: Colors.black),),
                    onPressed: () {
                      flag = true;
                      prefs.setString("songTitle", controllerTitle.text);
                      prefs.setString("songArtist", controllerArtist.text);
                      prefs.setString("songAlbum", controllerAlbum.text);
                      prefs.setInt("songID", song.id);
                      print(controllerTitle.text);
                      print(controllerArtist.text);
                      print(controllerAlbum.text);
                      Navigator.of(context).pop(DialogOptions.Save);
                      print("Save is pressed");
                      },
                  )
                ],
              );
        },
        );
        return (action != null) ? action : DialogOptions.Cancel;
  }
}