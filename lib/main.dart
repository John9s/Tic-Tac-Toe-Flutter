import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tik_tac_toe_game/boxes.dart';
import 'package:flutter_tik_tac_toe_game/utils.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();

  await Hive.openBox<List<dynamic>>('matrixstate');
  await Hive.openBox<String>('values');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static final String title = 'Tic Tac Toe';

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: title,
        theme: ThemeData(
          primaryColor: Colors.blue,
        ),
        home: MainPage(title: title),
      );
}

class MainPage extends StatefulWidget {
  final String title;

  const MainPage({
    required this.title,
  });

  @override
  _MainPageState createState() => _MainPageState();
}

class Player {
  static const none = '';
  static const X = 'X';
  static const O = 'O';
}

class _MainPageState extends State<MainPage> {
  static final countMatrix = 3;
  static final double size = 92;
  static Timer? timer;
  static final minController = TextEditingController();
  static final secController = TextEditingController();

  Duration duration = Duration();

  String lastMove = Boxes.getValues().isNotEmpty
      ? Boxes.getValues().get('player')!
      : Player.none;

  // late List<List<String>> matrix;
  late dynamic matrix;

  @override
  void initState() {
    super.initState();

    log("Last move: $lastMove");

    Boxes.getMatrix().isNotEmpty ? setSavedFields() : setEmptyFields();
    //setEmptyFields();
  }

  void setEmptyFields() => setState(() => matrix = List.generate(
        countMatrix,
        (_) => List.generate(countMatrix, (_) => Player.none),
      ));

  void setSavedFields() =>
      setState(() => matrix = Boxes.getMatrix().get("myMatrix"));

  Color getBackgroundColor() {
    final thisMove = lastMove == Player.X ? Player.O : Player.X;

    return getFieldColor(thisMove).withAlpha(150);
  }

  @override
  Widget build(BuildContext context) {
    final minField = Container(
        width: 50.0,
        color: Colors.white,
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: TextFormField(
            controller: minController,
            decoration: InputDecoration.collapsed(hintText: ""),
            keyboardType: TextInputType.number,
          ),
        ));

