import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  List<ThemeMode> themes = [ThemeMode.light, ThemeMode.dark];
  int actTheme = 0;
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048 Game',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color.fromARGB(255, 133, 138, 227),
          onPrimary: Color.fromARGB(255, 95, 102, 248),
          secondary: Color.fromARGB(255, 244, 250, 255),
          onSecondary: Colors.black,
          tertiary: Colors.white,
          background: Color.fromARGB(255, 252, 252, 252),
          error: Color.fromARGB(255, 238, 51, 38),
          shadow: Color.fromARGB(255, 167, 167, 167),
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 126, 82, 160),
          onPrimary: Color.fromARGB(255, 126, 82, 160),
          secondary: Color.fromARGB(255, 102, 148, 190),
          onSecondary: Colors.white,
          tertiary: Colors.black,
          background: Color.fromARGB(255, 19, 19, 19),
          error: Color.fromARGB(255, 234, 31, 17),
          shadow: Color.fromARGB(255, 0, 0, 0),
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      themeMode: _themeMode,
      home: const Game2048(),
    );
  }

  void switchTheme() {
    setState(
      () {
        actTheme = actTheme ^ 1;
        _themeMode = themes[actTheme];
      },
    );
  }
}

class Game2048 extends StatefulWidget {
  const Game2048({super.key});

  @override
  State<Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  int prevScore = 0, score = 0, bestScore = 0;
  List<List<int>> prevTiles =
      List.generate(4, (i) => List.generate(4, (j) => 0));
  List<List<int>> tiles = List.generate(4, (i) => List.generate(4, (j) => 0));

  late SharedPreferences prefs;

  List<List<int>> transposeMatrix(List<List<int>> matrix) {
    List<List<int>> result = List.generate(
      matrix[0].length,
      (index) => List<int>.empty(growable: true),
    );

    for (int i = matrix.length - 1; i >= 0; i--) {
      for (int j = matrix[i].length - 1; j >= 0; j--) {
        result[j].add(matrix[i][j]);
      }
    }

    return result;
  }

  void restartGame() {
    setState(() {
      prevScore = 0;
      score = 0;
      prevTiles = List.generate(4, (i) => List.generate(4, (j) => 0));
      tiles = List.generate(4, (i) => List.generate(4, (j) => 0));
      generateNewTile();
    });
  }

  void undoMove() {
    setState(() {
      tiles = prevTiles;
      score = prevScore;
    });
  }

  void move(int direction) {
    prevScore = score;
    List<List<int>> newTiles = tiles;

    for (int i = 0; i < direction; i++) {
      newTiles = transposeMatrix(newTiles);
    }

    for (int i = 3; i > 0; i--) {
      for (int j = 0; j < 4; j++) {
        int I = i;
        while (i < 4 && newTiles[i - 1][j] != 0 && newTiles[i][j] == 0) {
          newTiles[i][j] = newTiles[i - 1][j];
          newTiles[i - 1][j] = 0;
          i++;
        }
        if (i == 4) i--;

        if (newTiles[i][j] == newTiles[i - 1][j]) {
          newTiles[i][j] += newTiles[i - 1][j];
          newTiles[i - 1][j] = 0;
          score += newTiles[i][j];
        }
        i = I;
      }
    }

    for (int i = direction; i < 4; i++) {
      newTiles = transposeMatrix(newTiles);
    }

    setState(() {
      prevTiles = tiles;
      tiles = newTiles;
      bestScore = max(bestScore, score);

      prefs.setInt("bestScore", bestScore);
      generateNewTile();
    });
  }

  void generateNewTile() {
    List<int> emptyTiles = [];
    for (int i = 0; i < 16; i++) {
      if (tiles[i ~/ 4][i % 4] == 0) {
        emptyTiles.add(i);
      }
    }

    if (emptyTiles.isNotEmpty) {
      int index = emptyTiles[Random().nextInt(emptyTiles.length)];
      tiles[index ~/ 4][index % 4] = Random().nextInt(2) == 0 ? 2 : 4;
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          Size size = MediaQuery.of(context).size;

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Container(
                width: size.width / 2,
                height: size.height / 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height / 25),
                    Text(
                      "You lose!\nYou lose again!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size.width / 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        restartGame();
                      },
                      child: Container(
                        width: size.width / 10,
                        height: size.width / 10,
                        decoration: BoxDecoration(
                          color: boardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.restart_alt,
                            color: textColorWhite,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height / 25),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    initMemory();

    generateNewTile();
  }

  Future<void> initMemory() async {
    prefs = await SharedPreferences.getInstance();

    setState(() {
      bestScore = prefs.getInt("bestScore") ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final boardSize = size.width * 0.85;
    final sizePerTile = (boardSize / 4).floorToDouble();
    final tileSize = sizePerTile - 12.0 - (12.0 / 4);

    return Scaffold(
      body: Center(
        child: Container(
          margin: EdgeInsets.only(
            left: size.width * 0.075,
            right: size.width * 0.075,
            top: size.height / 10,
            bottom: size.height / 10,
          ),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  Text(
                    "2048",
                    style: TextStyle(
                      fontSize: size.width / 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: size.width / 5.5,
                            height: size.height / 15,
                            decoration: BoxDecoration(
                              color: boardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "SCORE\n$score",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: textColorWhite,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: size.width / 50),
                          Container(
                            width: size.width / 6.5,
                            height: size.height / 15,
                            decoration: BoxDecoration(
                              color: boardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "BEST\n$bestScore",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: textColorWhite,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: size.height / 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () {
                              undoMove();
                            },
                            child: Container(
                              width: size.width / 10,
                              height: size.width / 10,
                              decoration: BoxDecoration(
                                color: boardColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.undo,
                                  color: textColorWhite,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: size.width / 25),
                          InkWell(
                            onTap: () {
                              restartGame();
                            },
                            child: Container(
                              width: size.width / 10,
                              height: size.width / 10,
                              decoration: BoxDecoration(
                                color: boardColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.restart_alt,
                                  color: textColorWhite,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: size.height / 15),
              GestureDetector(
                onPanEnd: (details) {
                  double dx = details.velocity.pixelsPerSecond.dx;
                  double dy = details.velocity.pixelsPerSecond.dy;

                  if (dx.abs() < dy.abs()) {
                    if (dy > 0) {
                      move(0);
                    } else if (dy < 0) {
                      move(2);
                    }
                  } else {
                    if (dx > 0) {
                      move(1);
                    } else if (dx < 0) {
                      move(3);
                    }
                  }
                },
                child: Container(
                  height: boardSize,
                  width: boardSize,
                  decoration: BoxDecoration(
                    color: boardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: List.generate(16, (i) {
                      var x = ((i + 1) / 4).ceil();
                      var y = x - 1;

                      var top = y * (tileSize) + (x * 12.0);
                      var z = (i - (4 * y));
                      var left = z * (tileSize) + ((z + 1) * 12.0);

                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        top: top,
                        left: left,
                        child: Container(
                          width: tileSize,
                          height: tileSize,
                          decoration: BoxDecoration(
                            color: tileColors[tiles[i ~/ 4][i % 4]],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              tiles[i ~/ 4][i % 4] == 0
                                  ? ""
                                  : "${tiles[i ~/ 4][i % 4]}",
                              style: TextStyle(
                                fontSize: size.width / 20,
                                fontWeight: FontWeight.w700,
                                color: textColorWhite,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
