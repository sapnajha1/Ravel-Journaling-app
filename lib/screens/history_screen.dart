import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/journal_entry.dart';
import '../viewmodels/history_view_model.dart';
import '../viewmodels/rantViewModel/rant_view_model.dart';
import '../views/home_view.dart';
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
    final size = MediaQuery.of(context).size;
    final scaleW = size.width / 360;
    final scaleH = size.height / 800;

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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'History',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
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
      return const Center(
        child: Text(
          'Calendar view coming soon',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(child: Text(vm.errorMessage!));
    }

    if (vm.entries.isEmpty) {
      return const Center(
        child: Text(
          'No entries yet',
          style: TextStyle(fontWeight: FontWeight.w600),
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
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
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
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
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

class HistoryEntryDetailScreen extends StatefulWidget {
  const HistoryEntryDetailScreen({super.key, required this.entry});

  final JournalEntry entry;

  @override
  State<HistoryEntryDetailScreen> createState() => _HistoryEntryDetailScreenState();
}

class _HistoryEntryDetailScreenState extends State<HistoryEntryDetailScreen> {

  late TextEditingController _controller;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry.content);

    // After first frame, scroll to end
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaleW = size.width / 360;
    final scaleH = size.height / 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(child: DottedBackground()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailTopBar(
                  entryDate: widget.entry.entryDate,
                  onBack: () => Navigator.of(context).pop(),
                  onDelete: () {
                    showDeleteRantDialog(context, widget.entry);
                  },
                ),

                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      reverse: false,
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),

                // Expanded(
                //   child: Padding(
                //     padding: const EdgeInsets.symmetric(horizontal: 16),
                //     child: SingleChildScrollView(
                //       child: Text(
                //         widget.entry.content,
                //         style: const TextStyle(
                //           fontSize: 14,
                //           height: 1.6,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 80),

                /// ===== FIXED BOTTOM BUTTONS =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// LEFT SVG
                      GestureDetector(
                        onTap: () {
                          // TODO: left button action
                        },
                        child: SvgPicture.asset(
                          'assets/Group 13(2).svg',
                          width: 48 * scaleW,
                          height: 48 * scaleH,
                        ),
                      ),

                      /// RIGHT SVG
                      GestureDetector(
                        onTap: () {
                          // TODO: right button action
                        },
                        child: SvgPicture.asset(
                          'assets/Frame 22(3).svg',
                          width: 154 * scaleW,
                          height: 48 * scaleH,
                        ),
                      ),
                    ],
                  ),
                ),


              ],
            ),
          ),
        ],
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
    required this.entryDate,
    required this.onBack,
    required this.onDelete,
    super.key,
  });

  final DateTime entryDate;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF201B18),
            offset: Offset(0, 5),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1️⃣ Back arrow
          GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 24,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Center(
              child: Text(
                'Today, ${_formatDateWithOrdinal(entryDate)}',
                style: GoogleFonts.syneMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: const Color(0xFF52443F),
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: onDelete,
            child: SvgPicture.asset(
              'assets/delete.svg',
              width: 20,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateWithOrdinal(DateTime date) {
    final day = date.day;
    final suffix = _getDaySuffix(day);
    final month = DateFormat('MMM').format(date); // Jan, Feb...
    return '$day$suffix $month';
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

void showDeleteRantDialog(
    BuildContext parentContext,
    JournalEntry entry,
    ) {
  final date = DateFormat('d MMM').format(entry.entryDate);

  // Dynamically determine the type label
  String typeLabel;
  switch (entry.entryType) {
    case 'reflection':
      typeLabel = 'Reflect';
      break;
    case 'rant':
      typeLabel = 'Rant';
      break;
    case 'scribble':
      typeLabel = 'Scribble';
      break;
    default:
      typeLabel = 'Entry';
  }

  showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// ===== TITLE =====
              Text(
                'Delete $typeLabel',
                style: GoogleFonts.syneMono(
                  color: const Color(0xFFFF7B6B),
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 12),

              /// ===== DESCRIPTION =====
              Text(
                'Please confirm if you want to delete $typeLabel dated $date',
                style: GoogleFonts.syneMono(
                  fontSize: 16,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  /// CANCEL
                  InkWell(
                    onTap: () => Navigator.pop(dialogContext),
                    child: SvgPicture.asset(
                      'assets/Frame 177.svg',
                      height: 36,
                    ),
                  ),

                  const SizedBox(width: 16),

                  /// DELETE
                  InkWell(
                    onTap: () async {
                      Navigator.pop(dialogContext);

                      // Determine correct ViewModel if needed
                      if (entry.entryType == 'rant') {
                        final rantVM = parentContext.read<RantViewModel>();
                        await rantVM.deleteRant(entry);
                      }
                      // Similarly, you can handle reflection/scribble ViewModels
                      // else if (entry.entryType == 'reflection') { ... }

                      Navigator.of(parentContext)
                          .pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                            (route) => false,
                      );

                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text('$typeLabel deleted'),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/Frame 22(2).svg',
                      height: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}



// void showDeleteRantDialog(
//     BuildContext parentContext,
//     JournalEntry entry,
//     ) {
//   final date = DateFormat('d MMM').format(entry.entryDate);
//
//   showDialog(
//     context: parentContext,
//     barrierDismissible: false,
//     builder: (dialogContext) {
//       return Dialog(
//         backgroundColor: Colors.transparent,
//         insetPadding: const EdgeInsets.symmetric(horizontal: 24),
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             border: Border.all(color: Colors.black, width: 1.5),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//
//               /// TITLE
//               Text(
//                 'Delete Rant',
//                 style: GoogleFonts.syneMono(
//                   color: const Color(0xFFFF7B6B),
//                   fontSize: 20,
//                 ),
//               ),
//
//               const SizedBox(height: 12),
//
//               /// DESCRIPTION
//               Text(
//                 'Please confirm if you want to delete rant dated $date',
//                 style: GoogleFonts.syneMono(
//                   fontSize: 16,
//                   height: 1.7,
//                 ),
//               ),
//
//               const SizedBox(height: 28),
//
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//
//                   /// CANCEL
//                   InkWell(
//                     onTap: () => Navigator.pop(dialogContext),
//                     child: SvgPicture.asset(
//                       'assets/Frame 177.svg',
//                       height: 36,
//                     ),
//                   ),
//
//                   const SizedBox(width: 16),
//
//                   /// DELETE
//                   InkWell(
//                     onTap: () async {
//
//                       Navigator.pop(dialogContext);
//
//                       final rantVM =
//                       parentContext.read<RantViewModel>();
//
//                       /// ⭐ PASS ENTRY HERE
//                       await rantVM.deleteRant(entry);
//
//                       /// Navigate
//                       Navigator.of(parentContext)
//                           .pushAndRemoveUntil(
//                         MaterialPageRoute(
//                           builder: (_) => const HistoryScreen(),
//                         ),
//                             (route) => false,
//                       );
//
//                       /// Snackbar
//                       ScaffoldMessenger.of(parentContext)
//                           .showSnackBar(
//                         const SnackBar(
//                           content: Text('Rant deleted'),
//                         ),
//                       );
//                     },
//                     child: SvgPicture.asset(
//                       'assets/Frame 22(2).svg',
//                       height: 36,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }
