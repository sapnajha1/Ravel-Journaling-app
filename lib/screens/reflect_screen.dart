import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../design_system/app_colors.dart';
import '../features/reflect/reflect_controller.dart';
import '../viewmodels/recording/recording_view_model.dart';
import '../widgets/dotted_background.dart';
import '../widgets/recording_waveform.dart';

class ReflectScreen extends ConsumerStatefulWidget {
  const ReflectScreen({super.key});

  @override
  ConsumerState<ReflectScreen> createState() => _ReflectScreenState();
}

/// Light purple waveform color for reflect (matches reflect history card).
const Color _kReflectWaveformColor = Color(0xFFE6DDFF);

class _ReflectScreenState extends ConsumerState<ReflectScreen> {
  final _entryController = TextEditingController();
  final _titleController = TextEditingController();
  final _entryScrollController = ScrollController();

  bool _showTopFade = false;
  bool _wasRecordingOrTranscribing = false;

  @override
  void initState() {
    super.initState();
    _entryScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _titleController.dispose();
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
    final content = _entryController.text.trim();
    if (content.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => _ReflectAlert(
          title: 'Change Prompt',
          message:
              'Changing prompt will clear the current reflection to provide space for new reflection',
          primaryLabel: 'Confirm',
          secondaryLabel: 'Cancel',
          onPrimary: () => Navigator.of(ctx).pop(true),
          onSecondary: () => Navigator.of(ctx).pop(false),
        ),
      );
      if (confirm != true || !mounted) return;
      _entryController.clear();
    }
    await ref.read(reflectControllerProvider.notifier).changePrompt();
  }

  Future<void> _endSession() async {
    final content = _entryController.text.trim();
    if (content.isEmpty) {
      _showSnack('Add reflection');
      return;
    }
    final currentState = ref.read(reflectControllerProvider);
    final title = currentState.prompt == null
        ? (_titleController.text.trim().isEmpty ? null : _titleController.text.trim())
        : null;
    final saved = await ref.read(reflectControllerProvider.notifier).saveEntry(
          content: content,
          title: title,
        );
    if (saved) {
      _entryController.clear();
      _titleController.clear();
    }
  }

  Future<bool> _onBackPressed() async {
    final content = _entryController.text.trim();
    if (content.isEmpty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => _ReflectAlert(
          title: 'Changed Minds?',
          message:
              'Sometimes words don\'t come right away. Take your time to reflect or try later',
          primaryLabel: 'Stay',
          secondaryLabel: 'Discard',
          onPrimary: () => Navigator.of(ctx).pop('Stay'),
          onSecondary: () => Navigator.of(ctx).pop('Discard'),
        ),
      );
      if (choice == 'Discard') return true;
      return false;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => _ReflectAlert(
        title: 'Finished Reflecting?',
        message:
            'Save using End Session or leave without saving.',
        primaryLabel: 'Stay',
        secondaryLabel: 'Discard',
        onPrimary: () => Navigator.of(ctx).pop('Stay'),
        onSecondary: () => Navigator.of(ctx).pop('Discard'),
      ),
    );
    if (choice == 'Discard') return true;
    return false;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _syncEntryFromRecording() {
    final recordingVM = context.read<RecordingViewModel>();
    if (_entryController.text != recordingVM.displayText) {
      _entryController.text = recordingVM.displayText;
      _entryController.selection = TextSelection.collapsed(
        offset: _entryController.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reflectControllerProvider);
    final recordingVM = context.watch<RecordingViewModel>();
    final busy = recordingVM.isRecording || recordingVM.isTranscribing;
    if (busy) {
      _syncEntryFromRecording();
      _wasRecordingOrTranscribing = true;
    } else if (_wasRecordingOrTranscribing) {
      _syncEntryFromRecording();
      _wasRecordingOrTranscribing = false;
    }

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onBackPressed();
        if (!context.mounted) return;
        if (shouldPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
                child: state.showSaved
                    ? _buildSaved(context)
                    : _buildEditor(context, state),
              ),
            ),
          ],
        ),
        bottomSheet: state.showSaved
            ? null
            : _buildBottomBar(context, state),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ReflectState state) {
    final recordingVM = context.watch<RecordingViewModel>();
    final isRecording = recordingVM.isRecording;

    // When recording: full-width waveform box with stop button inside
    if (isRecording) {
      return Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF2A2A2A),
                  blurRadius: 0,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, constraints) => Center(
                      child: recordingWaveform(
                        recordingVM,
                        width: constraints.maxWidth,
                        barColor: _kReflectWaveformColor,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => recordingVM.stopRecording(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE53935),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF2A2A2A),
                          blurRadius: 0,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.stop_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // When not recording: mic + End Session as before
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                recordingVM.setSessionText(_entryController.text);
                recordingVM.startRecording();
              },
              child: DecoratedBox(
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
                        color: AppColors.textPrimary,
                        fontFamily: GoogleFonts.syneMono().fontFamily,
                      ),
                    ),
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
          onBack: () async {
            final shouldPop = await _onBackPressed();
            if (!context.mounted) return;
            if (shouldPop) Navigator.of(context).pop();
          },
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
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
                if (state.prompt != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          state.prompt!.text,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                            fontFamily: GoogleFonts.syneMono().fontFamily,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _clearPrompt,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            size: 24,
                            color: AppColors.textPrimary,
                          ),
                        ),
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
                ] else ...[
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      fontFamily: GoogleFonts.syneMono().fontFamily,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a title...',
                      hintStyle: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                        fontFamily: GoogleFonts.syneMono().fontFamily,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
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
                          state.isLoading ? 'Loading prompt...' : 'Add a Prompt',
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
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: Stack(
                    children: [
                      _buildEntryField(),
                      if (context.watch<RecordingViewModel>().isTranscribing)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.6),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black54,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Processing...',
                                    style: GoogleFonts.syneMono(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
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
                SvgPicture.asset(
                  'assets/reflect-completion.svg',
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  'YOU showed up for yourself today. That takes courage. Keep it up.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              height: 44,
                              child: Center(
                                child: Text(
                                  'Go to Home',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontFamily: GoogleFonts.syneMono().fontFamily,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ShadowButton(
                        height: 44,
                        onPressed: () async {
                          await ref.read(reflectControllerProvider.notifier).resetForNewReflection();
                        },
                        child: Text(
                          'Reflect Again',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: GoogleFonts.syneMono().fontFamily,
                          ),
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

  Widget _buildEntryField() {
    return TextField(
      controller: _entryController,
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

class _ReflectAlert extends StatelessWidget {
  const _ReflectAlert({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF6E5A),
                fontFamily: GoogleFonts.syneMono().fontFamily,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
                fontFamily: GoogleFonts.syneMono().fontFamily,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _WhiteOutlineButton(
                    onPressed: onSecondary,
                    child: Text(
                      secondaryLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: GoogleFonts.syneMono().fontFamily,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShadowButton(
                    onPressed: onPrimary,
                    child: Text(
                      primaryLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: GoogleFonts.syneMono().fontFamily,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
  const _ShadowButton({
    required this.onPressed,
    required this.child,
    this.height = 36,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFFFF6E5A),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: height,
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
    );
  }
}

class _WhiteOutlineButton extends StatelessWidget {
  const _WhiteOutlineButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
    );
  }
}

