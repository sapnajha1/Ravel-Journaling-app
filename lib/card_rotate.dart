import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'journal_mode.dart';
import 'viewmodels/home_viewmodel.dart';
import 'views/rantView/rant_recording_screen.dart';


class AnimatedCard extends StatefulWidget {
  final String assetPath;
  final double angle;
  final JournalMode mode;

  const AnimatedCard({
    super.key,
    required this.assetPath,
    required this.angle,
    required this.mode, required double width,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(_controller);
    _rotateAnimation =
        Tween<double>(begin: widget.angle, end: widget.angle + 0.05)
            .animate(_controller);
  }

  void _onTap() async {
    await _controller.forward();
    await _controller.reverse();

    // Notify Provider
    final vm = context.read<HomeViewModel>();
    vm.onCardTap(widget.mode);

    // Navigate Rant flow only for now
    if (widget.mode == JournalMode.rant) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RantRecordingScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coming soon 🚧')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: _onTap,
              child: SvgPicture.asset(
                widget.assetPath,
                width: MediaQuery.of(context).size.width * 0.78,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
