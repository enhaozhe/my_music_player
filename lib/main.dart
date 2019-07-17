import 'package:flutter/material.dart';

import 'song_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //debugShowCheckedModeBanner: false,
      title: 'My Music Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SongList(),
    );
  }
}