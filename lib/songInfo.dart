import 'package:flutter/material.dart';
import 'package:flute_music_player/flute_music_player.dart';

class SongInfo{
  static void showSongInfo(BuildContext context, Song song){
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        title: Text("Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
                children: <Widget>[
                  Text("Title : ", style: TextStyle(fontWeight:FontWeight.bold),),
                  Flexible(child: Text(song.title))
                ],
              ),
            Divider(height: 2.0, color: Colors.grey,),
            Row(
              children: <Widget>[
                Text("Artist : ", style: TextStyle(fontWeight:FontWeight.bold),),
                Flexible(child: Text(song.artist))
              ],
            ),
            Divider(height: 2.0, color: Colors.grey,),
            Row(
              children: <Widget>[
                Text("Album : ", style: TextStyle(fontWeight:FontWeight.bold),),
                Flexible(child: Text(song.album),)
              ],
            ),
            Divider(height: 2.0, color: Colors.grey,),
            Row(
              children: <Widget>[
                Text("Location : ", style: TextStyle(fontWeight:FontWeight.bold), ),
                Flexible(child: Text(song.uri),)
              ],
            ),
            Divider(height: 2.0, color: Colors.grey,),
            Row(
              children: <Widget>[
                Text("Duration : " , style: TextStyle(fontWeight:FontWeight.bold), ),
                Flexible(child: Text((song.duration/60000).floor().toString() + ":" + (song.duration%60).toString()),)
              ],
            ),

          ],
        ),
        actions: <Widget>[
          RaisedButton(
            child: Text("OK", style: TextStyle(color: Colors.white),),
            onPressed: () => Navigator.pop(context),
          )
        ],
      );
    });
  }
}