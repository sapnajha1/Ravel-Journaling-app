import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as provider;

import '../data/models/journal_entry.dart';
import '../data/repositories/journal_repository.dart';
import '../design_system/app_colors.dart';
import '../features/reflect/reflect_controller.dart';
import '../viewmodels/history_view_model.dart';
import '../viewmodels/recording/recording_view_model.dart';
import '../widgets/dotted_background.dart';
import '../widgets/history_card.dart';
import '../widgets/recording_waveform.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.journalRepository});

  final JournalRepository journalRepository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F7),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      fontFamily: GoogleFonts.syneMono().fontFamily,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildBody(context, vm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HistoryViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Text(
          vm.errorMessage!,
          style: TextStyle(fontFamily: GoogleFonts.syneMono().fontFamily),
        ),
      );
    }

    if (vm.entries.isEmpty) {
      return Center(
        child: Text(
          'No entries yet',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: GoogleFonts.syneMono().fontFamily,
          ),
        ),
      );
    }

    final grouped = _groupEntries(vm.entries);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final section = grouped[index];
        return _HistorySection(
          label: _sectionLabel(section.date),
          entries: section.entries,
          onTapEntry: (entry) async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => provider.ChangeNotifierProvider(
                  create: (_) => RecordingViewModel(ctx),
                  child: HistoryEntryDetailScreen(
                    entry: entry,
                    journalRepository: widget.journalRepository,
                  ),
                ),
              ),
            );
            if (context.mounted) {
              context.read<HistoryViewModel>().refresh();
            }
          },
        );
      },
    );
  }

  List<_HistorySectionData> _groupEntries(List<JournalEntry> entries) {
    // Sort all entries by time (most recent first), independent of type
    final sortedEntries = List<JournalEntry>.from(entries)
      ..sort((a, b) {
        final ta = a.createdTimestamp ?? a.entryDate;
        final tb = b.createdTimestamp ?? b.entryDate;
        return tb.compareTo(ta);
      });

    final Map<DateTime, List<JournalEntry>> grouped = {};
    for (final entry in sortedEntries) {
      final day = DateTime(entry.entryDate.year, entry.entryDate.month,
          entry.entryDate.day);
      grouped.putIfAbsent(day, () => []);
      grouped[day]!.add(entry);
    }

    final keys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return keys
        .map(
          (key) => _HistorySectionData(
            date: key,
            entries: grouped[key]!,
          ),
        )
        .toList();
  }

  String _sectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;
    final monthName = DateFormat('MMMM').format(date);
    final label = '${_ordinal(date.day)} $monthName ${date.year}';
    return isToday ? 'Today, $label' : label;
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }
}

class _HistorySectionData {
  _HistorySectionData({required this.date, required this.entries});

  final DateTime date;
  final List<JournalEntry> entries;
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.label,
    required this.entries,
    required this.onTapEntry,
  });

  final String label;
  final List<JournalEntry> entries;
  final void Function(JournalEntry) onTapEntry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DatePill(label: label),
          const SizedBox(height: 10),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HistoryEntryCard(
                entry: entry,
                onTap: () => onTapEntry(entry),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          fontFamily: GoogleFonts.syneMono().fontFamily,
        ),
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.entry,
    required this.onTap,
  });

  final JournalEntry entry;
  final VoidCallback onTap;

  static String formatTimeOnly(DateTime dateTime) {
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return DateFormat('h:mm a').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final dateTimeForDisplay = entry.createdTimestamp ?? entry.entryDate;
    final timeLabel = formatTimeOnly(dateTimeForDisplay);
    final typeLabel = _typeLabel(entry.entryType);
    final typeColor = _typeColor(entry.entryType);

    return InkWell(
      onTap: onTap,
      child: HistoryCard(
        svgAsset: _historyCardAsset(entry.entryType),
        backgroundColor: const Color(0xFFFFF9F7),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: _typeTextColor(entry.entryType),
                      fontFamily: GoogleFonts.syneMono().fontFamily,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary,
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (entry.entryType == 'scribble')
              _ScribblePreview(contentBase64: entry.content)
            else
              Text(
                entry.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.normal,
                  fontFamily: GoogleFonts.syneMono().fontFamily,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'reflection':
        return 'Reflection';
      case 'rant':
        return 'Rant';
      case 'scribble':
        return 'Scribble';
      default:
        if (type.isEmpty) return 'Entry';
        return '${type[0].toUpperCase()}${type.substring(1)}';
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'reflection':
        return const Color(0xFFE6DDFF);
      case 'rant':
        return const Color(0xFFFFD6B5);
      case 'scribble':
        return const Color(0xFFD3F0D9);
      default:
        return const Color(0xFFF2F2F2);
    }
  }

  Color _typeTextColor(String type) {
    switch (type) {
      case 'reflection':
        return AppColors.purpleDark;
      case 'rant':
        return AppColors.releaseDark;
      case 'scribble':
        return AppColors.expressDark;
      default:
        return AppColors.textPrimary;
    }
  }

  String _historyCardAsset(String type) {
    switch (type) {
      case 'reflection':
        return 'assets/cards/reflect_history_bg.svg';
      case 'rant':
        return 'assets/cards/rant_history_bg.svg';
      case 'scribble':
        return 'assets/cards/reflect_history_bg.svg';
      default:
        return 'assets/cards/reflect_history_bg.svg';
    }
  }
}

class _ScribblePreview extends StatelessWidget {
  const _ScribblePreview({required this.contentBase64});

  final String contentBase64;

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    try {
      if (contentBase64.isNotEmpty) {
        final decoded = base64Decode(contentBase64);
        if (decoded.isNotEmpty) {
          imageBytes = Uint8List.fromList(decoded);
        }
      }
    } catch (_) {
      // Not valid base64 or not an image
    }
    if (imageBytes == null) {
      return Text(
        'Drawing',
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.normal,
          fontFamily: GoogleFonts.syneMono().fontFamily,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.memory(
        imageBytes,
        height: 56,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

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

/// Light purple waveform color for history detail (same as reflect).
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

  String _dateLabel(DateTime date) {
    final monthName = DateFormat('MMMM').format(date);
    return '${_ordinal(date.day)} $monthName ${date.year}';
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  String _todayOrDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(date.year, date.month, date.day);
    final monthName = DateFormat('MMM').format(date);
    final dayOrdinal = _ordinal(date.day);
    if (entryDay == today) {
      return 'Today · $dayOrdinal $monthName';
    }
    return '$dayOrdinal $monthName ${date.year}';
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
        dateLabel: _dateLabel(widget.entry.entryDate),
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
    } catch (_) {
      // Content may not be base64 (e.g. legacy or corrupt)
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
                    dateText: _todayOrDate(widget.entry.entryDate),
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
            ? ref.read(promptRepositoryProvider).getPromptById(widget.entry.promptId!)?.text
            : (widget.entry.title != null && widget.entry.title!.trim().isNotEmpty
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
                    dateText: _todayOrDate(widget.entry.entryDate),
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
                                      color: Colors.white.withOpacity(0.6),
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
                              // When recording: full-width waveform box with stop inside (same as reflect)
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
                                // When not recording: mic + Save Changes
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
