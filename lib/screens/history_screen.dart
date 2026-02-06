import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/journal_entry.dart';
import '../viewmodels/history_view_model.dart';
import '../widgets/dotted_background.dart';
import '../widgets/history_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isListView = true;

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
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: GoogleFonts.syneMono().fontFamily,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _HistoryViewToggle(
                    isListView: _isListView,
                    onToggle: (isListView) {
                      setState(() => _isListView = isListView);
                    },
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
    if (!_isListView) {
      return Center(
        child: Text(
          'Calendar view coming soon',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: GoogleFonts.syneMono().fontFamily,
          ),
        ),
      );
    }

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
          onTapEntry: (entry) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HistoryEntryDetailScreen(entry: entry),
              ),
            );
          },
        );
      },
    );
  }

  List<_HistorySectionData> _groupEntries(List<JournalEntry> entries) {
    final Map<DateTime, List<JournalEntry>> grouped = {};
    for (final entry in entries) {
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
            entries: grouped[key]!
              ..sort((a, b) => b.entryDate.compareTo(a.entryDate)),
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

class _HistoryViewToggle extends StatelessWidget {
  const _HistoryViewToggle({
    required this.isListView,
    required this.onToggle,
  });

  final bool isListView;
  final void Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    const active = Color(0xFFFF6E5A);
    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: 'List View',
            isActive: isListView,
            activeColor: active,
            onTap: () => onToggle(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToggleButton(
            label: 'Calendar View',
            isActive: !isListView,
            activeColor: active,
            onTap: () => onToggle(false),
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: GoogleFonts.syneMono().fontFamily,
            ),
          ),
        ),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF2A2A2A),
              blurRadius: 0,
              offset: Offset(2, 2),
            ),
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: GoogleFonts.syneMono().fontFamily,
            ),
          ),
        ),
      ),
    );
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
          fontWeight: FontWeight.w700,
          fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a').format(entry.entryDate);
    final typeLabel = _typeLabel(entry.entryType);
    final typeColor = _typeColor(entry.entryType);

    return InkWell(
      onTap: onTap,
      child: HistoryCard(
        svgAsset: _historyCardAsset(entry.entryType),
        backgroundColor: const Color(0xFFFFF9F7),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: GoogleFonts.syneMono().fontFamily,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
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

class HistoryEntryDetailScreen extends StatelessWidget {
  const HistoryEntryDetailScreen({super.key, required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailTopBar(
                  title: _detailTitle(entry.entryType),
                  dateText:
                      'Today, ${DateFormat('d MMM').format(entry.entryDate)}',
                  onBack: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: Text(
                        entry.content,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          fontFamily: GoogleFonts.syneMono().fontFamily,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _detailTitle(String type) {
    switch (type) {
      case 'reflection':
        return 'Reflect - Filled';
      case 'rant':
        return 'Rant - Filled';
      case 'scribble':
        return 'Scribble - Filled';
      default:
        return 'Entry - Filled';
    }
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({
    required this.title,
    required this.dateText,
    required this.onBack,
  });

  final String title;
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
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: GoogleFonts.syneMono().fontFamily,
            ),
          ),
          const SizedBox(width: 6),
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
