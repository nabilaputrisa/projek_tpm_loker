import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MemoryMatchGame());
}

class MemoryMatchGame extends StatelessWidget {
  const MemoryMatchGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Kartu Daya Ingat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFE3F2FD),
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CardItem {
  final String emoji;
  final String profession;
  final int id;
  bool isFlipped;
  bool isMatched;

  CardItem({
    required this.emoji,
    required this.profession,
    required this.id,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<CardItem> cards = [];
  List<int> selectedCards = [];
  int lives = 3;
  bool isChecking = false;
  bool showingPreview = false;
  bool gameStarted = false;
  int matchedPairs = 0;
  int previewTimeLeft = 10;
  Timer? previewTimer;
  Timer? countdownTimer;

  final List<Map<String, String>> professions = [
    {'emoji': '👨‍⚕️', 'name': 'Dokter'},
    {'emoji': '👨‍🏫', 'name': 'Guru'},
    {'emoji': '👨‍🍳', 'name': 'Koki'},
    {'emoji': '👨‍🚒', 'name': 'Pemadam Kebakaran'},
    {'emoji': '👮‍♂️', 'name': 'Polisi'},
    {'emoji': '👨‍💼', 'name': 'Pengusaha'},
    {'emoji': '👨‍🔧', 'name': 'Mekanik'},
    {'emoji': '👨‍🌾', 'name': 'Petani'},
    {'emoji': '👨‍✈️', 'name': 'Pilot'},
    {'emoji': '👨‍🎨', 'name': 'Seniman'},
    {'emoji': '👨‍💻', 'name': 'Programmer'},
    {'emoji': '👨‍🔬', 'name': 'Ilmuwan'},
    {'emoji': '👷‍♂️', 'name': 'Pekerja Konstruksi'},
  ];

  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  @override
  void dispose() {
    previewTimer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  void initializeGame() {
    cards.clear();
    selectedCards.clear();
    lives = 3;
    matchedPairs = 0;
    showingPreview = false;
    gameStarted = false;
    isChecking = false;
    previewTimeLeft = 10;
    
    previewTimer?.cancel();
    countdownTimer?.cancel();

    // Pilih 8 profesi secara acak untuk 4x4 grid (16 kartu = 8 pasang)
    final selectedProfessions = List<Map<String, String>>.from(professions);
    selectedProfessions.shuffle();
    
    int cardId = 0;
    // Buat 8 pasang kartu
    for (int i = 0; i < 8; i++) {
      cards.add(CardItem(
        emoji: selectedProfessions[i]['emoji']!,
        profession: selectedProfessions[i]['name']!,
        id: cardId++,
      ));
      cards.add(CardItem(
        emoji: selectedProfessions[i]['emoji']!,
        profession: selectedProfessions[i]['name']!,
        id: cardId++,
      ));
    }

    cards.shuffle();

    setState(() {});
  }

  void startGame() {
    setState(() {
      gameStarted = true;
      showingPreview = true;
      previewTimeLeft = 10;
    });

    // Buka semua kartu untuk preview
    for (var card in cards) {
      card.isFlipped = true;
    }

    // Countdown timer yang bergerak
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        previewTimeLeft--;
      });

      if (previewTimeLeft == 0) {
        timer.cancel();
        // Tutup semua kartu setelah preview selesai
        setState(() {
          showingPreview = false;
          for (var card in cards) {
            card.isFlipped = false;
          }
        });
      }
    });
  }

  void onCardTap(int index) {
    if (showingPreview || isChecking || cards[index].isFlipped || cards[index].isMatched) {
      return;
    }

    setState(() {
      cards[index].isFlipped = true;
      selectedCards.add(index);
    });

    if (selectedCards.length == 2) {
      isChecking = true;
      checkMatch();
    }
  }

  void checkMatch() {
    final first = cards[selectedCards[0]];
    final second = cards[selectedCards[1]];

    if (first.profession == second.profession) {
      // Cocok!
      setState(() {
        first.isMatched = true;
        second.isMatched = true;
        matchedPairs++;
      });

      selectedCards.clear();
      isChecking = false;

      // Cek apakah menang (8 pasang untuk grid 4x4)
      if (matchedPairs == 8) {
        Future.delayed(const Duration(milliseconds: 500), () {
          showWinDialog();
        });
      }
    } else {
      // Tidak cocok
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          cards[selectedCards[0]].isFlipped = false;
          cards[selectedCards[1]].isFlipped = false;
          selectedCards.clear();
          isChecking = false;
          lives--;

          if (lives == 0) {
            showGameOverDialog();
          }
        });
      });
    }
  }

  void showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blue[50],
        title: const Text(
          '🎉 SELAMAT! 🎉',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Anda berhasil mencocokkan semua kartu!',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              initializeGame();
            },
            child: const Text(
              'Main Lagi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[50],
        title: const Text(
          '💔 GAME OVER 💔',
          style: TextStyle(
            color: Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Kesempatan habis!\nKartu yang berhasil: $matchedPairs/8 pasang',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              initializeGame();
            },
            child: const Text(
              'Coba Lagi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Game Kartu Daya Ingat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[700],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Lives
                Row(
                  children: [
                    const Text(
                      'Nyawa: ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...List.generate(
                      3,
                      (index) => Icon(
                        index < lives ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                // Matched Pairs
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pasangan: $matchedPairs/8',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Preview Timer dengan countdown
          if (showingPreview)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange[100],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.remove_red_eye, color: Colors.orange, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Ingat posisi kartu!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '$previewTimeLeft detik',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Start Button atau Game Grid
          Expanded(
            child: Center(
              child: !gameStarted
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 100,
                          color: Colors.blue[300],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Game Kartu Daya Ingat',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Cocokkan semua pasangan kartu profesi!\nKamu punya 3 nyawa.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.play_arrow, size: 32),
                              SizedBox(width: 8),
                              Text(
                                'START',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: 16,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => onCardTap(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: cards[index].isFlipped || cards[index].isMatched
                                      ? Colors.white
                                      : Colors.blue[600],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: cards[index].isFlipped || cards[index].isMatched
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              cards[index].emoji,
                                              style: const TextStyle(fontSize: 40),
                                            ),
                                          ],
                                        )
                                      : Icon(
                                          Icons.help_outline,
                                          size: 40,
                                          color: Colors.blue[200],
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ),

          // Reset Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: initializeGame,
              icon: const Icon(Icons.refresh, size: 24),
              label: const Text(
                'Main Ulang',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}