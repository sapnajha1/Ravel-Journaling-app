import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/models/journal_entry.dart';
import '../design_system/app_colors.dart';
import 'history_card.dart';

/// Data for one date section in history list.
class HistorySectionData {
  HistorySectionData({required this.date, required this.entries});

  final DateTime date;
  final List<JournalEntry> entries;
}

/// A dated section of history entries with a label.
class HistorySection extends StatelessWidget {
  const HistorySection({
    super.key,
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
          HistoryDatePill(label: label),
          const SizedBox(height: 10),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HistoryEntryCard(
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

/// Date label pill for history sections.
class HistoryDatePill extends StatelessWidget {
  const HistoryDatePill({super.key, required this.label});

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

/// Single journal entry card in history list.
class HistoryEntryCard extends StatelessWidget {
  const HistoryEntryCard({
    super.key,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              ScribblePreview(contentBase64: entry.content)
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

/// Thumbnail preview for scribble (base64) content in history list.
class ScribblePreview extends StatelessWidget {
  const ScribblePreview({super.key, required this.contentBase64});

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
    } catch (_) {}
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
