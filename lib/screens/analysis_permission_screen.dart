import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/local/local_store.dart';
import '../design_system/app_colors.dart';
import '../viewmodels/recording/recording_view_model.dart';
import '../widgets/dotted_background.dart';
import '../widgets/shared_buttons.dart';
import 'reflect_screen.dart';

class AnalysisPermissionScreen extends StatefulWidget {
  const AnalysisPermissionScreen({super.key});

  @override
  State<AnalysisPermissionScreen> createState() =>
      _AnalysisPermissionScreenState();
}

class _AnalysisPermissionScreenState extends State<AnalysisPermissionScreen> {
  String _selected = LocalStore.analysisPreferenceAlways;

  Future<void> _confirm() async {
    final box = LocalStore.appSettingsBox();
    await box.put(LocalStore.analysisPreferenceKey, _selected);
    await box.put(LocalStore.analysisPermissionShownKey, true);

    if (!mounted) return;

    final reflectRecordingVM = RecordingViewModel(context);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: reflectRecordingVM,
          child: const ReflectScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          const Positioned.fill(child: DottedBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Journal can analyze reflections to share intelligent insights, mood and frequent topics. How would you like the analysis setting to be:',
                    style: GoogleFonts.syneMono(
                      fontSize: 16,
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _OptionCard(
                    label: 'Analyze my reflection everytime',
                    value: LocalStore.analysisPreferenceAlways,
                    groupValue: _selected,
                    onTap: (v) => setState(() => _selected = v),
                  ),
                  const SizedBox(height: 12),
                  _OptionCard(
                    label: 'Ask me everytime',
                    value: LocalStore.analysisPreferenceAsk,
                    groupValue: _selected,
                    onTap: (v) => setState(() => _selected = v),
                  ),
                  const SizedBox(height: 12),
                  _OptionCard(
                    label: 'Don\'t analyze my reflection',
                    value: LocalStore.analysisPreferenceNever,
                    groupValue: _selected,
                    onTap: (v) => setState(() => _selected = v),
                  ),
                  const Spacer(),
                  ShadowButton(
                    height: 48,
                    onPressed: _confirm,
                    child: Text(
                      'Confirm',
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
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onTap;

  bool get _isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: _isSelected ? AppColors.purpleLight : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isSelected ? AppColors.purpleBase : Colors.black,
            width: _isSelected ? 2 : 1.5,
          ),
          boxShadow: _isSelected
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 0,
                    offset: Offset(2, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.syneMono(
            fontSize: 15,
            fontWeight: _isSelected ? FontWeight.w600 : FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
