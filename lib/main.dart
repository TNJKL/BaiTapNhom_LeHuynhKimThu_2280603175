import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'screens/translate_screen.dart';
import 'screens/alarm_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/group_info_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TranslateScreen(),
    const AlarmScreen(),
    const ProfileScreen(),
    const GroupInfoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bài tập nhóm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.translate),
              label: 'Dịch',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alarm),
              label: 'Báo thức',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Thông tin nhóm',
            ),
          ],
        ),
      ),
    );
  }
}
