import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import 'paint_screen.dart';
import 'profile_screen.dart';

/// Main shell after login: bottom nav with Home, Calendar (Paint), Profile.
///
/// Shows logged-in user email on Home tab and handles session expiration
/// via [AuthController].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeTab(userEmail: widget.authController.userEmail ?? ''),
      const PaintScreen(),
      ProfileScreen(authController: widget.authController),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        elevation: 12,
        selectedItemColor: Colors.deepOrangeAccent,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sentiment_satisfied), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Home tab content: greeting with user email and journal cards.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.userEmail});

  final String userEmail;

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day}. ${months[now.month - 1]}';
  }

  String _displayName() {
    if (userEmail.isEmpty) return 'there';
    final local = userEmail.split('@').first;
    if (local.isEmpty) return 'there';
    return local;
  }

  Widget _buildTiltedCard({
    required Color color,
    required String title,
    double angle = 0,
    double top = 0,
    double left = 0,
  }) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: double.infinity,
        height: 260,
        margin: EdgeInsets.only(left: left, top: top, right: 24, bottom: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 8, offset: Offset(4, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text('Start Reflecting'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF7F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Today . ${_formattedDate()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Good Morning, ${_displayName()}!',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 28,
                  top: 40,
                  right: 28,
                  child: _buildTiltedCard(
                      color: Colors.greenAccent.shade200,
                      title: 'Scribble',
                      angle: -0.05,
                      top: 10,
                      left: 8),
                ),
                Positioned(
                  left: 20,
                  top: 80,
                  right: 20,
                  child: _buildTiltedCard(
                      color: Colors.orange.shade300,
                      title: 'Rant',
                      angle: -0.15,
                      top: 20,
                      left: 4),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 140,
                  child: _buildTiltedCard(
                      color: Colors.deepPurple.shade300,
                      title: 'Reflect',
                      angle: 0.02,
                      top: 0,
                      left: 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
