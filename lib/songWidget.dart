import 'package:flutter/material.dart';

import 'song.dart';

final _rowHeight = 70.0;

class SongWidget extends StatelessWidget {
  final Song song;

  const SongWidget({
    this.song
  })
      : assert(song != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: new BoxDecoration(
        border: new Border.all(color: Colors.grey[200])
      ),
      height: _rowHeight,
      child: InkWell(
        splashColor: Colors.blue,
        onTap: () {
          print("I was tapped");
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(song.songName, style: TextStyle(fontSize: 20.0),  textAlign: TextAlign.left,),
                    Text(song.singer, style: TextStyle(fontSize: 14.0, color: Colors.grey), textAlign: TextAlign.start,)
                  ],
                ),
              ),
            Container(
              alignment: Alignment.center,
                child: Icon(Icons.more_horiz))
          ],
        ),
      ),
    );
  }
}
