import 'package:flutter/material.dart';

// ①　必要なライブラリをインポート
import 'package:shared_preferences/shared_preferences.dart';

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
  List<Widget> cards = [];

  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ② Widgetを初期化した際に呼ばれる`initState()`を上書き
  @override
  void initState() {
    super.initState();

    // ③ SharedPreferencesのインスタンスを取得し、
    // SharedPreferencesに保存されているリストを取得
    SharedPreferences.getInstance().then((prefs) {
      var todo = prefs.getStringList("todo") ?? [];
      for (var v in todo) {
        setState(() {
          // ④ 保存されている場合は、widgetのリストに追加
          widget.cards.add(TodoCardWidget(label: v));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My TODO"),
        actions: [
          // ⑦ナビゲーションバーの右上にゴミ箱ボタンを設置
          IconButton(
              onPressed: () {
                // ⑧ 押された場合は、保存されているTODOを全て削除
                SharedPreferences.getInstance().then((prefs) async {
                  await prefs.setStringList("todo", []);
                  setState(() {
                    widget.cards = [];
                  });
                });
              },
              icon: Icon(Icons.delete))
        ],
      ),
      body: Center(
        child: ListView.builder(
          itemCount: widget.cards.length,
          itemBuilder: (BuildContext context, int index) {
            return widget.cards[index];
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // ⑤ TextInputDialogを用いて、任意の文字列を取得する。
          var label = await _showTextInputDialog(context);

          if (label != null) {
            setState(() {
              widget.cards.add(TodoCardWidget(label: label));
            });

            // ⑥ SharedPreferencesのインスタンスを取得し、追加する。
            SharedPreferences prefs = await SharedPreferences.getInstance();
            var todo = prefs.getStringList("todo") ?? [];
            todo.add(label);
            await prefs.setStringList("todo", todo);
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
            title: const Text('TODO'),
            content: TextField(
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: "タスクの名称を入力してください。"),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text("キャンセル"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context, _textFieldController.text),
              ),
            ],
          );
        });
  }
}

////////////////////
class TodoCardWidget extends StatefulWidget {
  final String label;
  var state = false;

  TodoCardWidget({Key? key, required this.label}) : super(key: key);

  @override
  _TodoCardWidgetState createState() => _TodoCardWidgetState();
}

class _TodoCardWidgetState extends State<TodoCardWidget> {
  void _changeState(value) {
    setState(() {
      widget.state = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Container(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            Checkbox(onChanged: _changeState, value: widget.state),
            Text(widget.label),
          ],
        ),
      ),
    );
  }
}