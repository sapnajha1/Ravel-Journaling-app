import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../data/models/journal_entry.dart';
import '../data/repositories/journal_repository.dart';
import '../utils/date_formatters.dart';
import '../viewmodels/history_view_model.dart';
import '../viewmodels/recording/recording_view_model.dart';
import '../widgets/dotted_background.dart';
import '../widgets/history_list_widgets.dart';
import 'history_entry_detail_screen.dart';

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
      return Center(
        child: Lottie.asset('assets/book_loader.json', width: 80, height: 80),
      );
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
        return HistorySection(
          label: formatSectionLabel(section.date),
          entries: section.entries,
          onTapEntry: (entry) async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => ChangeNotifierProvider(
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

  List<HistorySectionData> _groupEntries(List<JournalEntry> entries) {
    final sortedEntries = List<JournalEntry>.from(entries)
      ..sort((a, b) {
        final ta = a.createdTimestamp ?? a.entryDate;
        final tb = b.createdTimestamp ?? b.entryDate;
        return tb.compareTo(ta);
      });

    final Map<DateTime, List<JournalEntry>> grouped = {};
    for (final entry in sortedEntries) {
      final day = DateTime(
        entry.entryDate.year,
        entry.entryDate.month,
        entry.entryDate.day,
      );
      grouped.putIfAbsent(day, () => []);
      grouped[day]!.add(entry);
    }

    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys
        .map(
          (key) => HistorySectionData(
            date: key,
            entries: grouped[key]!,
          ),
        )
        .toList();
  }
}