    final secField = Container(
        width: 50.0,
        color: Colors.white,
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: TextFormField(
            controller: secController,
            decoration: InputDecoration.collapsed(hintText: ""),
            keyboardType: TextInputType.number,
          ),
        ));

    return Scaffold(
      backgroundColor: getBackgroundColor(),
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
                icon: const Icon(CupertinoIcons.restart, color: Colors.white),
                onPressed: () => showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title:
                            Text("ARE YOU SURE?", textAlign: TextAlign.center),
                        content: Text('Do you want to restart the game?',
                            textAlign: TextAlign.center),
                        actions: [
                          ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.resolveWith(
                                          (states) => Colors.redAccent)),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('No')),
                          ElevatedButton(
                            onPressed: () {
                              restart();
                              Navigator.of(context).pop();
                            },
                            child: Text('Yes'),
                          )
                        ],
                        actionsAlignment: MainAxisAlignment.spaceBetween,
                      ),
                    )),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.05),
          child: Column(children: [

            buildTime(),
            SizedBox(
              height: 30.0,
            ),

            Column(
              children: Utils.modelBuilder(matrix, (x, value) => buildRow(x)),
            ),
            SizedBox(
              height: 30.0,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: minField,
                        ),
                        Text("min")
                      ],
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: secField,
                        ),
                        Text("sec")
                      ],
                    ),
                  ],
                ),


              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith(
                              (states) => Colors.redAccent)),
                  onPressed: () {
                    timer != null ? timer!.cancel() : (){};
                  },
                  child: Text("Stop"),
                ),

                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith(
                              (states) => Colors.green)),
                  onPressed: () {
                    final min = minController.text !=  "" ? int.parse(minController.text) : 0;
                    final sec = secController.text !=  "" ?  int.parse(secController.text) : 0;
                    log("$min : $sec");

                    FocusManager.instance.primaryFocus?.unfocus();
                    minController.clear();
                    secController.clear();

                    if(min > 0 || sec > 0) {
                      timer != null ? timer!.cancel() : (){};
                      startTimer(min: min, sec: sec);
                    }
                  },
                  child: const Text("Start"),
                ),

              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget buildRow(int x) {
    final values = matrix[x];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: Utils.modelBuilder(
        values,
        (y, value) => buildField(x, y),
      ),
    );
  }

  Color getFieldColor(String value) {
    switch (value) {
      case Player.O:
        return Colors.blue;
      case Player.X:
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  Widget buildField(int x, int y) {
    final value = matrix[x][y];
    final color = getFieldColor(value);

    return Container(
      margin: EdgeInsets.all(4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(size, size),
          primary: color,
        ),
        child: Text(value, style: TextStyle(fontSize: 32)),
        onPressed: () => selectField(value, x, y),
      ),
    );
  }

  void selectField(String value, int x, int y) {
    if (value == Player.none) {
      final newValue = lastMove == Player.X ? Player.O : Player.X;

      final box = Boxes.getMatrix();
      final values = Boxes.getValues();
      setState(() {
        lastMove = newValue;
        matrix[x][y] = newValue;

        box.put("myMatrix", matrix);
        values.put("player", lastMove);
        //box.add(matrix);
      });

      if (isWinner(x, y)) {
        showEndDialog('Player $newValue Won');
      } else if (isEnd()) {
        showEndDialog('Undecided Game');
      }
    }
  }

  bool isEnd() => matrix.every(
      (values) => values.every((value) => value != Player.none) ? true : false);

  /// Check out logic here: https://stackoverflow.com/a/1058804
  bool isWinner(int x, int y) {
    var col = 0, row = 0, diag = 0, rdiag = 0;
    final player = matrix[x][y];
    final n = countMatrix;

    for (int i = 0; i < n; i++) {
      if (matrix[x][i] == player) col++;
      if (matrix[i][y] == player) row++;
      if (matrix[i][i] == player) diag++;
      if (matrix[i][n - i - 1] == player) rdiag++;
    }

    return row == n || col == n || diag == n || rdiag == n;
  }

  Future showEndDialog(String title) => showDialog(
        context: context,
       barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(title, textAlign: TextAlign.center),
          content: Text('Press to Restart the Game', textAlign: TextAlign.center),
          actions: [
            ElevatedButton(
              onPressed: () {
                restart();
                Navigator.of(context).pop();
              },
              child: Text('Restart'),
            )
          ],
        ),
      );

  void restart() {
    setEmptyFields();
    Boxes.getMatrix().delete("myMatrix");
    Boxes.getValues().delete("player");
  }

  Widget buildTime() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    timerCard(String time) => Card(
      color: Colors.black.withOpacity(0.3),
          child: SizedBox(
            height: 50,
            width: 50,
            child: Center(
              child: Text(time, style: const TextStyle(color: Colors.white),),
            ),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        timerCard("$minutes"),
        timerCard("$seconds"),
      ],
    );
  }

  void startTimer({int min = 0, int sec = 0}) {
    duration = Duration(minutes: min, seconds: sec);

   timer = Timer.periodic(Duration(seconds: 1), (timer) {
      countDown();
    });
  }

  void countDown() {
    final subtractSeconds = 1;


    setState(() {
      final seconds = duration.inSeconds - subtractSeconds;

      log("Sec: $seconds");
      if (seconds < 0) {
        timer != null ? timer!.cancel() : (){};
        showTimeUp("Time Up!");
      } else {
        duration = Duration(seconds: seconds);
      }
    });
  }

  Future showTimeUp(String title) => showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
  title: Text(title, textAlign: TextAlign.center),
  content: Text('Press to Restart the Game', textAlign: TextAlign.center),
  actions: [
  ElevatedButton(
  onPressed: () {
  restart();
  Navigator.of(context).pop();
  },
  child: Text('Restart'),
  )
  ],
  ));
}
