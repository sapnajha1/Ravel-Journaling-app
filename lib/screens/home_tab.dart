import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design_system/app_colors.dart';
import '../utils/date_formatters.dart';

enum JournalCardType { rant, scribble, reflect }

class JournalCardData {
  const JournalCardData({
    required this.type,
    required this.title,
    required this.description,
    required this.buttonText,
  });

  final JournalCardType type;
  final String title;
  final String description;
  final String buttonText;
}

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.userEmail,
    this.displayName = '',
    required this.onOpenCard,
  });

  final String userEmail;
  final String displayName;
  final void Function(JournalCardType) onOpenCard;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const List<JournalCardData> _cards = [
    JournalCardData(
      type: JournalCardType.rant,
      title: 'Rant',
      description: 'Get it off your chest, feel lighter in 2 minutes',
      buttonText: 'Let It Out Now',
    ),
    JournalCardData(
      type: JournalCardType.scribble,
      title: 'Scribble',
      description: "Express feelings you don't have names for",
      buttonText: 'Start Creating',
    ),
    JournalCardData(
      type: JournalCardType.reflect,
      title: 'Reflect',
      description: 'Turn messy thoughts into clear next steps',
      buttonText: 'Start Reflecting',
    ),
  ];

  int _frontIndex = 2;
  int _swipeDirection = 0;
  bool _isSwiping = false;

  String _displayName() {
    if (widget.displayName.trim().isNotEmpty) {
      return widget.displayName.trim();
    }
    final email = widget.userEmail;
    if (email.isEmpty) return 'there';
    final local = email.split('@').first;
    if (local.isEmpty) return 'there';
    return local[0].toUpperCase() + local.substring(1);
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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
    setState(() => _frontIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 20,
          right: 20,
          top: 16,
          child: _Header(
            dateText: 'Today · ${formatDayMonth(DateTime.now())}',
            greeting: '${_timeBasedGreeting()}, ${_displayName()}!',
          ),
        ),
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
  final List<JournalCardData> cards;
  final int frontIndex;
  final bool isSwiping;
  final int swipeDirection;
  final void Function(DragEndDetails) onSwipeEnd;
  final void Function(int) onCardTap;
  final void Function(JournalCardType) onButtonPressed;

  @override
  Widget build(BuildContext context) {
    final backLeft = (frontIndex + 1) % cards.length;
    final backRight = (frontIndex + 2) % cards.length;
    final backTop = centerY - 52;
    final frontTop = centerY + (cardH * 0.28);
    const sideOffset = 120.0;
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
  final JournalCardData data;
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

class _CardVisual extends StatelessWidget {
  const _CardVisual({
    required this.data,
    required this.isFront,
    required this.onButtonPressed,
  });

  final JournalCardData data;
  final bool isFront;
  final VoidCallback? onButtonPressed;

  String _cardSvg() {
    switch (data.type) {
      case JournalCardType.rant:
        return 'assets/cards/card_rant.svg';
      case JournalCardType.scribble:
        return 'assets/cards/card_reflect.svg';
      case JournalCardType.reflect:
        return 'assets/cards/card_scribble.svg';
    }
  }

  String _iconSvg() {
    switch (data.type) {
      case JournalCardType.rant:
        return 'assets/cards/cloud-storm-svgrepo-com 1.svg';
      case JournalCardType.scribble:
        return 'assets/cards/scribble-svgrepo-com 1.svg';
      case JournalCardType.reflect:
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
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
                    color: AppColors.textPrimary,
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
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
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
              BoxShadow(
                color: Color(0xFF2A2A2A),
                blurRadius: 0,
                offset: Offset(3, 3),
              ),
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
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: GoogleFonts.syneMono().fontFamily,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          greeting,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            fontFamily: GoogleFonts.syneMono().fontFamily,
          ),
        ),
      ],
    );
  }
}
