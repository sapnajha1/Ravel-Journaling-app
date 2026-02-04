import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../features/reflect/reflect_controller.dart';

class ReflectScreen extends ConsumerStatefulWidget {
  const ReflectScreen({super.key});

  @override
  ConsumerState<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends ConsumerState<ReflectScreen> {
  final _entryController = TextEditingController();
  final _entryScrollController = ScrollController();

  bool _showTopFade = false;

  @override
  void initState() {
    super.initState();
    _entryScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _entryScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _entryScrollController.offset > 6;
    if (shouldShow != _showTopFade) {
      setState(() => _showTopFade = shouldShow);
    }
  }

  Future<void> _changePrompt() async {
    await ref.read(reflectControllerProvider.notifier).changePrompt();
  }

  Future<void> _endSession() async {
    final content = _entryController.text.trim();
    if (content.isEmpty) {
      _showSnack('Reflection content can\'t be empty.');
      return;
    }
    final saved = await ref.read(reflectControllerProvider.notifier).saveEntry(
          content: content,
        );
    if (saved) {
      _entryController.clear();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reflectControllerProvider);
    ref.listen<ReflectState>(
      reflectControllerProvider,
      (previous, next) {
        final error = next.errorMessage;
        if (error != null && error.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showSnack(error);
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DottedBackgroundPainter(
                  dotColor: const Color(0x18FF6E5A),
                  spacing: 18,
                  radius: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: state.showSaved
                  ? _buildSaved(context)
                  : _buildEditor(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context, ReflectState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          dateText: 'Today, ${_dateLabel()}',
          onBack: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 12),
        if (state.isOffline || state.pendingSyncCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              state.isOffline
                  ? 'Offline mode • ${state.pendingSyncCount} unsynced'
                  : '${state.pendingSyncCount} unsynced • syncing soon',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                state.prompt?.text ??
                    'No prompt selected. You can write freely.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: state.prompt == null ? null : _clearPrompt,
              icon: const Icon(Icons.close),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: state.isLoading ? null : _changePrompt,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/cards/change_prompt.svg',
                width: 14,
                height: 14,
                colorFilter: state.isLoading
                    ? const ColorFilter.mode(
                        Colors.black54,
                        BlendMode.srcIn,
                      )
                    : const ColorFilter.mode(
                        Color(0xFFFF6E5A),
                        BlendMode.srcIn,
                      ),
              ),
              const SizedBox(width: 6),
              Text(
                state.isLoading ? 'Loading prompt...' : 'Change Prompt',
                style: TextStyle(
                  color:
                      state.isLoading ? Colors.black54 : const Color(0xFFFF6E5A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Stack(
            children: [
              _buildEntryField(),
              if (_showTopFade)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 20,
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE6FF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: const Icon(Icons.mic, size: 16),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: state.isSaving ? null : _endSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6E5A),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: state.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text(
                        'End Session',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaved(BuildContext context) {
    return Column(
      children: [
        _TopBar(
          dateText: 'Reflect - Save',
          onBack: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE6FF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: const Icon(Icons.self_improvement, size: 28),
        ),
        const SizedBox(height: 16),
        const Text(
          'You showed up for yourself today.\nThat takes courage',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6E5A),
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Back to Home',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryField() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: _entryController,
        scrollController: _entryScrollController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Start typing here...',
        ),
      ),
    );
  }

  void _clearPrompt() {
    ref.read(reflectControllerProvider.notifier).clearPrompt();
  }

  String _dateLabel() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${now.day} ${months[now.month - 1]}';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.dateText, required this.onBack});

  final String dateText;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
          Text(
            dateText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _DottedBackgroundPainter extends CustomPainter {
  const _DottedBackgroundPainter({
    required this.dotColor,
    required this.spacing,
    required this.radius,
  });

  final Color dotColor;
  final double spacing;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBackgroundPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.radius != radius;
  }
}
