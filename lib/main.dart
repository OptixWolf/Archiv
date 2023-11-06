// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'keys.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeMode>(
      future: ThemePreferences.getThemeMode(),
      builder: (context, themeModeSnapshot) {
        final currentThemeMode = themeModeSnapshot.data ?? ThemeMode.system;

        return MaterialApp(
          title: 'Archiv',
          home: HomePage(),
          themeMode: currentThemeMode,
          theme: ThemeData.light(
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(
            useMaterial3: true,
          ),
        );
      },
    );
  }
}

class ThemePreferences {
  static const String themeModeKey = 'themeMode';

  static Future<ThemeMode> getThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int themeModeValue = prefs.getInt(themeModeKey) ?? 0;
    return ThemeMode.values[themeModeValue];
  }

  // Funktion zum Speichern des ausgewählten ThemeMode
  static Future<void> setThemeMode(ThemeMode themeMode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeModeKey, themeMode.index);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePageContent(),
    About(),
    Settings(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 10),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Archiv',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Über die App',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
        ],
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  final _future = Supabase.instance.client
      .from('Archive-Items')
      .select<List<Map<String, dynamic>>>();

  HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 15),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final getitems = snapshot.data!;
          final items = removeDuplicatesKategorie(getitems);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Archiv',
                  style: TextStyle(fontSize: 50),
                ),
                SizedBox(height: 10),
                Text('Kategorien', style: TextStyle(fontSize: 25)),
                SizedBox(height: 5),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: ((context, index) {
                      final sortedItems = List.from(items);
                      sortedItems.sort(
                          (a, b) => a['kategorie'].compareTo(b['kategorie']));
                      final item = sortedItems[index];
                      return Card(
                        child: ListTile(
                          title: Text(item['kategorie']),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => PlattformDetailPage(
                                  getitems: getitems, selectedItem: item),
                            ));
                          },
                          trailing: Icon(Icons.arrow_forward),
                        ),
                      );
                    }),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class PlattformDetailPage extends StatelessWidget {
  final List<Map<String, dynamic>> getitems;
  final Map<String, dynamic> selectedItem;

  const PlattformDetailPage(
      {super.key, required this.getitems, required this.selectedItem});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredItems = getitems.where((item) {
      return item['kategorie'] == selectedItem['kategorie'];
    }).toList();
    final items = removeDuplicatesPlattform(filteredItems);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedItem['kategorie']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: ((context, index) {
            final sortedItems = List.from(items);
            sortedItems
                .sort((a, b) => a['plattform'].compareTo(b['plattform']));
            final item = sortedItems[index];
            return Card(
              child: ListTile(
                  title: Text(item['plattform']),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          DetailPage(getitems: getitems, selectedItem: item),
                    ));
                  }),
            );
          }),
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final List<Map<String, dynamic>> getitems;
  final Map<String, dynamic> selectedItem;

  const DetailPage(
      {super.key, required this.getitems, required this.selectedItem});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredItems = getitems.where((item) {
      return item['kategorie'] == selectedItem['kategorie'] &&
          item['plattform'] == selectedItem['plattform'];
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title:
            Text(selectedItem['kategorie'] + ' - ' + selectedItem['plattform']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: filteredItems.length,
          itemBuilder: ((context, index) {
            final sortedItems = List.from(filteredItems);
            sortedItems.sort((a, b) => a['titel'].compareTo(b['titel']));
            final item = sortedItems[index];
            return Card(
              child: ListTile(
                  title: Text(item['titel']),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ItemDetailPage(selectedItem: item),
                    ));
                  }),
            );
          }),
        ),
      ),
    );
  }
}

class ItemDetailPage extends StatelessWidget {
  final Map<String, dynamic> selectedItem;

