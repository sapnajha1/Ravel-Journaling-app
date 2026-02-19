import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/entry_analysis.dart';
import '../design_system/app_colors.dart';
import '../widgets/dotted_background.dart';
import '../widgets/shared_buttons.dart';

class EntryAnalysisScreen extends StatelessWidget {
  const EntryAnalysisScreen({
    super.key,
    required this.analysis,
    required this.entryType,
  });

  /// The AI-generated analysis for this entry.
  final EntryAnalysis analysis;

  /// Either 'reflection' or 'rant' — used to pick accent color and icon.
  final String entryType;

  bool get _isRant => entryType == 'rant';

  Color get _accentColor =>
      _isRant ? AppColors.releaseBase : AppColors.purpleBase;

  Color get _accentLightColor =>
      _isRant ? AppColors.releaseLight : AppColors.purpleLight;

  String get _iconAsset => _isRant
      ? 'assets/analysis-icons/rant-icon.svg'
      : 'assets/analysis-icons/reflect-icon.svg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Icon
                    SvgPicture.asset(
                      _iconAsset,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    // AI-generated title
                    if (analysis.title.isNotEmpty)
                      Text(
                        analysis.title,
                        style: GoogleFonts.gochiHand(
                          fontSize: 22,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 16),
                    // Mood chips
                    if (analysis.moods.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: analysis.moods
                            .map((mood) => _MoodChip(mood: mood))
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    // Divider
                    Divider(
                      color: AppColors.textTertiary.withValues(alpha: 0.4),
                      thickness: 1,
                    ),
                    const SizedBox(height: 24),
                    // Scrollable cards
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Insight card
                            if (analysis.insight.isNotEmpty)
                              _AnalysisCard(
                                label: 'Insight',
                                accentColor: _accentColor,
                                child: Text(
                                  analysis.insight,
                                  style: GoogleFonts.syneMono(
                                    fontSize: 14,
                                    height: 1.6,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            if (analysis.insight.isNotEmpty)
                              const SizedBox(height: 16),
                            // Topics card
                            if (analysis.topics.isNotEmpty)
                              _AnalysisCard(
                                label: 'Topics',
                                accentColor: _accentColor,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: analysis.topics
                                      .map(
                                        (t) => _TopicChip(
                                          label: t,
                                          accentColor: _accentColor,
                                          accentLightColor: _accentLightColor,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                    // CTA — centered, fixed width
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: SizedBox(
                          width: 200,
                          child: ShadowButton(
                            height: 44,
                            onPressed: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            child: Text(
                              'Go to Home',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: GoogleFonts.syneMono().fontFamily,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.mood});

  final MoodTag mood;

  @override
  Widget build(BuildContext context) {
    final label = mood.emoji.isNotEmpty
        ? '${mood.emoji} ${mood.label}'
        : mood.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textPrimary, width: 1.5),
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

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.label,
    required this.accentColor,
    required this.child,
  });

  final String label;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textPrimary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.syneMono(
              fontSize: 12,
              height: 1.4,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
