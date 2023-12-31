// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'dart:convert';
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
      future: Preferences.getThemeMode(),
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

class Preferences {
  static const String themeModeKey = 'themeMode';
  static const String platformKey = 'allPlatforms';
  static const String archivedKey = 'archived';

  static Future<ThemeMode> getThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int themeModeValue = prefs.getInt(themeModeKey) ?? 0;
    return ThemeMode.values[themeModeValue];
  }

  static Future<void> setThemeMode(ThemeMode themeMode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeModeKey, themeMode.index);
  }

  static Future<bool> getPlatformSetting() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool platformValue = prefs.getBool(platformKey) ?? true;
    return platformValue;
  }

  static Future<void> setPlatformSetting(bool platformValue) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(platformKey, platformValue);
  }

  static Future<bool> getArchivedSetting() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool archivedValue = prefs.getBool(archivedKey) ?? true;
    return archivedValue;
  }

  static Future<void> setArchivedSetting(bool archivedValue) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(archivedKey, archivedValue);
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

class ThemedIconButton extends StatefulWidget {
  const ThemedIconButton({super.key});

  @override
  ThemedIconButtonState createState() => ThemedIconButtonState();
}

class ThemedIconButtonState extends State<ThemedIconButton> {
  ThemeMode selectedThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    Preferences.getThemeMode().then((themeMode) {
      setState(() {
        selectedThemeMode = themeMode;
      });
    });
  }

  void _changeState() {
    setState(() {
      if (selectedThemeMode == ThemeMode.system) {
        selectedThemeMode = ThemeMode.dark;
        Preferences.setThemeMode(selectedThemeMode);
        runApp(MyApp());
      } else if (selectedThemeMode == ThemeMode.dark) {
        selectedThemeMode = ThemeMode.light;
        Preferences.setThemeMode(selectedThemeMode);
        runApp(MyApp());
      } else {
        selectedThemeMode = ThemeMode.system;
        Preferences.setThemeMode(selectedThemeMode);
        runApp(MyApp());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final IconData iconData = selectedThemeMode == ThemeMode.light
        ? Icons.wb_sunny
        : selectedThemeMode == ThemeMode.system
            ? Icons.dark_mode
            : Icons.brightness_auto;

    return IconButton(
      icon: Icon(iconData),
      iconSize: 35,
      onPressed: () {
        _changeState();
      },
    );
  }
}

class HomePageContent extends StatefulWidget {
  @override
  HomePageContentState createState() => HomePageContentState();

  const HomePageContent({super.key});
}

class HomePageContentState extends State<HomePageContent> {
  Key _futureBuilderKey = UniqueKey();
  final _future = Supabase.instance.client
      .from('Archive-Items')
      .select<List<Map<String, dynamic>>>();

  Future<String> getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<String> getLatestReleaseVersion() async {
    var url = Uri.parse(
        'https://api.github.com/repos/OptixWolf/Archiv/releases/latest');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse['tag_name'];
    } else {
      return "failed";
    }
  }

  Future<bool> delay() async {
    await Future.delayed(Duration(seconds: 2));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 15),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: _futureBuilderKey,
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingAnimationWidget.threeArchedCircle(
                        color: Colors.blueGrey, size: 75),
                    FutureBuilder(
                        future: delay(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container();
                          } else {
                            return Column(
                              children: [
                                SizedBox(
                                  height: 20,
                                ),
                                Text(
                                    'Es konnte keine Verbindung zur Datenbank hergestellt werden'),
                                SizedBox(
                                  height: 10,
                                ),
                                TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _futureBuilderKey = UniqueKey();
                                      });
                                    },
                                    child: Text('Erneut versuchen'))
                              ],
                            );
                          }
                        }),
                  ]),
            );
          }
          final getitems = snapshot.data!;
          final items = removeDuplicatesKategorie(getitems);
          final localVersion = getPackageInfo();
          final newestVersion = getLatestReleaseVersion();

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  SizedBox(width: 7),
                  Text('Archiv', style: TextStyle(fontSize: 50)),
                  Spacer(),
                  ThemedIconButton(),
                  SizedBox(
                    width: 10,
                  )
                ]),
                SizedBox(height: 10),
                FutureBuilder(
                  future: Future.wait([localVersion, newestVersion]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Container();
                    } else if (snapshot.hasData) {
                      final lV = snapshot.data?[0];
                      final nV = snapshot.data?[1];

                      if (lV != nV) {
                        return Card(
                            child: ListTile(
                          title: Text('Versionsprüfung'),
                          subtitle: Text('Du hast nicht die neueste Version!'),
                          trailing: Icon(Icons.open_in_new),
                          onTap: () {
                            _launchURL(
                                'https://github.com/OptixWolf/Archiv/releases/latest');
                          },
                        ));
                      } else {
                        return Container();
                      }
                    }
                    return Container();
                  },
                ),
                SizedBox(height: 20),
                Row(children: [
                  SizedBox(width: 7),
                  Text('Kategorien', style: TextStyle(fontSize: 25))
                ]),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedItem['kategorie']),
      ),
      body: FutureBuilder(
          future: Preferences.getPlatformSetting(),
          builder: (context, snapshot) {
            dynamic platformValue;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              platformValue = true;
            } else {
              platformValue = snapshot.data;
            }

            dynamic items;

            if (platformValue) {
              items = removeDuplicatesPlattform(filteredItems);
            } else {
              final removedDuplicatedItems =
                  removeDuplicatesPlattform(filteredItems);
              items = removeOtherPlatforms(removedDuplicatedItems);
            }

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(children: [
                Row(
                  children: [
                    SizedBox(width: 7),
                    Text('Plattform', style: TextStyle(fontSize: 25))
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: ((context, index) {
                      final sortedItems = List.from(items);
                      sortedItems.sort(
                          (a, b) => a['plattform'].compareTo(b['plattform']));
                      final item = sortedItems[index];

                      return Card(
                        child: ListTile(
                            title: Text(item['plattform']),
                            trailing: Icon(Icons.arrow_forward),
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => DetailPage(
                                    getitems: getitems, selectedItem: item),
                              ));
                            }),
                      );
                    }),
                  ),
                ),
              ]),
            );
          }),
    );
  }
}

