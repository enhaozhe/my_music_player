import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class PlaylistDatabase {
  static final _databaseName = "Playlist.db";
  static final _databaseVersion = 1;

  static final table = 'playlist_table';

  static final columnId = 'songID';
  static final columnTitle = 'title';
  static final columnArtist = 'artist';
  static final columnAlbum = 'album';
  static final columnAlbumid = 'albumId';
  static final columnDuration = 'duration';
  static final columnUrl = 'uri';
  static final columnAlbumArt = 'albumArt';
  static final columnIsAdded = "isAdded";  //true if the song is added to the queue by user

  // make this a singleton class
  PlaylistDatabase._privateConstructor();
  static final PlaylistDatabase instance = PlaylistDatabase._privateConstructor();

  // only have a single app-wide reference to the database
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            $columnId INTEGER,
            $columnArtist TEXT NOT NULL,
            $columnTitle TEXT NOT NULL,
            $columnAlbum TEXT NOT NULL,
            $columnAlbumid INTEGER,
            $columnDuration INTEGER NOT NULL,
            $columnUrl TEXT NOT NULL,
            $columnAlbumArt TEXT,
            $columnIsAdded INTEGER
          )
          ''');
    print("Created");
  }

// Helper methods

  // Inserts a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  // All of the methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a raw query to give the row count.
  Future<int> queryRowCount() async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    print("row id =");
    print(id);
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> updateRow(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.rawUpdate('''UPDATE $table SET $columnTitle = ?, $columnArtist = ?, $columnAlbum = ?, $columnIsAdded = ? WHERE $columnId = ?''',
        [row[columnTitle], row[columnArtist], row[columnAlbum], row[columnId], row[columnIsAdded]]);
  }
  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  deleteAll() async {
    final db = await database;
    var a = db.execute("DELETE * FROM $table");
    print("Deleted : " + a.toString());
  }
}
