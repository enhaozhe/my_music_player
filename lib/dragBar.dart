import 'package:flutter/material.dart';

class DraggableScrollbar extends StatefulWidget {
  final Widget child;

  DraggableScrollbar({this.child});

  @override
  _DraggableScrollbarState createState() => new _DraggableScrollbarState();
}

class _DraggableScrollbarState extends State<DraggableScrollbar> {
  //this counts offset for scroll thumb for Vertical axis
  double _barOffset;

  @override
  void initState() {
    super.initState();
    _barOffset = 0.0;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _barOffset += details.delta.dy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Stack(children: <Widget>[
      widget.child,
      GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          child: Container(
              alignment: Alignment.topRight,
              margin: EdgeInsets.only(top: _barOffset),
              child: _buildScrollThumb())),
    ]);
  }
  Widget _buildScrollThumb() {
    return new Container(
      height: 5.0,
      width: 10.0,
      color: Colors.blue,
    );
  }
}