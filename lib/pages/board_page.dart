import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  static const int gridSize = 100;
  static const int numberOfPieces = 15;
  static const int numberOfBombs = 20;
  late Set<int> piecePosition;
  late Set<int> bombPosition;
  int bombCounter = 0;
  Timer? gameTimer;
  final random = Random();

  @override
  void initState() {
    super.initState();
    _generateBoard();
    _startTimer();
  }

  void _generateBoard() {
    piecePosition = {};
    bombPosition = {};
    bombCounter = 0;

    while (bombPosition.length < numberOfBombs) {
      int pos = random.nextInt(gridSize);
      bombPosition.add(pos);
    }

    while (piecePosition.length < numberOfPieces) {
      int pos = random.nextInt(gridSize);
      if (!bombPosition.contains(pos) && !piecePosition.contains(pos)) {
        piecePosition.add(pos);
      }
    }
    gameTimer?.cancel();
    _startTimer();

    setState(() {});
  }

  void _startTimer() {
    gameTimer = Timer.periodic(Duration(seconds: 10), (_) {
      if (bombPosition.isNotEmpty) {
        final bombList = bombPosition.toList();
        final explode = bombList[random.nextInt(bombList.length)];
        bombPosition.remove(explode);
        setState(() {});
      }

      if (bombPosition.isEmpty) {
        gameTimer?.cancel();
        _gameOverDialog();
      }
    });
  }

  void _gameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Game Over"),
        content: Text(
          "All bombs are exploded..\n Bombs discovered: ${bombCounter}",
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generateBoard();
            },
            child: Text("Play Again", style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reversed Minesweeper"), centerTitle: true),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(8.0),
          color: Colors.grey[300],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _generateBoard();
                      });
                    },
                    icon: Icon(Icons.refresh, size: 32),
                  ),
                ),
              ),
              Flexible(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: gridSize,
                  itemBuilder: (context, index) {
                    bool hasPiece = piecePosition.contains(index);
                    bool hasBomb = bombPosition.contains(index);
                    return DragTarget<int>(
                      onAccept: (fromIndex) {
                        setState(() {
                          piecePosition.remove(fromIndex);
                          if (hasBomb) {
                            bombPosition.remove(index);
                            bombCounter++;
                          }
                          piecePosition.add(index);
                        });
                      },
                      onWillAccept: (fromIndex) =>
                          // bool occupied =
                          //     piecePosition.contains(index) ||
                          //     bombPosition.contains(index);
                          // return !occupied;
                          !piecePosition.contains(index),
                      builder: (context, _, _) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black),
                          ),
                          child: Center(
                            child: hasPiece
                                ? Draggable<int>(
                                    data: index,
                                    childWhenDragging: SizedBox.shrink(),
                                    feedback: Icon(
                                      Icons.circle,
                                      color: Colors.blueGrey,
                                      size: 18,
                                    ),
                                    child: Icon(
                                      Icons.circle,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                  )
                                : Text(
                                    "${index + 1}",
                                    style: TextStyle(fontSize: 12),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 220.0),
                child: Row(
                  children: [
                    SizedBox(width: 8),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        "Bombs Found: $bombCounter",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    SizedBox(width: 94),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        "Bombs Remaining: ${bombPosition.length}",
                        style: TextStyle(fontSize: 20, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