  const ItemDetailPage({super.key, required this.selectedItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedItem['titel']),
      ),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Visibility(
                  visible: selectedItem['hint'] != null,
                  child: Column(
                    children: [
                      Card(
                          child: ListTile(
                        title: Text('Hinweis'),
                        subtitle: Text(selectedItem['hint'] ?? ''),
                      )),
                      SizedBox(
                        height: 10,
                      )
                    ],
                  ),
                ),
                Card(
                    child: ListTile(
                  title: Text(selectedItem['titel']),
                  subtitle: Text(selectedItem['beschreibung']),
                )),
                Visibility(
                  visible: selectedItem['command'] != null,
                  child: Card(
                      child: ListTile(
                    title: Text(selectedItem['command-titel'] ?? ''),
                    subtitle: Text(selectedItem['command'] ?? ''),
                  )),
                ),
                Card(
                    child: ListTile(
                  title: Text(selectedItem['link-titel']),
                  subtitle: Text(selectedItem['link']),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    _launchURL(selectedItem['link']);
                  },
                )),
                Visibility(
                  visible: selectedItem['link2'] != null,
                  child: Card(
                      child: ListTile(
                    title: Text(selectedItem['link2-titel'] ?? ''),
                    subtitle: Text(selectedItem['link2'] ?? ''),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      _launchURL(selectedItem['link2'] ?? '');
                    },
                  )),
                ),
                Visibility(
                  visible: selectedItem['link3'] != null,
                  child: Card(
                      child: ListTile(
                    title: Text(selectedItem['link3-titel'] ?? ''),
                    subtitle: Text(selectedItem['link3'] ?? ''),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      _launchURL(selectedItem['link3'] ?? '');
                    },
                  )),
                ),
                SizedBox(
                  height: 25,
                ),
                Card(
                    child: ListTile(
                  title: Text('Projekt Autor'),
                  subtitle: Text(selectedItem['projekt-autor']),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    _launchURL(selectedItem['projekt-autor-link'] ?? '');
                  },
                )),
                Card(
                    child: ListTile(
                  title: Text('Bereitgestellt durch'),
                  subtitle: Text(selectedItem['autor']),
                ))
              ],
            ),
          )),
    );
  }
}

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 10,
      ),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  Text(
                    'Über die App',
                    style: TextStyle(fontSize: 40),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Autor',
                    style: TextStyle(fontSize: 25),
                  ),
                  Card(
                      child: ListTile(
                    title: Text('OptixWolf', style: TextStyle(fontSize: 20)),
                  )),
                  SizedBox(height: 30),
                ],
              ),
              Text(
                'Discord',
                style: TextStyle(fontSize: 25),
              ),
              SizedBox(height: 5),
              Card(
                  child: ListTile(
                title: Text('https://discord.gg/KW7GWQfKaj'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  _launchURL('https://discord.gg/KW7GWQfKaj');
                },
              )),
              SizedBox(height: 5),
              Card(
                  child: ListTile(
                title: Text('Warum beitreten?'),
                subtitle: Text(
                    '• Neue Archiv einträge einreichen\n• Vorschläge für die App\n• Melden von problemen'),
              )),
            ],
          )),
    );
  }
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  ThemeMode selectedThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    ThemePreferences.getThemeMode().then((themeMode) {
      setState(() {
        selectedThemeMode = themeMode;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 10,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Einstellungen', style: TextStyle(fontSize: 50)),
            SizedBox(
              height: 25,
            ),
            Text('System Design', style: TextStyle(fontSize: 25)),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('System folgen'),
                    leading: Radio(
                      value: ThemeMode.system,
                      groupValue: selectedThemeMode,
                      onChanged: (value) {
                        setState(() {
                          ThemePreferences.setThemeMode(value as ThemeMode);
                          selectedThemeMode = value;
                          runApp(MyApp());
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Heller Modus'),
                    leading: Radio(
                      value: ThemeMode.light,
                      groupValue: selectedThemeMode,
                      onChanged: (value) {
                        setState(() {
                          ThemePreferences.setThemeMode(value as ThemeMode);
                          selectedThemeMode = value;
                          runApp(MyApp());
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Dark Mode'),
                    leading: Radio(
                      value: ThemeMode.dark,
                      groupValue: selectedThemeMode,
                      onChanged: (value) {
                        setState(() {
                          ThemePreferences.setThemeMode(value as ThemeMode);
                          selectedThemeMode = value;
                          runApp(MyApp());
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> removeDuplicatesKategorie(
    List<Map<String, dynamic>> items) {
  Set<String> seenCategories = {};
  List<Map<String, dynamic>> uniqueItems = [];

  for (var item in items) {
    String category = item['kategorie'];

    if (!seenCategories.contains(category)) {
      seenCategories.add(category);
      uniqueItems.add(item);
    }
  }

  return uniqueItems;
}

List<Map<String, dynamic>> removeDuplicatesPlattform(
    List<Map<String, dynamic>> items) {
  Set<String> seenCategories = {};
  List<Map<String, dynamic>> uniqueItems = [];

  for (var item in items) {
    String category = item['plattform'];

    if (!seenCategories.contains(category)) {
      seenCategories.add(category);
      uniqueItems.add(item);
    }
  }

  return uniqueItems;
}

_launchURL(String url) async {
  final Uri finalUrl = Uri.parse(url);
  if (!await launchUrl(finalUrl)) {
    throw Exception('Could not launch $finalUrl');
  }
}
