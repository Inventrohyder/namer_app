import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart' as xml;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // TRY THIS: Try running your application with "flutter run". You'll see
          // the application has a blue toolbar. Then, without quitting the app,
          // try changing the seedColor in the colorScheme below to Colors.green
          // and then invoke "hot reload" (save your changes or press the "hot
          // reload" button in a Flutter-supported IDE, or press "r" if you used
          // the command line to start the app).
          //
          // Notice that the counter didn't reset back to zero; the application
          // state is not lost during the reload. To reset the state, use hot
          // restart instead.
          //
          // This works for code too, not just values: Most code changes can be
          // tested with just a hot reload.
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  WordPair current = WordPair.random();
  List<WordPair> history = <WordPair>[];

  GlobalKey? historyListKey;

  Set<WordPair> favorites = <WordPair>{};

  void getNext() {
    history.insert(0, current);
    AnimatedListState? animatedList =
        historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    current = WordPair.random();
    notifyListeners();
  }

  void unFavorite(WordPair pair) {
    bool removed = favorites.remove(pair);
    if (removed) {
      notifyListeners();
    }
  }

  void toggleFavorite({WordPair? pair}) {
    pair ??= current;

    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const GeneratorPage();
        break;
      case 1:
        page = const FavouritePage();
        break;
      default:
        throw UnimplementedError("no widget for $selectedIndex");
    }

    // The container for the current page, with its background colour
    // and subtle switching animation

    ColoredBox mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: page,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Use a more mobile-friendly layout with BottomNavigationBar
          // on narrow screens
          return Scaffold(
            body: mainArea,
            bottomNavigationBar: NavigationBar(
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: "Home",
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: "Favorites",
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth > 1240,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text("Home"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite),
                      label: Text("Favorites"),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: mainArea,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GeneratorPage extends StatelessWidget {
  const GeneratorPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    MyAppState appState = context.watch<MyAppState>();

    WordPair pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(
            flex: 3,
            child: HistoryListView(),
          ),
          const SizedBox(height: 10),
          BigCard(pair: pair),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => appState.toggleFavorite(),
                icon: Icon(icon),
                label: const Text("Like"),
              ),
              const SizedBox(
                width: 10,
              ),
              ElevatedButton(
                onPressed: () => appState.getNext(),
                child: const Text("Next"),
              ),
            ],
          ),
          const Spacer(
            flex: 2,
          ),
        ],
      ),
    );
  }
}

class HistoryListView extends StatefulWidget {
  const HistoryListView({
    super.key,
  });

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  /// Needed so  that [MyAppState] can tell [AnimatedList] below to animate
  /// new items

  final _key = GlobalKey();

  /// Used to 'fade out' the history items at the top to suggest continuation
  static const Gradient _maskingGradient = LinearGradient(
    // this gradient goes from fully transparent to fully opaque black ...
    colors: [Colors.transparent, Colors.black],
    // ... from the top (transparent) to half (0.5) of the way to the bottom.
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      //This blend mode takes the opacity of the shader (i.e our gradient)
      //and applies it to the destination (i.e our animated list
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: const EdgeInsets.only(top: 100),
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.history[index];
          return SizeTransition(
              sizeFactor: animation,
              child: Center(
                child: TextButton.icon(
                  icon: appState.favorites.contains(pair)
                      ? const Icon(
                          Icons.favorite,
                          size: 12,
                        )
                      : const SizedBox(),
                  label: Text(
                    pair.asLowerCase,
                    semanticsLabel: pair.asPascalCase,
                  ),
                  onPressed: () {
                    appState.toggleFavorite(
                      pair: pair,
                    );
                  },
                ),
              ));
        },
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: MergeSemantics(
            child: Wrap(
              children: [
                Text(
                  pair.first,
                  style: style.copyWith(
                    fontWeight: FontWeight.w100,
                  ),
                ),
                Text(
                  pair.second,
                  style: style.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FavouritePage extends StatelessWidget {
  const FavouritePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    MyAppState appState = context.watch<MyAppState>();

    if (appState.favorites.isNotEmpty) {
      return Column(
        children: [
          Expanded(
            child: GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 600,
                childAspectRatio: 600 / 300,
              ),
              children: appState.favorites
                  .map(
                    (pair) => ListTile(
                      trailing: IconButton(
                        onPressed: () => appState.unFavorite(pair),
                        icon: const Icon(
                          Icons.delete,
                        ),
                      ),
                      title: BigCard(pair: pair),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      );
    } else {
      return const EmptyView();
    }
  }
}

class EmptyView extends StatefulWidget {
  const EmptyView({super.key});

  @override
  State<EmptyView> createState() => _EmptyViewState();
}

class _EmptyViewState extends State<EmptyView> {
  String? svgString;

  String colorToHex(Color color) {
    return '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}';
  }

  Future<void> _loadSvg(String newColor) async {
    // Load the SVG file as a string
    String rawSvg =
        await rootBundle.loadString('svgs/undraw_no_data_re_kwbl.svg');

    // Parse the SVG
    var document = xml.XmlDocument.parse(rawSvg);

    // Iterate through the elements and change the specific color
    const String targetColor = '#6c63ff';
    document.descendants.whereType<xml.XmlElement>().forEach((element) {
      final String? fillColor = element.getAttribute('fill');
      if (fillColor == targetColor) {
        element.setAttribute('fill', newColor);
      }
    });

    // Update the state with the modified SVG string
    setState(() {
      svgString = document.toXmlString();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (svgString == null) {
      String newColor = colorToHex(Theme.of(context).colorScheme.primary);
      _loadSvg(newColor); // Pass the color hex string to the _loadSvg method
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          svgString != null
              ? SvgPicture.string(
                  svgString!,
                  height: 250,
                )
              : const CircularProgressIndicator(),
          const SizedBox(
            height: 10,
          ),
          Text(
            "No Favorites yet!",
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ],
      ),
    );
  }
}
