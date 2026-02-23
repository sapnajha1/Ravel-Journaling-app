import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/entry_analysis.dart';
import '../data/models/journal_entry.dart';
import '../data/repositories/journal_repository.dart';
import '../design_system/app_colors.dart';
import '../services/entry_analysis_service.dart';
import '../utils/date_formatters.dart';
import '../widgets/dotted_background.dart';

/// Full-screen read-only view for a single history entry.
class HistoryEntryDetailScreen extends ConsumerWidget {
  const HistoryEntryDetailScreen({
    super.key,
    required this.entry,
    required this.journalRepository,
  });

  final JournalEntry entry;
  final JournalRepository journalRepository;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entry.entryType == 'scribble') {
      return _ScribbleDetailView(entry: entry, journalRepository: journalRepository);
    }
    return _TextDetailView(entry: entry, journalRepository: journalRepository);
  }
}

// ---------------------------------------------------------------------------
// Scribble detail — unchanged behaviour
// ---------------------------------------------------------------------------

class _ScribbleDetailView extends StatelessWidget {
  const _ScribbleDetailView({required this.entry, required this.journalRepository});

  final JournalEntry entry;
  final JournalRepository journalRepository;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmDialog(
        title: 'Delete Scribble',
        typeLower: 'scribble',
        dateLabel: formatFullDate(entry.entryDate),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await journalRepository.deleteEntry(entry);
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    try {
      final decoded = base64Decode(entry.content);
      if (decoded.isNotEmpty) imageBytes = Uint8List.fromList(decoded);
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
                    dateText: formatDetailDateLabel(entry.entryDate),
                    onBack: () => Navigator.of(context).pop(),
                    onDelete: () => _confirmDelete(context),
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
                                  child: Image.memory(imageBytes, fit: BoxFit.contain),
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
}

// ---------------------------------------------------------------------------
// Text detail (Reflect / Rant) — read-only, new layout
// Layout: title → mood chips → ENTRY divider → content → WHAT WE NOTICED divider → insight + topics
// ---------------------------------------------------------------------------

class _TextDetailView extends StatefulWidget {
  const _TextDetailView({required this.entry, required this.journalRepository});

  final JournalEntry entry;
  final JournalRepository journalRepository;

  @override
  State<_TextDetailView> createState() => _TextDetailViewState();
}

class _TextDetailViewState extends State<_TextDetailView> {
  // When moods are not already stored, we fetch analysis lazily on first build.
  Future<EntryAnalysis>? _analysisFuture;

  @override
  void initState() {
    super.initState();
    if (widget.entry.moods == null) {
      _analysisFuture = EntryAnalysisService()
          .analyzeEntry(widget.entry.content, widget.entry.entryType);
    }
  }

  Future<void> _confirmDelete() async {
    final typeLabel = widget.entry.entryType == 'reflection' ? 'Reflection' : 'Rant';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmDialog(
        title: 'Delete $typeLabel',
        typeLower: typeLabel.toLowerCase(),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  bool get _isRant => widget.entry.entryType == 'rant';
  Color get _accentColor => _isRant ? AppColors.releaseBase : AppColors.purpleBase;
  Color get _accentLightColor => _isRant ? AppColors.releaseLight : AppColors.purpleLight;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

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
                    dateText: formatDetailDateLabel(entry.entryDate),
                    onBack: () => Navigator.of(context).pop(),
                    onDelete: _confirmDelete,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: entry.moods != null
                        // Analysis already saved — render everything synchronously.
                        ? _buildScrollContent(
                            context,
                            moodChipsWidget: _MoodChipsRow(moods: entry.moods!),
                            analysisWidget: (entry.insight?.isNotEmpty == true ||
                                    entry.topics?.isNotEmpty == true)
                                ? _FlatAnalysisBody(
                                    insight: entry.insight,
                                    topics: entry.topics,
                                    accentColor: _accentColor,
                                    accentLightColor: _accentLightColor,
                                  )
                                : null,
                          )
                        // No saved analysis — fetch lazily and drive both chips + body.
                        : FutureBuilder<EntryAnalysis>(
                            future: _analysisFuture,
                            builder: (context, snapshot) {
                              final analysis = snapshot.data;
                              final isLoading =
                                  snapshot.connectionState == ConnectionState.waiting;

                              Widget? chipsWidget;
                              if (isLoading) {
                                chipsWidget = Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                                    ),
                                  ),
                                );
                              } else if (analysis != null && analysis.moods.isNotEmpty) {
                                final moodStrings = analysis.moods
                                    .map((m) => m.emoji.isNotEmpty
                                        ? '${m.emoji} ${m.label}'
                                        : m.label)
                                    .toList();
                                chipsWidget = _MoodChipsRow(moods: moodStrings);
                              }

                              Widget? analysisWidget;
                              if (analysis != null &&
                                  (analysis.insight.isNotEmpty ||
                                      analysis.topics.isNotEmpty)) {
                                analysisWidget = _FlatAnalysisBody(
                                  insight: analysis.insight.isNotEmpty
                                      ? analysis.insight
                                      : null,
                                  topics: analysis.topics.isNotEmpty
                                      ? analysis.topics
                                      : null,
                                  accentColor: _accentColor,
                                  accentLightColor: _accentLightColor,
                                );
                              }

                              return _buildScrollContent(
                                context,
                                moodChipsWidget: chipsWidget,
                                analysisWidget: analysisWidget,
                              );
                            },
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

  Widget _buildScrollContent(
    BuildContext context, {
    Widget? moodChipsWidget,
    Widget? analysisWidget,
  }) {
    final entry = widget.entry;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (entry.title != null && entry.title!.isNotEmpty)
            Text(
              entry.title!,
              style: GoogleFonts.gochiHand(
                fontSize: 22,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          // Mood chips (or loading spinner)
          if (moodChipsWidget != null) ...[
            const SizedBox(height: 12),
            moodChipsWidget,
          ],
          const SizedBox(height: 20),
          // ENTRY divider
          _PillDivider(
            label: 'ENTRY',
            accentColor: _accentColor,
            accentLightColor: _accentLightColor,
          ),
          const SizedBox(height: 16),
          // Entry content (read-only)
          SelectableText(
            entry.content,
            style: GoogleFonts.gochiHand(
              fontSize: 20,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
          // WHAT WE NOTICED section — only if analysis data is available
          if (analysisWidget != null) ...[
            const SizedBox(height: 24),
            _PillDivider(
              label: 'WHAT WE NOTICED',
              accentColor: _accentColor,
              accentLightColor: _accentLightColor,
              icon: Icons.auto_awesome,
            ),
            const SizedBox(height: 16),
            analysisWidget,
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Flat analysis body — insight + topics without card wrappers
// ---------------------------------------------------------------------------

class _FlatAnalysisBody extends StatelessWidget {
  const _FlatAnalysisBody({
    required this.insight,
    required this.topics,
    required this.accentColor,
    required this.accentLightColor,
  });

  final String? insight;
  final List<String>? topics;
  final Color accentColor;
  final Color accentLightColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insight != null && insight!.isNotEmpty) ...[
          Text(
            'INSIGHT',
            style: GoogleFonts.syneMono(
              fontSize: 11,
              height: 1.4,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            insight!,
            style: GoogleFonts.gochiHand(
              fontSize: 16,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
        if (insight != null && insight!.isNotEmpty && topics != null && topics!.isNotEmpty)
          const SizedBox(height: 16),
        if (topics != null && topics!.isNotEmpty) ...[
          Text(
            'TOPICS',
            style: GoogleFonts.syneMono(
              fontSize: 11,
              height: 1.4,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topics!
                .map((t) => _TopicChip(
                      label: t,
                      accentColor: accentColor,
                      accentLightColor: accentLightColor,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mood chips row (from saved entry.moods or lazy analysis)
// ---------------------------------------------------------------------------

class _MoodChipsRow extends StatelessWidget {
  const _MoodChipsRow({required this.moods});

  final List<String> moods;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: moods
          .map(
            (mood) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textPrimary, width: 1.5),
              ),
              child: Text(
                mood,
                style: GoogleFonts.syneMono(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Pill divider — centered label pill with lines on each side
// ---------------------------------------------------------------------------

class _PillDivider extends StatelessWidget {
  const _PillDivider({
    required this.label,
    required this.accentColor,
    required this.accentLightColor,
    this.icon,
  });

  final String label;
  final Color accentColor;
  final Color accentLightColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.textTertiary.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: accentLightColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: accentColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.syneMono(
                  fontSize: 11,
                  height: 1.4,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: AppColors.textTertiary.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Topic chip
// ---------------------------------------------------------------------------

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.accentColor,
    required this.accentLightColor,
  });

  final String label;
  final Color accentColor;
  final Color accentLightColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentLightColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor, width: 1.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.syneMono(
          fontSize: 13,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delete confirm dialog
// ---------------------------------------------------------------------------

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
            BoxShadow(color: Color(0x50000000), blurRadius: 12, offset: Offset(2, 2)),
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
                      text: 'Please confirm if you want to delete the $typeLower dated '),
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
          BoxShadow(color: Color(0xFF2A2A2A), blurRadius: 0, offset: Offset(2, 2)),
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

// ---------------------------------------------------------------------------
// Top bar (date + back + delete)
// ---------------------------------------------------------------------------

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
          BoxShadow(color: Color(0x33000000), blurRadius: 0, offset: Offset(0, 2)),
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
              colorFilter: const ColorFilter.mode(Color(0xFFE53935), BlendMode.srcIn),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
