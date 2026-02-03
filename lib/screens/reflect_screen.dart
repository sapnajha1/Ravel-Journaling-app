import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReflectScreen extends StatefulWidget {
  const ReflectScreen({super.key});

  @override
  State<ReflectScreen> createState() => _ReflectScreenState();
}

enum _ReflectView { edit, saved }

class _ReflectScreenState extends State<ReflectScreen> {
  static const _promptKey = 'reflect_prompt';
  static const _entryKey = 'reflect_entry';

  final _entryController = TextEditingController();
  final _entryScrollController = ScrollController();

  _ReflectView _view = _ReflectView.edit;
  String _prompt = "What's something that brought\nsmile to your face today?";
  bool _showTopFade = false;

  @override
  void initState() {
    super.initState();
    _loadLocal();
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

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrompt = prefs.getString(_promptKey);
    final savedEntry = prefs.getString(_entryKey);
    if (savedPrompt != null) _prompt = savedPrompt;
    if (savedEntry != null) _entryController.text = savedEntry;
    if (mounted) setState(() {});
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_promptKey, _prompt);
    await prefs.setString(_entryKey, _entryController.text.trim());
  }

  Future<void> _changePrompt() async {
    final controller = TextEditingController(text: _prompt.replaceAll('\n', ' '));
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Prompt'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Enter a new prompt',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _prompt = result);
      await _saveLocal();
    }
  }

  Future<void> _endSession() async {
    await _saveLocal();
    if (mounted) setState(() => _view = _ReflectView.saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEE4D4),
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
              child: _view == _ReflectView.edit
                  ? _buildEditor(context)
                  : _buildSaved(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          dateText: 'Today, ${_dateLabel()}',
          onBack: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 12),
        Text(
          _prompt,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _changePrompt,
          child: const Text(
            '✍ Change Prompt',
            style: TextStyle(
              color: Color(0xFFFF6E5A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
                          colors: [Color(0xFFFFF7F0), Color(0x00FFF7F0)],
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
              onPressed: _endSession,
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _entryController,
        scrollController: _entryScrollController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Start typing here...',
        ),
        onChanged: (_) => _saveLocal(),
      ),
    );
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
