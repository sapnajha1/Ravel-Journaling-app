import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../data/local/local_store.dart';
import '../data/repositories/journal_repository.dart';
import '../viewmodels/history_view_model.dart';
import '../viewmodels/rantViewModel/rant_view_model.dart';
import '../viewmodels/recording/recording_view_model.dart';
import '../views/rantView/rant_recording_screen.dart';
import '../widgets/dotted_background.dart';
import '../widgets/home_bottom_bar.dart';
import 'history_screen.dart';
import 'home_tab.dart';
import 'profile_screen.dart';
import 'reflect_screen.dart';
import 'scribble_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static int _savedTabIndex = 0;
  late int _selectedIndex;
  late final Connectivity _connectivity;
  late final JournalRepository _journalRepository;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _savedTabIndex;
    _connectivity = Connectivity();
    _journalRepository = JournalRepository(
      Supabase.instance.client,
      LocalStore.journalBox(),
      _connectivity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final content = _selectedIndex == 0
        ? HomeTab(
            userEmail: widget.authController.userEmail ?? '',
            displayName: widget.authController.displayName,
            onOpenCard: _openCard,
          )
        : _selectedIndex == 1
            ? ChangeNotifierProvider(
                create: (_) => HistoryViewModel(
                  repository: _journalRepository,
                  connectivity: _connectivity,
                  userId: widget.authController.user?.id,
                ),
                child: HistoryScreen(journalRepository: _journalRepository),
              )
            : ProfileScreen(authController: widget.authController);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            Positioned.fill(child: content),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, math.max(18, bottomInset + 16)),
        child: HomeBottomBar(
          selectedIndex: _selectedIndex,
          onTap: (index) {
            _savedTabIndex = index;
            setState(() => _selectedIndex = index);
          },
        ),
      ),
    );
  }

  void _openCard(JournalCardType type) {
    Widget screen;
    switch (type) {
      case JournalCardType.rant:
        final recordingVM = RecordingViewModel(context);
        screen = MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: recordingVM),
            ChangeNotifierProvider(
              create: (_) => RantViewModel(
                recordingVM: recordingVM,
                journalRepository: _journalRepository,
              ),
            ),
          ],
          child: const RantRecordingScreen(),
        );
        break;
      case JournalCardType.scribble:
        screen = const ScribbleScreen();
        break;
      case JournalCardType.reflect:
        final reflectRecordingVM = RecordingViewModel(context);
        screen = ChangeNotifierProvider.value(
          value: reflectRecordingVM,
          child: const ReflectScreen(),
        );
        break;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

