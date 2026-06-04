import 'package:flutter/material.dart';
import 'dart:async';

class MemoryMatchGame extends StatelessWidget {
  const MemoryMatchGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const GameScreen();
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

    final selectedProfessions = List<Map<String, String>>.from(professions);
    selectedProfessions.shuffle();

    int cardId = 0;
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

    for (var card in cards) {
      card.isFlipped = true;
    }

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        previewTimeLeft--;
      });

      if (previewTimeLeft == 0) {
        timer.cancel();
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
      setState(() {
        first.isMatched = true;
        second.isMatched = true;
        matchedPairs++;
      });

      selectedCards.clear();
      isChecking = false;

      if (matchedPairs == 8) {
        Future.delayed(const Duration(milliseconds: 500), () {
          showWinDialog();
        });
      }
    } else {
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
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cs.primaryContainer,
        title: Text(
          '🎉 SELAMAT! 🎉',
          style: TextStyle(
            color: cs.onPrimaryContainer,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Anda berhasil mencocokkan semua kartu!',
          style: TextStyle(fontSize: 18, color: cs.onPrimaryContainer),
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
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cs.errorContainer,
        title: Text(
          '💔 GAME OVER 💔',
          style: TextStyle(
            color: cs.onErrorContainer,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Kesempatan habis!\nKartu yang berhasil: $matchedPairs/8 pasang',
          style: TextStyle(fontSize: 18, color: cs.onErrorContainer),
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Game Kartu Daya Ingat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: cs.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Text(
                      'Nyawa: ',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...List.generate(
                      3,
                      (index) => Icon(
                        index < lives ? Icons.favorite : Icons.favorite_border,
                        color: cs.error,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pasangan: $matchedPairs/8',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Preview Timer
          if (showingPreview)
            Container(
              padding: const EdgeInsets.all(16),
              color: cs.secondaryContainer,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove_red_eye, color: cs.onSecondaryContainer, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Ingat posisi kartu!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.secondary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '$previewTimeLeft detik',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: cs.onSecondary,
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
                          color: cs.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Game Kartu Daya Ingat',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Cocokkan semua pasangan kartu profesi!\nKamu punya 3 nyawa.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.tertiary ?? cs.secondary,
                            foregroundColor: cs.onTertiary ?? cs.onSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                  color: cards[index].isMatched
                                      ? cs.primaryContainer
                                      : cards[index].isFlipped
                                          ? cs.surface
                                          : cs.primary,
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
                                          color: cs.onPrimary.withOpacity(0.6),
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
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
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