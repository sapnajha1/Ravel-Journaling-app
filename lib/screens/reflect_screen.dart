import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../data/local/local_store.dart';
import '../design_system/app_colors.dart';
import '../features/reflect/reflect_controller.dart';
import '../screens/entry_analysis_loading_screen.dart';
import '../screens/entry_analysis_screen.dart';
import '../screens/entry_completion_screen.dart';
import '../services/entry_analysis_service.dart';
import '../utils/date_formatters.dart';
import '../viewmodels/recording/recording_view_model.dart';
import '../widgets/dotted_background.dart';
import '../widgets/recording_waveform.dart';
import '../widgets/reflect_widgets.dart';
import '../widgets/shared_buttons.dart';

/// A completed turn: user's locked text + the AI question that followed.
class _DeepDiveTurn {
  final String userText;
  final String aiQuestion;
  const _DeepDiveTurn({required this.userText, required this.aiQuestion});
}

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
  final _scrollController = ScrollController();

  // Deep dive state
  List<_DeepDiveTurn> _deepDiveTurns = [];
  bool _isLoadingFollowUp = false;
  List<TextEditingController> _followUpControllers = [];

  bool _showTopFade = false;
  bool _wasRecordingOrTranscribing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _entryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entryController.dispose();
    _titleController.dispose();
    _scrollController.dispose();
    for (final c in _followUpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 6;
    if (shouldShow != _showTopFade) {
      setState(() => _showTopFade = shouldShow);
    }
  }

  /// Returns the currently active text controller
  /// (last follow-up controller, or the initial entry controller).
  TextEditingController get _activeController =>
      _followUpControllers.isNotEmpty ? _followUpControllers.last : _entryController;

  /// Builds the full accumulated content from all turns + current active text.
  String _buildAccumulatedContent() {
    final buf = StringBuffer();
    if (_deepDiveTurns.isEmpty) {
      buf.write(_activeController.text.trim());
    } else {
      // First turn: initial entry text is in _deepDiveTurns[0].userText
      // (locked when Go Deeper was first tapped)
      buf.write(_deepDiveTurns[0].userText);
      for (int i = 0; i < _deepDiveTurns.length; i++) {
        buf.write('\n\n[Follow-up: ${_deepDiveTurns[i].aiQuestion}]');
        if (i + 1 < _deepDiveTurns.length) {
          buf.write('\n${_deepDiveTurns[i + 1].userText}');
        } else {
          // Active input for the latest follow-up
          final activeText = _activeController.text.trim();
          if (activeText.isNotEmpty) buf.write('\n$activeText');
        }
      }
    }
    return buf.toString();
  }

  Future<void> _changePrompt() async {
    final content = _entryController.text.trim();
    if (content.isNotEmpty) {
      _entryController.clear();
      setState(() {
        _deepDiveTurns = [];
        for (final c in _followUpControllers) c.dispose();
        _followUpControllers = [];
      });
    }
    await ref.read(reflectControllerProvider.notifier).changePrompt();
  }

  Future<void> _goDeeper() async {
    final currentText = _activeController.text.trim();
    if (currentText.isEmpty) return;

    final accumulated = _buildAccumulatedContent();

    setState(() => _isLoadingFollowUp = true);

    final aiQuestion = await EntryAnalysisService().generateFollowUp(accumulated);

    if (!mounted) return;

    final newController = TextEditingController();
    newController.addListener(() => setState(() {}));

    setState(() {
      // For the first go deeper, lock the initial entry text
      if (_deepDiveTurns.isEmpty) {
        _deepDiveTurns.add(_DeepDiveTurn(
          userText: _entryController.text.trim(),
          aiQuestion: aiQuestion,
        ));
      } else {
        // Lock the previous follow-up response
        final prevText = _followUpControllers.last.text.trim();
        // Replace last turn with its locked response, then add new AI question
        // We track turns differently: each turn = (userText, aiQuestion)
        // After first go deeper: turns[0] = (initialEntry, aiQ1)
        // After second: turns[1] = (followUpResp1, aiQ2)
        _deepDiveTurns.add(_DeepDiveTurn(
          userText: prevText,
          aiQuestion: aiQuestion,
        ));
      }
      _followUpControllers.add(newController);
      _isLoadingFollowUp = false;
    });

    // Scroll to bottom and auto-focus new field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
      newController.selection = TextSelection.fromPosition(
        TextPosition(offset: newController.text.length),
      );
    });
    // Second scroll after keyboard animation finishes (~300ms) so the active
    // field is never hidden behind the keyboard.
    Timer(const Duration(milliseconds: 350), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _endSession() async {
    final finalContent = _deepDiveTurns.isEmpty
        ? _entryController.text.trim()
        : _buildAccumulatedContent();

    if (finalContent.isEmpty) {
      _showSnack('Add reflection');
      return;
    }
    final currentState = ref.read(reflectControllerProvider);
    final title = currentState.prompt == null
        ? (_titleController.text.trim().isEmpty ? null : _titleController.text.trim())
        : null;
    final savedEntry = await ref.read(reflectControllerProvider.notifier).saveEntry(
          content: finalContent,
          title: title,
        );
    if (savedEntry == null) return;

    if (!mounted) return;

    void clearJournalState() {
      _entryController.clear();
      _titleController.clear();
      setState(() {
        _deepDiveTurns = [];
        for (final c in _followUpControllers) c.dispose();
        _followUpControllers = [];
      });
    }

    final preference = LocalStore.appSettingsBox()
        .get(LocalStore.analysisPreferenceKey, defaultValue: LocalStore.analysisPreferenceAlways)
        as String;

    if (preference == LocalStore.analysisPreferenceNever) {
      clearJournalState();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EntryCompletionScreen()),
      );
      return;
    }

    if (preference == LocalStore.analysisPreferenceAsk) {
      // Show sheet while content is still visible, clear only after user decides.
      final shouldAnalyze = await _showAnalysisBottomSheet();
      clearJournalState();
      if (!mounted) return;
      if (shouldAnalyze != true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EntryCompletionScreen()),
        );
        return;
      }
    } else {
      // 'always' — clear before navigating away.
      clearJournalState();
    }

    if (!mounted) return;
    // 'always' or user confirmed analysis from bottom sheet
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EntryAnalysisLoadingScreen()),
    );

    final analysis = await EntryAnalysisService().analyzeEntry(finalContent, 'reflection');

    if (analysis.title.isNotEmpty || analysis.moods.isNotEmpty) {
      final moodStrings = analysis.moods
          .map((m) => m.emoji.isNotEmpty ? '${m.emoji} ${m.label}' : m.label)
          .toList();
      final updated = savedEntry.copyWith(
        title: analysis.title.isNotEmpty ? analysis.title : savedEntry.title,
        moods: moodStrings.isNotEmpty ? moodStrings : null,
        insight: analysis.insight.isNotEmpty ? analysis.insight : null,
        topics: analysis.topics.isNotEmpty ? analysis.topics : null,
      );
      await ref.read(journalRepositoryProvider).updateEntry(updated);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EntryAnalysisScreen(
          analysis: analysis,
          entryType: 'reflection',
        ),
      ),
    );
  }

  Future<bool?> _showAnalysisBottomSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Let Journal analyze mood, find insights and frequent topics in your reflection',
              style: GoogleFonts.syneMono(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: WhiteOutlineButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      'Don\'t analyze',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: GoogleFonts.syneMono().fontFamily,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadowButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'Analyze entry',
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _syncEntryFromRecording() {
    final recordingVM = context.read<RecordingViewModel>();
    final active = _activeController;
    if (active.text != recordingVM.displayText) {
      active.text = recordingVM.displayText;
      active.selection = TextSelection.collapsed(offset: active.text.length);
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
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        final hasContent = _entryController.text.trim().isNotEmpty ||
            _deepDiveTurns.isNotEmpty;
        if (didPop && hasContent) {
          _showSnack('Reflection discarded');
        }
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
                child: _buildEditor(context, state),
              ),
            ),
          ],
        ),
        bottomSheet: _buildBottomBar(context, state),
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

    // While fetching AI follow-up question
    if (_isLoadingFollowUp) {
      return Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(
            children: [
              _micButton(recordingVM),
              const Spacer(),
              Lottie.asset('assets/book_loader.json', width: 32, height: 32),
              const SizedBox(width: 8),
            ],
          ),
        ),
      );
    }

    final activeText = _activeController.text.trim();
    final hasActiveText = activeText.isNotEmpty;
    // Submit is available if the active field has text, OR the user has already
    // locked at least one turn (they've committed content and must always be
    // able to exit without being forced to answer a follow-up).
    final canSubmit = hasActiveText || _deepDiveTurns.isNotEmpty;

    if (!canSubmit) {
      // Nothing written yet at all — show mic only
      return Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(children: [_micButton(recordingVM)]),
        ),
      );
    }

    // Has submittable content: mic + (Go Deeper if active text) + Submit Journal
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Row(
          children: [
            _micButton(recordingVM),
            const SizedBox(width: 10),
            if (hasActiveText) ...[
              WhiteOutlineButton(
                onPressed: state.isSaving ? null : _goDeeper,
                child: Text(
                  'Go Deeper',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Spacer(),
            ShadowButton(
              onPressed: state.isSaving ? null : _endSession,
              child: state.isSaving
                  ? Lottie.asset('assets/book_loader.json', width: 24, height: 24)
                  : Text(
                      'Submit Journal',
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

  Widget _micButton(RecordingViewModel recordingVM) {
    return GestureDetector(
      onTap: () {
        recordingVM.setSessionText(_activeController.text);
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
    );
  }

  Widget _buildEditor(BuildContext context, ReflectState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReflectTopBar(
          dateText: 'Today · ${formatDayMonth(DateTime.now())}',
          onBack: () {
            final hasContent = _entryController.text.trim().isNotEmpty ||
                _deepDiveTurns.isNotEmpty;
            if (hasContent) _showSnack('Reflection discarded');
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPromptArea(state),
                const SizedBox(height: 12),
                Expanded(
                  child: Stack(
                    children: [
                      _buildConversationScroll(state),
                        if (context.watch<RecordingViewModel>().isTranscribing)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.6),
                            child: Center(
                              child: Lottie.asset(
                                'assets/book_loader.json',
                                width: 80,
                                height: 80,
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

  Widget _buildPromptArea(ReflectState state) {
    if (state.prompt != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  child: Icon(Icons.close, size: 24, color: AppColors.textPrimary),
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
                      ? const ColorFilter.mode(Colors.black54, BlendMode.srcIn)
                      : const ColorFilter.mode(Color(0xFFFF6E5A), BlendMode.srcIn),
                ),
                const SizedBox(width: 6),
                Text(
                  state.isLoading ? 'Loading prompt...' : 'Change Prompt',
                  style: TextStyle(
                    color: state.isLoading ? Colors.black54 : const Color(0xFFFF6E5A),
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      ? const ColorFilter.mode(Colors.black54, BlendMode.srcIn)
                      : const ColorFilter.mode(Color(0xFFFF6E5A), BlendMode.srcIn),
                ),
                const SizedBox(width: 6),
                Text(
                  state.isLoading ? 'Loading prompt...' : 'Add a Prompt',
                  style: TextStyle(
                    color: state.isLoading ? Colors.black54 : const Color(0xFFFF6E5A),
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  /// Builds the scrollable conversation column with initial entry + deep dive turns.
  Widget _buildConversationScroll(ReflectState state) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // If no deep dive yet, show the regular editable entry field
          if (_deepDiveTurns.isEmpty) _buildEntryField(controller: _entryController, autofocus: false),

          // Completed turns: locked user text → dot separator → AI question
          for (int i = 0; i < _deepDiveTurns.length; i++) ...[
            // First turn: initial user entry (locked)
            if (i == 0)
              _buildLockedText(_deepDiveTurns[0].userText),
            // Subsequent turns: follow-up response (locked)
            if (i > 0)
              _buildLockedText(_deepDiveTurns[i].userText),

            const SizedBox(height: 10),
            _buildDotSeparator(),
            const SizedBox(height: 8),

            // AI question
            Text(
              _deepDiveTurns[i].aiQuestion,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                fontFamily: GoogleFonts.syneMono().fontFamily,
              ),
            ),
            const SizedBox(height: 6),

            // Active follow-up input (only for the last turn)
            if (i == _deepDiveTurns.length - 1)
              _buildEntryField(
                controller: _followUpControllers[i],
                autofocus: true,
                hintText: 'write...',
              ),
          ],

          // Loading indicator while fetching next AI question
          if (_isLoadingFollowUp) ...[
            const SizedBox(height: 16),
            _buildDotSeparator(),
            const SizedBox(height: 8),
            Lottie.asset('assets/book_loader.json', width: 48, height: 48),
          ],

          // Bottom padding so content clears the bottom bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLockedText(String text) {
    return Text(
      text,
      style: GoogleFonts.gochiHand(
        fontSize: 20,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDotSeparator() {
    return Row(
      children: List.generate(
        12,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryField({
    required TextEditingController controller,
    bool autofocus = false,
    String hintText = 'Start typing here...',
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: null,
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
        hintText: hintText,
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
}
