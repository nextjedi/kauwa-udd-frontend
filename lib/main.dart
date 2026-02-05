import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const KauwaUddApp());
}

List<ThemeData> themes = [
  ThemeData(primarySwatch: Colors.blue),
  ThemeData(primarySwatch: Colors.red),
  ThemeData(primarySwatch: Colors.green),
  ThemeData(primarySwatch: Colors.purple),
  ThemeData(primarySwatch: Colors.orange),
  ThemeData(primarySwatch: Colors.blue), // Custom placeholder
];

class KauwaUddApp extends StatefulWidget {
  const KauwaUddApp({super.key});

  @override
  State<KauwaUddApp> createState() => _KauwaUddAppState();
}

class _KauwaUddAppState extends State<KauwaUddApp> {
  int selectedTheme = 0;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedTheme = prefs.getInt('selectedTheme') ?? 0;
    });
  }

  _saveTheme(int theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('selectedTheme', theme);
  }

  void _changeTheme(int theme) {
    setState(() {
      selectedTheme = theme;
    });
    _saveTheme(theme);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kauwa Udd',
      theme: themes[selectedTheme],
      home: HomePage(onThemeChanged: _changeTheme, selectedTheme: selectedTheme),
    );
  }
}

class HomePage extends StatelessWidget {
  final Function(int) onThemeChanged;
  final int selectedTheme;

  const HomePage({super.key, required this.onThemeChanged, required this.selectedTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kauwa Udd'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Kauwa Udd',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButton<int>(
              value: selectedTheme,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Blue Theme')),
                DropdownMenuItem(value: 1, child: Text('Red Theme')),
                DropdownMenuItem(value: 2, child: Text('Green Theme')),
                DropdownMenuItem(value: 3, child: Text('Purple Theme')),
                DropdownMenuItem(value: 4, child: Text('Orange Theme')),
                DropdownMenuItem(value: 5, child: Text('Custom Theme')),
              ],
              onChanged: (value) {
                onThemeChanged(value!);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlayerSetupPage()),
                );
              },
              child: const Text('Start Game'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DemoPage()),
                );
              },
              child: const Text('Show Me (Demo)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatsPage()),
                );
              },
              child: const Text('Player Stats'),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerSetupPage extends StatefulWidget {
  const PlayerSetupPage({super.key});

  @override
  State<PlayerSetupPage> createState() => _PlayerSetupPageState();
}

class _PlayerSetupPageState extends State<PlayerSetupPage> {
  int numPlayers = 4;
  List<String> playerNames = [];
  List<String> previousPlayers = [];

  @override
  void initState() {
    super.initState();
    playerNames = List.filled(numPlayers, '');
    _loadPrevious();
  }

  _loadPrevious() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      previousPlayers = prefs.getStringList('previousPlayers') ?? [];
    });
  }

  _savePlayers(List<String> names) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> all = [...previousPlayers, ...names.where((n) => n.isNotEmpty && !n.startsWith('Bot'))];
    prefs.setStringList('previousPlayers', all.toSet().toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Number of Players: '),
                DropdownButton<int>(
                  value: numPlayers,
                  items: List.generate(8, (index) => index + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      numPlayers = value!;
                      playerNames = List.filled(numPlayers, '');
                    });
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: numPlayers,
                itemBuilder: (context, index) {
                  return Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return [];
                      return previousPlayers.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      setState(() {
                        playerNames[index] = selection;
                      });
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(labelText: 'Player ${index + 1} Name (leave empty for bot)'),
                        onChanged: (value) {
                          playerNames[index] = value;
                        },
                      );
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                List<String> names = [];
                for (int i = 0; i < numPlayers; i++) {
                  String name = playerNames[i].isNotEmpty ? playerNames[i] : 'Bot ${names.where((n) => n.startsWith('Bot')).length + 1}';
                  names.add(name);
                }
                _savePlayers(names.where((n) => !n.startsWith('Bot')).toList());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GamePage(players: names, isDemo: false),
                  ),
                );
              },
              child: const Text('Start Game'),
            ),
          ],
        ),
      ),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> bots = List.generate(7, (index) => 'Bot ${index + 1}');
    return GamePage(players: bots, isDemo: true);
  }
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  Map<String, int> stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  _loadStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      List<String> keys = prefs.getKeys().where((k) => k.startsWith('score_')).toList();
      for (String k in keys) {
        stats[k.substring(6)] = prefs.getInt(k) ?? 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, int>> sorted = stats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      appBar: AppBar(title: const Text('Player Stats')),
      body: ListView.builder(
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(sorted[index].key),
            trailing: Text('${sorted[index].value} points'),
          );
        },
      ),
    );
  }
}

