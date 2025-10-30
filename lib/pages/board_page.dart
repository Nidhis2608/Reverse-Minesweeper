import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  static const int gridSize = 100;
  static const int numberOfPieces = 20;
  static const int numberOfBombs = 15;
  late Set<int> piecePosition;
  late Set<int> bombPosition;
  int bombCounter = 0;
  Timer? gameTimer;
  final random = Random();
  Map<int, bool> explodingCells = {};

  @override
  void initState() {
    super.initState();
    _generateBoard();
  }

  void _generateBoard() {
    piecePosition = {};
    bombPosition = {};
    explodingCells.clear();
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
    gameTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (bombPosition.isNotEmpty) {
        final bombList = bombPosition.toList();
        final explode = bombList[random.nextInt(bombList.length)];

        setState(() {
          explodingCells[explode] = true;
        });

        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 300, amplitude: 255);
        }

        Future.delayed(const Duration(milliseconds: 800), () {
          setState(() {
            explodingCells.remove(explode);
            bombPosition.remove(explode);
          });
          _checkGameOver();
        });
      }
    });
  }

  void _checkGameOver() {
    if (bombPosition.isEmpty) {
      gameTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 1200), _gameOverDialog);
    }
  }

  void _gameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "🎮 Game Over",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "All bombs have exploded!",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "💣 Bombs discovered: $bombCounter",
              style: const TextStyle(fontSize: 16, color: Colors.redAccent),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              "Cancel",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateBoard();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text("Play Again", style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _showHowToPlayDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "🕹️ How to Play",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🎯 Objective:", style: TextStyle(fontWeight: FontWeight.bold,)),
            Text("Discover hidden bombs by dragging blue circles onto numbered tiles."),
            SizedBox(height: 12),
            Text("💣 Rules:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("• Dropping a piece on a bomb will make it explode!"),
            Text("• Every 10 seconds, a random bomb explodes automatically."),
            Text("• The game ends when all bombs are gone."),
            SizedBox(height: 12),
            Text("🏁 Goal:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Find as many bombs as possible before they explode!"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Got it!",
              style: TextStyle(fontSize: 18, color: Colors.blue),
            ),
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
      appBar: AppBar(
        title: const Text("Reversed Minesweeper"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: "How to Play",
            onPressed: _showHowToPlayDialog,
          ),
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.grey[300],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: _generateBoard,
                    icon: const Icon(Icons.refresh, size: 32),
                  ),
                ),
              ),
              Flexible(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: gridSize,
                  itemBuilder: (context, index) {
                    bool hasPiece = piecePosition.contains(index);
                    bool hasBomb = bombPosition.contains(index);
                    bool isExploding = explodingCells[index] == true;

                    return DragTarget<int>(
                      onAccept: (fromIndex) {
                        setState(() {
                          piecePosition.remove(fromIndex);
                          if (hasBomb) {
                            bombPosition.remove(index);
                            bombCounter++;
                            explodingCells[index] = true;
                            Vibration.vibrate(duration: 300, amplitude: 200);

                            Future.delayed(const Duration(milliseconds: 800), () {
                              setState(() {
                                explodingCells.remove(index);
                              });
                              _checkGameOver();
                            });
                          }
                          piecePosition.add(index);
                        });
                      },
                      onWillAccept: (fromIndex) => !piecePosition.contains(index),
                      builder: (context, _, __) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: isExploding
                                ? Colors.redAccent.withOpacity(0.8)
                                : Colors.white,
                            border: Border.all(color: Colors.black),
                          ),
                          child: Center(
                            child: hasPiece
                                ? Draggable<int>(
                              data: index,
                              childWhenDragging: const SizedBox.shrink(),
                              feedback: const Icon(
                                Icons.circle,
                                color: Colors.blueGrey,
                                size: 18,
                              ),
                              child: const Icon(
                                Icons.circle,
                                color: Colors.blue,
                                size: 18,
                              ),
                            )
                                : Text(
                              "${index + 1}",
                              style: const TextStyle(fontSize: 12),
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
                    const SizedBox(width: 8),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        "Bombs Found: $bombCounter",
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 94),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        "Bombs Remaining: ${bombPosition.length}",
                        style: const TextStyle(fontSize: 20, color: Colors.red),
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
