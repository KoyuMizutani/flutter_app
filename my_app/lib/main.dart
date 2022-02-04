import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
int _count = 0;

///////////////////////////////
void main() => runApp(MyApp());

///////////////////////////////
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData(), home: MyHomePage());
  }
}

///////////////////////////////
class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs){
      var todo = prefs.getStringList("todo") ?? [];
      setState(() {
        _count = todo.length;
      });
    });
  }

  /// ---- ① 非同期にカードリストを生成する関数 ----
  Future<List<dynamic>> getCards() async {
    var prefs = await SharedPreferences.getInstance();
    List<Widget> cards = [];
    var todo = prefs.getStringList("todo") ?? [];
    for (var jsonStr in todo) {
      // JSON形式の文字列から辞書形式のオブジェクトに変換し、各要素を取り出し
      var mapObj = jsonDecode(jsonStr);
      var title = mapObj['title'];
      var state = mapObj['state'];
      cards.add(TodoCardWidget(label: title, state: state));
    }
    return cards;
  }
  
  /// ------------------------------------
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My ToDo",
          style: TextStyle(
            fontSize: 25,
          ),
        ),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
              onPressed: () {
                _count = 0;
                SharedPreferences.getInstance().then((prefs) async {
                  await prefs.setStringList("todo", []);
                  setState(() {});
                });
              },
              icon: const Icon(Icons.delete))
        ],
      ),
      body: Center(
        /// ---- ② 非同期にカードリストを更新するには、FutureBuilder を使います----
        child: FutureBuilder<List>(
          future: getCards(), // <--- getCards()メソッドの実行状態をモニタリングする
          builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return const Text('Waiting to start');
              case ConnectionState.waiting:
                return const Text('Loading...');
              default:
                // getCards()メソッドの処理が完了すると、ここが呼ばれる。
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return ListView.builder(
                      // リストの中身は、snapshot.dataの中に保存されているので、
                      // 取り出して活用する
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return snapshot.data![index];
                      });
                }
            }
          },
        ),

        /// ------------------------------------
      ),
      backgroundColor: Colors.blueGrey.shade100,
      bottomNavigationBar: BottomAppBar(
        color: Colors.orange,
        shape: const CircularNotchedRectangle(),
        child: Container(
          child: Text(
            "$_count tasks",
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
            ),
          ),
          height: 35.0,
          alignment: Alignment.center,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange[800],
        onPressed: () async {
          var label = await _showTextInputDialog(context);

          if (label != null) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            var todo = prefs.getStringList("todo") ?? [];

            // 辞書型オブジェクトを生成し、JSON形式の文字列に変換して保存
            var mapObj = {"title": label, "state": false};
            var jsonStr = jsonEncode(mapObj);
            todo.add(jsonStr);
            await prefs.setStringList("todo", todo);
            _count = todo.length;
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  final _textFieldController = TextEditingController();

  Future<String?> _showTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('ToDo'),
            content: TextField(
              cursorColor: Colors.orange,
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                hintText: "タスクの名称を入力してください。",
              ),
              controller: _textFieldController,
            ),
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                ),
                child: const Text("キャンセル"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                ),
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context, _textFieldController.text);
                  // _count++;
                },
              ),
            ],
          );
        });
  }
}

////////////////////
class TodoCardWidget extends StatefulWidget {
  final String label;
  // 真偽値（Boolen）型のstateを外部からアクセスできるように修正
  var state = false;

  TodoCardWidget({
    Key? key,
    required this.label,
    required this.state,
  }) : super(key: key);

  @override
  _TodoCardWidgetState createState() => _TodoCardWidgetState();
}

class _TodoCardWidgetState extends State<TodoCardWidget> {
  void _changeState(value) async {
    setState(() {
      widget.state = value ?? false;
    });

    // --- ③ ボタンが押されたタイミング状態を更新し保存する ---
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var todo = prefs.getStringList("todo") ?? [];

    for (int i = 0; i < todo.length; i++) {
      var mapObj = jsonDecode(todo[i]);
      if (mapObj["title"] == widget.label) {
        mapObj["state"] = widget.state;
        todo[i] = jsonEncode(mapObj);
      }
    }

    prefs.setStringList("todo", todo);

    /// ------------------------------------
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Container(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            Checkbox(
              onChanged: _changeState, 
              value: widget.state,
              checkColor: Colors.white,
              activeColor: Colors.orange,
            ),
            Text(widget.label),
          ],
        ),
      ),
    );
  }
}