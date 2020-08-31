import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vsongbook/models/BookModel.dart';
import 'package:vsongbook/models/SongModel.dart';
import 'package:vsongbook/helpers/SqliteHelper.dart';
import 'package:vsongbook/screens/EeSongView.dart';
//import 'package:vsongbook/utils/Preferences.dart';
import 'package:vsongbook/utils/constants.dart';
import 'package:vsongbook/widgets/AsProgressWidget.dart';
import 'package:vsongbook/widgets/AsTextView.dart';

class AsSearchSongs extends StatefulWidget {
  final int book;
  AsSearchSongs({this.book});

  @override
  createState() => AsSearchSongsState(book: this.book);

  static Widget getList(int songbook) {
    return new AsSearchSongs(
      book: songbook,
    );
  }
}

class AsSearchSongsState extends State<AsSearchSongs> {
  AsProgressWidget progressWidget =
      AsProgressWidget.getProgressWidget(AsProgressDialogTitles.Sis_Patience);
  TextEditingController txtSearch = new TextEditingController(text: "");
  AsTextView textResult = AsTextView.setUp(Texts.SearchResult, 18, false);
  SqliteHelper db = SqliteHelper();

  AsSearchSongsState({this.book});
  Future<Database> dbFuture;
  List<BookModel> books;
  List<SongModel> songs;
  int book;

  @override
  Widget build(BuildContext context) {
    if (songs == null) {
      books = [];
      songs = [];
      updateBookList();
      updateSongList();
    }

    return new Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: new AssetImage("assets/images/bg.jpg"),
              fit: BoxFit.cover)),
      child: new Stack(
        children: <Widget>[
          new Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: new Column(
              children: <Widget>[
                searchBox(),
                Container(
                  height: 55,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    itemCount: books.length,
                    itemBuilder: bookListView,
                  ),
                ),
                searchCount(),
              ],
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height - 200,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: progressWidget,
          ),
          Container(
            height: MediaQuery.of(context).size.height - 200,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            margin: EdgeInsets.only(top: 150),
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: songs.length,
              itemBuilder: songListView,
            ),
          ),
        ],
      ),
    );
  }

  Widget searchBox() {
    return new Card(
      elevation: 2,
      child: new TextField(
        controller: txtSearch,
        style: TextStyle(
          fontSize: 18,
        ),
        decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: Texts.SearchNow,
            hintStyle: TextStyle(fontSize: 18)),
        onChanged: (value) {
          searchSong();
        },
      ),
    );
  }

  Widget bookListView(BuildContext context, int index) {
    return Container(
      width: 160,
      child: GestureDetector(
        onTap: () {
          setCurrentBook(books[index].categoryid);
        },
        child: Card(
          elevation: 5,
          child: Hero(
            tag: books[index].bookid,
            child: Container(
              padding: const EdgeInsets.all(3),
              child: Center(
                child: Text(
                  books[index].title +
                      ' (' +
                      books[index].qcount.toString() +
                      ')',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget searchCount() {
    return new Card(
      elevation: 5,
      child: Hero(
        tag: 0,
        child: Container(
          padding: const EdgeInsets.all(7),
          child: Center(
            child: textResult,
          ),
        ),
      ),
    );
  }

  Widget songListView(BuildContext context, int index) {
    int category = songs[index].bookid;
    String songbook = "";
    String songTitle = songs[index].title;

    var verses = songs[index].content.split("\\n\\n");
    var songConts = songs[index].content.split("\\n");
    String songContent = songConts[0] + ' ' + songConts[1] + " ...";

    try {
      BookModel curbook = books.firstWhere((i) => i.categoryid == category);
      songContent = songContent + "\n" + curbook.title + "; ";
      songbook = curbook.title;
    } catch (Exception) {
      songContent = songContent + "\n";
    }

    if (songs[index].content.contains("CHORUS")) {
      songContent = songContent + Texts.HasChorus;
      songContent = songContent + verses.length.toString() + Texts.Verses;
    } else {
      songContent = songContent + Texts.NoChorus;
      songContent = songContent + verses.length.toString() + Texts.Verses;
    }

    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(songTitle,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text(songContent, style: TextStyle(fontSize: 18)),
        onTap: () {
          navigateToSong(songs[index], songTitle,
              "Song #" + songs[index].number.toString() + " - " + songbook);
        },
      ),
    );
  }

  void updateBookList() {
    dbFuture = db.initializeDatabase();
    dbFuture.then((database) {
      Future<List<BookModel>> bookListFuture = db.getBookList();
      bookListFuture.then((bookList) {
        setState(() {
          books = bookList;
        });
      });
    });
  }

  void updateSongList() {
    dbFuture = db.initializeDatabase();
    dbFuture.then((database) {
      Future<List<SongModel>> songListFuture = db.getSongList(book);
      songListFuture.then((songList) {
        setState(() {
          songs = songList;
          progressWidget.hideProgress();
        });
      });
    });
  }

  void searchSong() {
    String searchThis = txtSearch.text;
    if (searchThis.length > 0) {
      songs.clear();
      dbFuture = db.initializeDatabase();
      dbFuture.then((database) {
        Future<List<SongModel>> songListFuture =
            db.getSongSearch(txtSearch.text);
        songListFuture.then((songList) {
          setState(() {
            songs = songList;
            textResult.setText(songs.length.toString() + " songs found");
          });
        });
      });
    } else {
      updateSongList();
      textResult.setText(Texts.SearchResult);
    }
  }

  void setCurrentBook(int _book) {
    book = _book;
    songs.clear();
    updateSongList();
  }

  void navigateToSong(SongModel song, String title, String songbook) async {
    bool haschorus = false;
    if (song.content.contains("CHORUS")) haschorus = true;
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return EeSongView(song, haschorus, title, songbook);
    }));
  }
}

class BookItem<T> {
  bool isSelected = false;
  T data;
  BookItem(this.data);
}