import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/models/journal_entry.dart';
import '../data/repositories/journal_repository.dart';
import '../design_system/app_colors.dart';
import '../features/reflect/reflect_controller.dart';
import '../utils/date_formatters.dart';
import '../viewmodels/recording/recording_view_model.dart';
import '../widgets/dotted_background.dart';
import '../widgets/recording_waveform.dart';

/// Full-screen view for a single history entry (view/edit/delete).
class HistoryEntryDetailScreen extends ConsumerStatefulWidget {
  const HistoryEntryDetailScreen({
    super.key,
    required this.entry,
    required this.journalRepository,
  });

  final JournalEntry entry;
  final JournalRepository journalRepository;

  @override
  ConsumerState<HistoryEntryDetailScreen> createState() =>
      _HistoryEntryDetailScreenState();
}

const Color _kHistoryWaveformColor = Color(0xFFE6DDFF);

class _HistoryEntryDetailScreenState
    extends ConsumerState<HistoryEntryDetailScreen> {
  late final TextEditingController _contentController;
  bool _isSaving = false;
  bool _wasRecordingOrTranscribing = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.entry.entryType == 'scribble' ? '' : widget.entry.content,
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content cannot be empty')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = widget.entry.copyWith(content: content);
      await widget.journalRepository.updateEntry(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final typeLabel = _deleteTypeLabel(widget.entry.entryType);
    final typeLower = typeLabel.toLowerCase();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmDialog(
        title: 'Delete $typeLabel',
        typeLower: typeLower,
        dateLabel: formatFullDate(widget.entry.entryDate),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.journalRepository.deleteEntry(widget.entry);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  String _deleteTypeLabel(String type) {
    switch (type) {
      case 'reflection':
        return 'Reflection';
      case 'rant':
        return 'Rant';
      case 'scribble':
        return 'Scribble';
      default:
        return 'Entry';
    }
  }

  void _syncContentFromRecording() {
    final recordingVM = context.read<RecordingViewModel>();
    if (_contentController.text != recordingVM.displayText) {
      _contentController.text = recordingVM.displayText;
      _contentController.selection = TextSelection.collapsed(
        offset: _contentController.text.length,
      );
    }
  }

  Widget _buildScribbleDetail(BuildContext context) {
    Uint8List? imageBytes;
    try {
      final decoded = base64Decode(widget.entry.content);
      if (decoded.isNotEmpty) {
        imageBytes = Uint8List.fromList(decoded);
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HistoryDetailTopBar(
                    dateText: formatDetailDateLabel(widget.entry.entryDate),
                    onBack: () => Navigator.of(context).pop(),
                    onDelete: _confirmDelete,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: imageBytes != null
                          ? Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: Colors.white,
                                  child: Image.memory(
                                    imageBytes,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                'Unable to load scribble',
                                style: TextStyle(
                                  fontFamily: GoogleFonts.syneMono().fontFamily,
                                  color: AppColors.textSecondary,
                                ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entry.entryType == 'scribble') {
      return _buildScribbleDetail(context);
    }

    final isReflection = widget.entry.entryType == 'reflection';
    final String? promptOrTitleText = isReflection
        ? (widget.entry.promptId != null
            ? ref
                .read(promptRepositoryProvider)
                .getPromptById(widget.entry.promptId!)
                ?.text
            : (widget.entry.title != null &&
                    widget.entry.title!.trim().isNotEmpty
                ? widget.entry.title
                : null))
        : null;

    final recordingVM = context.watch<RecordingViewModel>();
    final busy = recordingVM.isRecording || recordingVM.isTranscribing;
    if (busy) {
      _syncContentFromRecording();
      _wasRecordingOrTranscribing = true;
    } else if (_wasRecordingOrTranscribing) {
      _syncContentFromRecording();
      _wasRecordingOrTranscribing = false;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HistoryDetailTopBar(
                    dateText: formatDetailDateLabel(widget.entry.entryDate),
                    onBack: () => Navigator.of(context).pop(),
                    onDelete: _confirmDelete,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (promptOrTitleText != null) ...[
                            Text(
                              promptOrTitleText,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                                color: AppColors.textPrimary,
                                fontFamily: GoogleFonts.syneMono().fontFamily,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Expanded(
                            child: Stack(
                              children: [
                                TextField(
                                  controller: _contentController,
                                  maxLines: null,
                                  expands: true,
                                  style: GoogleFonts.gochiHand(
                                    fontSize: 20,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                if (recordingVM.isTranscribing)
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
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.black54),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (recordingVM.isRecording) ...[
                                Expanded(
                                  child: Container(
                                    height: 56,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.black, width: 2),
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
                                            builder: (_, constraints) =>
                                                Center(
                                              child: recordingWaveform(
                                                recordingVM,
                                                width: constraints.maxWidth,
                                                barColor: _kHistoryWaveformColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              recordingVM.stopRecording(),
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFFE53935),
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 2),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0xFF2A2A2A),
                                                  blurRadius: 0,
                                                  offset: Offset(2, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                                Icons.stop_rounded,
                                                color: Colors.white,
                                                size: 24),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                GestureDetector(
                                  onTap: () {
                                    recordingVM.setSessionText(
                                        _contentController.text);
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
                                      child: SvgPicture.asset(
                                          'assets/cards/mic.svg'),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                _HistoryShadowButton(
                                  onPressed:
                                      _isSaving ? null : _saveChanges,
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<
                                                Color>(Colors.black),
                                          ),
                                        )
                                      : Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontFamily: GoogleFonts
                                                .syneMono()
                                                .fontFamily,
                                          ),
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({
    required this.title,
    required this.typeLower,
    required this.dateLabel,
  });

  final String title;
  final String typeLower;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x50000000),
              blurRadius: 12,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontFamily: GoogleFonts.syneMono().fontFamily,
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontFamily: GoogleFonts.syneMono().fontFamily,
                ),
                children: [
                  TextSpan(
                      text:
                          'Please confirm if you want to delete the $typeLower dated '),
                  TextSpan(
                    text: dateLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Cancel',
                    primary: false,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'Delete',
                    primary: true,
                    onPressed: () => Navigator.of(context).pop(true),
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

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: primary ? AppColors.primaryBase : Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF2A2A2A),
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primary ? Colors.white : AppColors.textPrimary,
                  fontFamily: GoogleFonts.syneMono().fontFamily,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryDetailTopBar extends StatelessWidget {
  const _HistoryDetailTopBar({
    required this.dateText,
    required this.onBack,
    required this.onDelete,
  });

  final String dateText;
  final VoidCallback onBack;
  final VoidCallback onDelete;

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
          IconButton(
            onPressed: onDelete,
            icon: SvgPicture.asset(
              'assets/delete.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Color(0xFFE53935),
                BlendMode.srcIn,
              ),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _HistoryShadowButton extends StatelessWidget {
  const _HistoryShadowButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 2),
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
                      color: AppColors.textPrimary,
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