enum GameState { ready, playing, results }

class GamePage extends StatefulWidget {
  final List<String> players;
  final bool isDemo;

  const GamePage({super.key, required this.players, required this.isDemo});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late List<int> scores;
  String currentObject = '';
  bool isFlying = false;
  GameState gameState = GameState.ready;
  List<bool> ready = [];
  List<bool> reacted = [];
  List<int> reactionTimes = [];
  DateTime? roundStartTime;
  Timer? roundTimer;
  int countdown = 0;
  Map<String, int> playerStats = {};

  @override
  void initState() {
    super.initState();
    scores = List.filled(widget.players.length, 0);
    ready = List.filled(widget.players.length, false);
    reacted = List.filled(widget.players.length, false);
    reactionTimes = List.filled(widget.players.length, -1);
    _loadStats();
    // Simulate bots placing fingers
    for (int i = 0; i < widget.players.length; i++) {
      if (widget.players[i].startsWith('Bot')) {
        int delay = Random().nextInt(2000) + 500;
        Future.delayed(Duration(milliseconds: delay), () {
          if (mounted && gameState == GameState.ready) placeFinger(i, true);
        });
      }
    }
    if (widget.isDemo) {
      startDemo();
    }
  }

  _loadStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> keys = prefs.getKeys().where((k) => k.startsWith('score_')).toList();
    for (String k in keys) {
      playerStats[k.substring(6)] = prefs.getInt(k) ?? 0;
    }
  }

  _saveStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    playerStats.forEach((p, s) => prefs.setInt('score_$p', s));
  }

  void startDemo() {
    // Simulate placing fingers for bots
    setState(() {
      gameState = GameState.ready;
      ready = List.filled(widget.players.length, false);
    });
    for (int i = 0; i < widget.players.length; i++) {
      int delay = Random().nextInt(2000) + 500; // 0.5 to 2.5 seconds
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted && gameState == GameState.ready) placeFinger(i, true);
      });
    }
  }

  void placeFinger(int playerIndex, bool isPlacing) {
    if (gameState != GameState.ready) return;
    if (!isPlacing && ready[playerIndex]) return; // Can't unplace once placed
    setState(() {
      ready[playerIndex] = isPlacing;
    });
    if (ready.every((r) => r)) {
      startCountdown();
    }
  }

  void startCountdown() {
    setState(() {
      countdown = 3;
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        countdown--;
      });
      if (countdown == 0) {
        timer.cancel();
        setState(() {
          gameState = GameState.playing;
        });
        startRound();
      }
    });
  }

  void startRound() {
    if (!mounted) return;
    String obj = getRandomObject();
    setState(() {
      currentObject = obj;
      isFlying = flyingObjects.contains(obj.toLowerCase());
      reacted = List.filled(widget.players.length, false);
      reactionTimes = List.filled(widget.players.length, -1);
      roundStartTime = DateTime.now();
    });
    // Simulate reactions for bots
    for (int i = 0; i < widget.players.length; i++) {
      if (widget.players[i].startsWith('Bot')) {
        int delay = Random().nextInt(2000) + 200; // 0.2 to 2.2 seconds
        Future.delayed(Duration(milliseconds: delay), () {
          if (mounted && gameState == GameState.playing) {
            react(i, delay);
          }
        });
      }
    }
    // End round after 2 seconds
    roundTimer = Timer(const Duration(seconds: 2), endRound);
  }

  void react(int playerIndex, int timeMs) {
    if (gameState != GameState.playing || reacted[playerIndex]) return;
    setState(() {
      reacted[playerIndex] = true;
      reactionTimes[playerIndex] = timeMs;
    });
  }

  void endRound() {
    roundTimer?.cancel();
    setState(() {
      gameState = GameState.results;
    });
    // Calculate points
    for (int i = 0; i < widget.players.length; i++) {
      int points = 0;
      if (reacted[i]) {
        if (isFlying) {
          points = 1;
          if (reactionTimes[i] < 500) points += 1;
        } else {
          points = -1;
        }
      } else {
        if (!isFlying) {
          points = 0;
        } else {
          points = -1;
        }
      }
      scores[i] += points;
    }
    // Check for first bonus
    List<int> reactedIndices = [];
    for (int i = 0; i < reacted.length; i++) {
      if (reacted[i]) reactedIndices.add(i);
    }
    if (reactedIndices.isNotEmpty) {
      int first = reactedIndices.reduce((a, b) => reactionTimes[a] < reactionTimes[b] ? a : b);
      if (isFlying) scores[first] += 1;
    }
    // Update stats
    for (int i = 0; i < widget.players.length; i++) {
      playerStats[widget.players[i]] = (playerStats[widget.players[i]] ?? 0) + scores[i];
    }
    _saveStats();
    // Show results
    showResultsDialog();
  }

  void showResultsDialog() {
    List<Map<String, dynamic>> playerData = [];
    for (int i = 0; i < widget.players.length; i++) {
      playerData.add({
        'name': widget.players[i],
        'score': scores[i],
        'time': isFlying && reacted[i] ? '${(reactionTimes[i] / 1000).toStringAsFixed(3)}s' : 'N/A',
        'reacted': reacted[i],
      });
    }
    playerData.sort((a, b) => b['score'].compareTo(a['score']));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Round Results'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playerData.length,
            itemBuilder: (context, index) {
              var data = playerData[index];
              return ListTile(
                title: Text('${index + 1}. ${data['name']}'),
                subtitle: Text('Score: ${data['score']} | Time: ${data['time']}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              nextRound();
            },
            child: const Text('Next Round'),
          ),
        ],
      ),
    );
  }

  void nextRound() {
    setState(() {
      gameState = GameState.ready;
      ready = List.filled(widget.players.length, false);
    });
    // Auto place for bots
    for (int i = 0; i < widget.players.length; i++) {
      if (widget.players[i].startsWith('Bot')) {
        int delay = Random().nextInt(2000) + 500; // 0.5 to 2.5 seconds
        Future.delayed(Duration(milliseconds: delay), () {
          if (mounted && gameState == GameState.ready) placeFinger(i, true);
        });
      }
    }
    if (widget.isDemo) {
      startDemo();
    }
  }

  String getRandomObject() {
    List<String> all = [...flyingObjects, ...nonFlyingObjects];
    return all[Random().nextInt(all.length)];
  }

  @override
  void dispose() {
    roundTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top;
    double centerX = screenWidth / 2;
    double centerY = screenHeight / 2;
    double radius = min(screenWidth, screenHeight) / 3;

    String centerText;
    switch (gameState) {
      case GameState.ready:
        centerText = 'Place your fingers!';
        break;
      case GameState.playing:
        centerText = '$currentObject flies?';
        break;
      case GameState.results:
        centerText = 'Calculating scores...';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kauwa Udd'),
      ),
      body: Column(
        children: [
          // Quick scorecard
          Container(
            height: 50,
            color: Theme.of(context).cardColor,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.players.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.players[index], style: const TextStyle(fontSize: 12)),
                      Text('${scores[index]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
            ),
          ),
          // Announcement at the top
          Container(
            height: 80,
            alignment: Alignment.center,
            color: Theme.of(context).primaryColorLight,
            child: Text(
              centerText,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Players around the circle
                ...List.generate(widget.players.length, (index) {
                  double angle = 2 * pi * index / widget.players.length;
                  double x = radius * cos(angle);
                  double y = radius * sin(angle);
                  Color bgColor;
                  switch (gameState) {
                    case GameState.ready:
                      bgColor = ready[index] ? Colors.green : Colors.grey;
                      break;
                    case GameState.playing:
                      bgColor = reacted[index] ? Colors.green : Colors.grey;
                      break;
                    case GameState.results:
                      bgColor = Colors.blue;
                      break;
                  }
                  bool isBot = widget.players[index].startsWith('Bot');
                  return Positioned(
                    left: centerX + x - 50,
                    top: centerY + y - 50,
                    child: isBot ? Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: bgColor,
                          child: Text(
                            widget.players[index],
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Text('${scores[index]}', style: const TextStyle(fontSize: 16)),
                        if (gameState == GameState.results && isFlying && reacted[index])
                          Text('${(reactionTimes[index] / 1000).toStringAsFixed(3)}s', style: const TextStyle(fontSize: 10)),
                      ],
                    ) : GestureDetector(
                      onLongPressStart: (_) => placeFinger(index, true),
                      onLongPressEnd: (_) => placeFinger(index, false),
                      onTap: () {
                        if (gameState == GameState.playing) {
                          int timeMs = DateTime.now().difference(roundStartTime!).inMilliseconds;
                          react(index, timeMs);
                        }
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: bgColor,
                            child: Text(
                              widget.players[index],
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Text('${scores[index]}', style: const TextStyle(fontSize: 16)),
                          if (gameState == GameState.results && isFlying && reacted[index])
                            Text('${(reactionTimes[index] / 1000).toStringAsFixed(3)}s', style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Data
const List<String> flyingObjects = [
  'crow', 'eagle', 'sparrow', 'pigeon', 'parrot', 'owl', 'hawk', 'falcon', 'duck', 'swan',
  'goose', 'albatross', 'seagull', 'vulture', 'raven', 'robin', 'finch', 'canary', 'nightingale', 'bat',
  'butterfly', 'bee', 'wasp', 'moth', 'dragonfly', 'mosquito', 'fly', 'grasshopper', 'locust', 'airplane',
  'helicopter', 'hot air balloon', 'drone', 'rocket', 'kite', 'hang glider', 'paraglider', 'jet', 'fighter jet', 'bomber',
  'blimp', 'zephyr', 'glider', 'biplane', 'seaplane', 'supersonic jet', 'space shuttle', 'satellite', 'meteor', 'comet',
  'angel', 'fairy', 'superman', 'batman', 'spiderman', 'iron man', 'thor', 'captain america', 'wonder woman', 'flash',
  'green lantern', 'aquaman', 'cyborg', 'martian manhunter', 'green arrow', 'black canary', 'joker', 'lex luthor', 'darkseid', 'thanos',
  'iron man suit', 'hulk', 'wolverine', 'deadpool', 'venom', 'carnage', 'doctor strange', 'scarlet witch', 'vision', 'falcon',
  'war machine', 'black widow', 'hawkeye', 'ant-man', 'wasp', 'captain marvel', 'she-hulk', 'moon knight', 'blade', 'morbius',
  'hellboy', 'spawn', 'the mask', 'buzz lightyear', 'woody', 'jessie', 'bullseye', 'sid', 'andy', 'rex',
  'slinky', 'mr potato head', 'little bo peep', 'barbie', 'ken', 'stitch', 'lilo', 'nemo', 'dory', 'marlin',
  'crush', 'squirt', 'hank', 'destiny', 'bailey', 'gill', 'bloat', 'gurgle', 'deb', 'flo',
];

const List<String> nonFlyingObjects = [
  'cow', 'dog', 'cat', 'elephant', 'lion', 'tiger', 'horse', 'sheep', 'goat', 'pig',
  'chicken', 'rooster', 'turkey', 'duckling', 'goose', 'swan', 'ostrich', 'emu', 'penguin', 'kiwi',
  'platypus', 'kangaroo', 'koala', 'sloth', 'panda', 'bear', 'wolf', 'fox', 'rabbit', 'hare',
  'deer', 'moose', 'elk', 'buffalo', 'bison', 'rhinoceros', 'hippopotamus', 'giraffe', 'zebra', 'monkey',
  'ape', 'chimpanzee', 'gorilla', 'orangutan', 'baboon', 'lemur', 'tarsier', 'marmoset', 'capuchin', 'howler monkey',
  'crocodile', 'alligator', 'snake', 'lizard', 'turtle', 'tortoise', 'frog', 'toad', 'salamander', 'newt',
  'fish', 'shark', 'whale', 'dolphin', 'seal', 'otter', 'beaver', 'mouse', 'rat', 'hamster',
  'guinea pig', 'gerbil', 'ferret', 'skunk', 'badger', 'hedgehog', 'porcupine', 'armadillo', 'anteater', 'pangolin',
  'camel', 'llama', 'alpaca', 'vicuna', 'yak', 'ox', 'bull', 'calf', 'donkey', 'mule',
  'zebu', 'banteng', 'gaur', 'water buffalo', 'caribou', 'reindeer', 'ibex', 'goat', 'sheep', 'ram',
  'ewe', 'lamb', 'kid', 'fawn', 'doe', 'buck', 'stag', 'hind', 'antelope', 'gazelle',
];
