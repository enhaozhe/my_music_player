import 'package:flute_music_player/flute_music_player.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DialogOptions {Save , Cancel}
bool flag = false;

class Dialogs {
  static Future<DialogOptions> saveCancelDialog(BuildContext context, Song song) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final ControllerTitle = TextEditingController(text: song.title);
    final ControllerArtist = TextEditingController(text: song.artist);
    final ControllerAlbum = TextEditingController(text: song.album);

    Widget titleText = new TextField(
      controller: ControllerTitle,
    );

    Widget artistText = new TextField(
      controller: ControllerArtist,
    );

    Widget albumText = new TextField(
      controller: ControllerAlbum,
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
                        children: <Widget>[
                          Text("Song Title"),
                          titleText,
                          Text("Artist"),
                          artistText,
                          Text("Album"),
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
                      prefs.setString("songTitle", ControllerTitle.text);
                      prefs.setString("songArtist", ControllerArtist.text);
                      prefs.setString("songAlbum", ControllerAlbum.text);
                      print(ControllerTitle.text);
                      print(ControllerArtist.text);
                      print(ControllerAlbum.text);
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