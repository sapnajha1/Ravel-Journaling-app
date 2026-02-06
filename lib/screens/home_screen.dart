import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../utils/date_formatters.dart';
import 'history_screen.dart';
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
  int _selectedIndex = 0;
  late final Connectivity _connectivity;
  late final JournalRepository _journalRepository;

  @override
  void initState() {
    super.initState();
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
            onOpenCard: _openCard,
          )
        : _selectedIndex == 1
            ? ChangeNotifierProvider(
                create: (_) => HistoryViewModel(
                  repository: _journalRepository,
                  connectivity: _connectivity,
                  userId: widget.authController.user?.id,
                ),
                child: const HistoryScreen(),
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
        padding: EdgeInsets.fromLTRB(16, 4, 16, math.max(6, bottomInset + 2)),
        child: _CustomBottomBar(
          selectedIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }

  void _openCard(_JournalCardType type) {
    Widget screen;
    switch (type) {
      case _JournalCardType.rant:
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
      case _JournalCardType.scribble:
        screen = const ScribbleScreen();
        break;
      case _JournalCardType.reflect:
        screen = const ReflectScreen();
        break;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

enum _JournalCardType { rant, scribble, reflect }

class _JournalCardData {
  const _JournalCardData({
    required this.type,
    required this.title,
    required this.description,
    required this.buttonText,
  });

  final _JournalCardType type;
  final String title;
  final String description;
  final String buttonText;
}

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.userEmail,
    required this.onOpenCard,
  });

  final String userEmail;
  final void Function(_JournalCardType) onOpenCard;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final List<_JournalCardData> _cards = const [
    _JournalCardData(
      type: _JournalCardType.rant,
      title: 'Rant',
      description:
          'Get it off your chest, feel lighter in 2 minutes - no filter, no judgment',
      buttonText: 'Let It Out Now',
    ),
    _JournalCardData(
      type: _JournalCardType.scribble,
      title: 'Scribble',
      description: "Express feelings you don't have names for",
      buttonText: 'Start Creating',
    ),
    _JournalCardData(
      type: _JournalCardType.reflect,
      title: 'Reflect',
      description: 'Turn messy thoughts into clear next steps',
      buttonText: 'Start Reflecting',
    ),
  ];

  int _frontIndex = 2;
  int _swipeDirection = 0; // -1 left, 1 right
  bool _isSwiping = false;

  String _displayName() {
    final email = widget.userEmail;
    if (email.isEmpty) return 'Roshan';
    final local = email.split('@').first;
    if (local.isEmpty) return 'there';
    return local[0].toUpperCase() + local.substring(1);
  }

  void _onSwipeEnd(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v.abs() < 200) return;
    final direction = v < 0 ? -1 : 1;

    setState(() {
      _frontIndex = direction == 1
          ? (_frontIndex + 1) % _cards.length
          : (_frontIndex + 2) % _cards.length;
      _swipeDirection = 0;
      _isSwiping = false;
    });
  }

  void _bringCardToFront(int index) {
    if (index == _frontIndex) return;
    setState(() {
      _frontIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Header
        Positioned(
          left: 20,
          right: 20,
          top: 16,
          child: _Header(
            dateText: 'Today · ${formatDayMonth(DateTime.now())}',
            greeting: 'Good Morning, ${_displayName()}!',
          ),
        ),
        // Card deck
        Positioned.fill(
          top: 150,
          bottom: 120,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final cardW = (w * 0.82).clamp(260.0, 380.0);
              final cardH = (h * 0.72).clamp(220.0, 320.0);
              final centerX = (w - cardW) / 2;
              final centerY = (h - cardH) / 2;

              final backLeft = (_frontIndex + 1) % 3;
              final backRight = (_frontIndex + 2) % 3;

              return _CardDeckStack(
                width: w,
                height: h,
                centerX: centerX,
                centerY: centerY,
                cardW: cardW,
                cardH: cardH,
                cards: _cards,
                frontIndex: _frontIndex,
                isSwiping: _isSwiping,
                swipeDirection: _swipeDirection,
                onSwipeEnd: _onSwipeEnd,
                onCardTap: _bringCardToFront,
                onButtonPressed: (type) => widget.onOpenCard(type),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CardDeckStack extends StatelessWidget {
  const _CardDeckStack({
    required this.width,
    required this.height,
    required this.centerX,
    required this.centerY,
    required this.cardW,
    required this.cardH,
    required this.cards,
    required this.frontIndex,
    required this.isSwiping,
    required this.swipeDirection,
    required this.onSwipeEnd,
    required this.onCardTap,
    required this.onButtonPressed,
  });

  final double width;
  final double height;
  final double centerX;
  final double centerY;
  final double cardW;
  final double cardH;
  final List<_JournalCardData> cards;
  final int frontIndex;
  final bool isSwiping;
  final int swipeDirection;
  final void Function(DragEndDetails) onSwipeEnd;
  final void Function(int) onCardTap;
  final void Function(_JournalCardType) onButtonPressed;

  @override
  Widget build(BuildContext context) {
    // Back cards peek out from sides
    final backLeft = (frontIndex + 1) % cards.length;
    final backRight = (frontIndex + 2) % cards.length;

    // Positions for back and front
    final backTop = centerY - 52;
    final frontTop = centerY + (cardH * 0.28);
    final sideOffset = 120.0;

    final leftIsAdvancing = isSwiping && swipeDirection == 1;
    final rightIsAdvancing = isSwiping && swipeDirection == -1;

    final frontSlot = _CardSlot(
      left: centerX,
      top: frontTop,
      rotation: 0.0,
      scale: 1.0,
    );
    final leftSlot = _CardSlot(
      left: centerX - sideOffset,
      top: backTop,
      rotation: -0.18,
      scale: 0.98,
    );
    final rightSlot = _CardSlot(
      left: centerX + sideOffset,
      top: backTop,
      rotation: 0.18,
      scale: 0.98,
    );

    final frontSlotIndex = leftIsAdvancing
        ? backLeft
        : rightIsAdvancing
            ? backRight
            : frontIndex;

    _CardSlot slotForIndex(int index) {
      if (leftIsAdvancing) {
        if (index == backLeft) return frontSlot;
        if (index == frontIndex) return rightSlot;
        return leftSlot;
      }
      if (rightIsAdvancing) {
        if (index == backRight) return frontSlot;
        if (index == frontIndex) return leftSlot;
        return rightSlot;
      }
      if (index == frontIndex) return frontSlot;
      if (index == backLeft) return leftSlot;
      return rightSlot;
    }

    Widget buildCard(int index) {
      final slot = slotForIndex(index);
      final isFront = index == frontSlotIndex;
      final data = cards[index];
      return _DeckCard(
        key: ValueKey('card-${data.type}'),
        left: slot.left,
        top: slot.top,
        width: cardW,
        height: cardH,
        rotation: slot.rotation,
        scale: slot.scale,
        data: data,
        isFront: isFront,
        onDragEnd: isFront ? onSwipeEnd : null,
        onTap: () => onCardTap(index),
        onButtonPressed: isFront ? () => onButtonPressed(data.type) : null,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        buildCard(backLeft),
        buildCard(backRight),
        buildCard(frontIndex),
      ],
    );
  }
}

class _CardSlot {
  const _CardSlot({
    required this.left,
    required this.top,
    required this.rotation,
    required this.scale,
  });

  final double left;
  final double top;
  final double rotation;
  final double scale;
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({
    super.key,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.rotation,
    required this.scale,
    required this.data,
    required this.isFront,
    required this.onDragEnd,
    required this.onTap,
    required this.onButtonPressed,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double rotation;
  final double scale;
  final _JournalCardData data;
  final bool isFront;
  final void Function(DragEndDetails)? onDragEnd;
  final VoidCallback onTap;
  final VoidCallback? onButtonPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onHorizontalDragEnd: onDragEnd,
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: rotation),
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final yTilt = value * 0.45;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(yTilt)
              ..rotateZ(value);
            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: _CardVisual(
            data: data,
            isFront: isFront,
            onButtonPressed: onButtonPressed,
          ),
        ),
      ),
    );
  }
}

class _AnimatedDeckCard extends StatelessWidget {
  const _AnimatedDeckCard({
    super.key,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.rotation,
    required this.scale,
    required this.data,
    required this.onTap,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double rotation;
  final double scale;
  final _JournalCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: rotation),
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final yTilt = value * 0.35;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(yTilt)
              ..rotateZ(value);
            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: child,
            );
          },
          child: Transform.scale(
            scale: scale,
            child: _CardVisual(
              data: data,
              isFront: false,
              onButtonPressed: null,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardVisual extends StatelessWidget {
  const _CardVisual({
    required this.data,
    required this.isFront,
    required this.onButtonPressed,
  });

  final _JournalCardData data;
  final bool isFront;
  final VoidCallback? onButtonPressed;

  String _cardSvg() {
    switch (data.type) {
      case _JournalCardType.rant:
        return 'assets/cards/card_rant.svg';
      case _JournalCardType.scribble:
        return 'assets/cards/card_reflect.svg';
      case _JournalCardType.reflect:
        return 'assets/cards/card_scribble.svg';
    }
  }

  String _iconSvg() {
    switch (data.type) {
      case _JournalCardType.rant:
        return 'assets/cards/cloud-storm-svgrepo-com 1.svg';
      case _JournalCardType.scribble:
        return 'assets/cards/scribble-svgrepo-com 1.svg';
      case _JournalCardType.reflect:
        return 'assets/cards/mirror-3.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              // soft floating shadow
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SvgPicture.asset(_cardSvg(), fit: BoxFit.fill),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: SvgPicture.asset(_iconSvg()),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: 240,
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.syneMono().fontFamily,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: onButtonPressed ?? () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Text(
                      data.buttonText,
                      style: TextStyle(
                        fontFamily: GoogleFonts.syneMono().fontFamily,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.dateText, required this.greeting});

  final String dateText;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6E5A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              // right-bottom border effect
              BoxShadow(
                color: Color(0xFF2A2A2A),
                blurRadius: 0,
                offset: Offset(3, 3),
              ),
              // soft shadow
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            dateText,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: GoogleFonts.syneMono().fontFamily,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          greeting,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: GoogleFonts.syneMono().fontFamily,
          ),
        ),
      ],
    );
  }
}

class _CustomBottomBar extends StatelessWidget {
  const _CustomBottomBar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          // right-bottom border effect
          BoxShadow(
            color: Color(0xFF2A2A2A),
            blurRadius: 0,
            offset: Offset(4, 4),
          ),
          // soft floating shadow
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.calendar_today_rounded,
            label: 'History',
            selected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.sentiment_satisfied_alt_rounded,
            label: 'Profile',
            selected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const active = Color(0xFFFF6E5A);
    const inactive = Colors.black87;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: selected
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                        maxHeight: 48,
                      ),
                      decoration: BoxDecoration(
                        color: active,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 18, color: Colors.white),
                          if (label.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  fontFamily: GoogleFonts.syneMono().fontFamily,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                )
              : Icon(icon, size: 22, color: inactive),
        ),
      ),
    );
  }
}

