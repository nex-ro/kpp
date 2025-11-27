import 'package:flutter/material.dart';
import 'login_page.dart';
import 'admin/home_page.dart';
import 'admin/about_me_page.dart';
import 'user/Pengajuan.dart';
import 'user/Approvement.dart';

class Homeuser extends StatefulWidget {
  const Homeuser({super.key, required this.title, required this.currentUserId});

  final String title;
  final String currentUserId; // Tambahkan parameter ini

  @override
  State<Homeuser> createState() => _CounterPageState();
}

class _CounterPageState extends State<Homeuser> {
  int _selectedIndex = 0;

  // List halaman yang akan ditampilkan
  List<Widget> get _pages => [
    const HomePage(),
    const PengajuanPage(),
    ApprovalPage(currentUserId: widget.currentUserId), // Tambahkan ApprovalPage
    const AboutMePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Pengajuan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.approval),
            label: 'Approval',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'About Me'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
