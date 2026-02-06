import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/reflect/reflect_controller.dart';
import '../widgets/dotted_background.dart';

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
            const Positioned.fill(child: DottedBackground()),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
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
          dateText: 'Today · ${_dateLabel()}',
          onBack: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.isOffline || state.pendingSyncCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: GoogleFonts.syneMono().fontFamily,
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        state.prompt?.text ??
                            'No prompt selected. You can write freely.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          fontFamily: GoogleFonts.syneMono().fontFamily,
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
                          color: state.isLoading
                              ? Colors.black54
                              : const Color(0xFFFF6E5A),
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          fontFamily: GoogleFonts.syneMono().fontFamily,
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
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF2A2A2A),
                            blurRadius: 0,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: SvgPicture.asset('assets/cards/mic.svg'),
                      ),
                    ),
                    const Spacer(),
                    _ShadowButton(
                      onPressed: state.isSaving ? null : _endSession,
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
                          : Text(
                              'End Session',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontFamily: GoogleFonts.syneMono().fontFamily,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
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
                Text(
                  'You showed up for yourself today.\nThat takes courage',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                  ),
                ),
                const Spacer(),
                _ShadowButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Back to Home',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: GoogleFonts.syneMono().fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryField() {
    return TextField(
      controller: _entryController,
      scrollController: _entryScrollController,
      maxLines: null,
      expands: true,
      style: GoogleFonts.gochiHand(
        fontSize: 20,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: true,
        fillColor: Colors.transparent,
        hintText: 'Start typing here...',
        hintStyle: GoogleFonts.gochiHand(
          fontSize: 20,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: EdgeInsets.zero,
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
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: const Border(
          left: BorderSide(color: Colors.black, width: 2),
          right: BorderSide(color: Colors.black, width: 2),
          bottom: BorderSide(color: Colors.black, width: 2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
          Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: GoogleFonts.syneMono().fontFamily,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _ShadowButton extends StatelessWidget {
  const _ShadowButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: const Border(
          right: BorderSide(color: Colors.black, width: 1.5),
          bottom: BorderSide(color: Colors.black, width: 1.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF2A2A2A),
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Material(
          color: const Color(0xFFFF6E5A),
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 36,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Center(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: GoogleFonts.syneMono().fontFamily,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

