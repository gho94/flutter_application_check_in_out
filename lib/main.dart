import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomeScreen(title: "CheckInOutTitle"),
    );
  }
}

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key, required this.title});

  final String title;

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  List<Map<String, dynamic>> checkData = [];
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    initialization();
  }

  void initialization() async {
    FlutterNativeSplash.remove();
  }

  void _onDestinationSelected(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  void updateCheckData(List<Map<String, dynamic>> data) {
    setState(() {
      checkData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("출석체크"),
          centerTitle: true,
        ),
        bottomNavigationBar: NavigationBar(selectedIndex: currentPageIndex, onDestinationSelected: _onDestinationSelected, destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "출석체크"),
          NavigationDestination(icon: Icon(Icons.share), label: "내역"),
        ]),
        body: [
          FirstPage(
            onCheckUpdated: updateCheckData,
          ),
          SecondPage(
            checkData: checkData,
          )
        ][currentPageIndex]);
  }
}

class FirstPage extends StatefulWidget {
  const FirstPage({super.key, required this.onCheckUpdated});

  final Function(List<Map<String, dynamic>>) onCheckUpdated;

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  late Database _database;
  List<Map<String, dynamic>> _check = [];
  bool _isCheck = false;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'check_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE check_table(id INTEGER PRIMARY KEY, checkState INTEGER, checkTime TEXT)",
        );
      },
      version: 1,
    );
    _fetchCheck();
  }

  Future<void> _addCheck(bool isCheck, String checkTime) async {
    await _database.insert(
      'check_table',
      {'checkState': isCheck ? 1 : 0, 'checkTime': checkTime},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _fetchCheck();
  }

  Future<void> _fetchCheck() async {
    final List<Map<String, dynamic>> maps = await _database.query('check_table');
    setState(() {
      _check = maps;
    });
    widget.onCheckUpdated(_check);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("출석 체크"),
            Switch(
                value: _isCheck,
                onChanged: (value) {
                  final String checkTime = DateTime.now().toString();
                  setState(() {
                    _isCheck = value;
                  });
                  _addCheck(_isCheck, checkTime);
                }),
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key, required this.checkData});

  final List<Map<String, dynamic>> checkData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: checkData.length,
        itemBuilder: (context, index) {
          final check = checkData[index];
          return ListTile(
            title: Text(check["checkState"] == 1 ? "출석 시간" : "퇴실 시간"),
            subtitle: Text(check["checkTime"]),
          );
        },
      ),
    );
  }
}