class DetailPage extends StatefulWidget {
  final List<Map<String, dynamic>> getitems;
  final Map<String, dynamic> selectedItem;

  const DetailPage(
      {super.key, required this.getitems, required this.selectedItem});

  @override
  DetailPageState createState() => DetailPageState();
}

class DetailPageState extends State<DetailPage> {
  late List<Map<String, dynamic>> filteredItems = [];

  bool archived = true;

  @override
  void initState() {
    super.initState();
    getArchivedValue().then((value) {
      setState(() {
        archived = value;
        filteredItems = widget.getitems
            .where((item) =>
                item['kategorie'] == widget.selectedItem['kategorie'] &&
                item['plattform'] == widget.selectedItem['plattform'])
            .toList();

        if (archived) {
          filteredItems = removeArchivedItems(filteredItems);
        }
      });
    });
  }

  Future<bool> getArchivedValue() async {
    final archivedValue = await Preferences.getArchivedSetting();
    return archivedValue;
  }

  void filterSearchResults(String query) {
    setState(() {
      filteredItems = widget.getitems
          .where((item) =>
              item['kategorie'] == widget.selectedItem['kategorie'] &&
              item['plattform'] == widget.selectedItem['plattform'] &&
              item['titel'].toLowerCase().contains(query.toLowerCase()))
          .toList();

      if (archived) {
        filteredItems = removeArchivedItems(filteredItems);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedItem['kategorie'] +
            ' - ' +
            widget.selectedItem['plattform']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              onChanged: filterSearchResults,
              decoration: InputDecoration(
                labelText: 'Suche',
                hintText: 'Suche',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final sortedItems = List.from(filteredItems);
                    sortedItems
                        .sort((a, b) => a['titel'].compareTo(b['titel']));
                    final item = sortedItems[index];

                    return Card(
                      child: ListTile(
                        title: Text(item['titel']),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                ItemDetailPage(selectedItem: item),
                          ));
                        },
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemDetailPage extends StatelessWidget {
  final Map<String, dynamic> selectedItem;

  const ItemDetailPage({super.key, required this.selectedItem});

  void setClipboardText(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _showSnackbar(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text('Inhalt wurde in die Zwischenablage gespeichert'),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedItem['titel']),
      ),
      body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Visibility(
                  visible: selectedItem['hint'] != null,
                  child: Column(
                    children: [
                      Card(
                          surfaceTintColor: Colors.red,
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
                    trailing: Icon(Icons.copy),
                    onTap: () {
                      setClipboardText(selectedItem['command']);
                      _showSnackbar(context);
                    },
                  )),
                ),
                Visibility(
                  visible: selectedItem['link'] != null,
                  child: Card(
                      child: ListTile(
                    title: Text(selectedItem['link-titel'] ?? ''),
                    subtitle: Text(selectedItem['link'] ?? ''),
                    trailing: Icon(Icons.open_in_new),
                    onTap: () {
                      _launchURL(selectedItem['link'] ?? '');
                    },
                  )),
                ),
                Visibility(
                  visible: selectedItem['link2'] != null,
                  child: Card(
                      child: ListTile(
                    title: Text(selectedItem['link2-titel'] ?? ''),
                    subtitle: Text(selectedItem['link2'] ?? ''),
                    trailing: Icon(Icons.open_in_new),
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
                    trailing: Icon(Icons.open_in_new),
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
                  trailing: Icon(Icons.open_in_new),
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  Row(children: [
                    SizedBox(
                      width: 7,
                    ),
                    Text('Über die App', style: TextStyle(fontSize: 40)),
                  ]),
                  SizedBox(height: 15),
                  Row(children: [
                    SizedBox(width: 7),
                    Text('Autor', style: TextStyle(fontSize: 25))
                  ]),
                  Card(
                      child: ListTile(
                    title: Text('OptixWolf', style: TextStyle(fontSize: 20)),
                    trailing: Icon(Icons.open_in_new),
                    onTap: () {
                      _launchURL('https://github.com/OptixWolf');
                    },
                  )),
                  SizedBox(height: 30),
                ],
              ),
              Row(children: [
                SizedBox(width: 7),
                Text('Discord', style: TextStyle(fontSize: 25))
              ]),
              SizedBox(height: 5),
              Card(
                  child: ListTile(
                title: Text('https://discord.gg/KW7GWQfKaj'),
                trailing: Icon(Icons.open_in_new),
                onTap: () {
                  _launchURL('https://discord.gg/KW7GWQfKaj');
                },
              )),
              SizedBox(height: 5),
              Card(
                  child: ListTile(
                title: Text('Warum beitreten?'),
                subtitle: Text(
                    '• Neue Archiv Einträge einreichen\n• Vorschläge für die App\n• Melden von problemen'),
              )),
            ],
          )),
    );
  }
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  bool selectedPlatformValue = true;
  bool selectedArchivedValue = true;

  @override
  void initState() {
    super.initState();
    Preferences.getPlatformSetting().then((platformValue) {
      setState(() {
        selectedPlatformValue = platformValue;
      });
    });
    Preferences.getArchivedSetting().then((archivedValue) {
      setState(() {
        selectedArchivedValue = archivedValue;
      });
    });
  }

  void toggleSwitchPlatform() {
    setState(() {
      selectedPlatformValue = !selectedPlatformValue;
      Preferences.setPlatformSetting(selectedPlatformValue);
    });
  }

  void toggleSwitchArchived() {
    setState(() {
      selectedArchivedValue = !selectedArchivedValue;
      Preferences.setArchivedSetting(selectedArchivedValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 10,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              SizedBox(width: 7),
              Text('Einstellungen', style: TextStyle(fontSize: 50)),
            ]),
            SizedBox(
              height: 25,
            ),
            Row(children: [
              SizedBox(width: 7),
              Text('Allgemeine Einstellungen', style: TextStyle(fontSize: 25)),
            ]),
            Card(
                child: ListTile(
              title: Text('Aktiviere alle Plattformen'),
              subtitle: Text(
                  'Wenn deaktiviert, siehst du nur noch Inhalte für deine aktuelle Plattform'),
              trailing: Switch(
                value: selectedPlatformValue,
                onChanged: (value) {
                  toggleSwitchPlatform();
                },
              ),
              onTap: () {
                toggleSwitchPlatform();
              },
            )),
            Card(
                child: ListTile(
              title: Text('Verstecke Archivierte Einträge'),
              subtitle:
                  Text('Wenn deaktiviert, siehst du Archivierte Einträge'),
              trailing: Switch(
                value: selectedArchivedValue,
                onChanged: (value) {
                  toggleSwitchArchived();
                },
              ),
              onTap: () {
                toggleSwitchArchived();
              },
            ))
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

List<Map<String, dynamic>> removeArchivedItems(
    List<Map<String, dynamic>> items) {
  List<Map<String, dynamic>> notArchivedItems = [];

  for (var item in items) {
    String currentItem = item['titel'];

    if (!currentItem.startsWith('[Archiviert]')) {
      notArchivedItems.add(item);
    }
  }

  return notArchivedItems;
}

List<Map<String, dynamic>> removeOtherPlatforms(
    List<Map<String, dynamic>> items) {
  List<Map<String, dynamic>> curPlatformItems = [];

  for (var item in items) {
    String plattform = item['plattform'];

    if (Platform.isAndroid && plattform.contains('Android') ||
        Platform.isLinux && plattform.contains('Linux') ||
        Platform.isWindows && plattform.contains('Windows') ||
        plattform == 'Universell' ||
        plattform == 'Browser') {
      curPlatformItems.add(item);
    }
  }

  return curPlatformItems;
}

_launchURL(String url) async {
  final Uri finalUrl = Uri.parse(url);
  if (!await launchUrl(finalUrl)) {
    throw Exception('Could not launch $finalUrl');
  }
}
