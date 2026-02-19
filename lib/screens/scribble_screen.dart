import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_painter/flutter_painter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design_system/app_colors.dart';
import '../features/scribble/scribble_controller.dart';
import '../utils/date_formatters.dart';
import '../widgets/dotted_background.dart';
import '../widgets/scribble_widgets.dart';

class ScribbleScreen extends ConsumerStatefulWidget {
  const ScribbleScreen({super.key});

  @override
  ConsumerState<ScribbleScreen> createState() => _ScribbleScreenState();
}

class _ScribbleScreenState extends ConsumerState<ScribbleScreen> {
  late final PainterController _controller;

  Color _selectedColor = Colors.black;
  double _brushSize = 6.0;
  double _eraserSize = 12.0;
  bool _isEraser = false;
  bool _penSelected = true; // Pen selected by default; color palette visible
  bool _showSavedConfirmation = false;

  final List<Color> _colors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
  ];

  @override
  void initState() {
    super.initState();
    _controller = PainterController();
    _controller.freeStyleStrokeWidth = _brushSize;
    _controller.freeStyleColor = _selectedColor;
    _controller.background = Colors.white.backgroundDrawable;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePen() {
    setState(() {
      if (_penSelected) {
        _penSelected = false;
        return;
      }
      _penSelected = true;
      _isEraser = false;
      _controller.freeStyleMode = FreeStyleMode.draw;
      _controller.freeStyleColor = _selectedColor;
      _controller.freeStyleStrokeWidth = _brushSize;
    });
  }

  void _selectEraser() {
    setState(() {
      _penSelected = false;
      _isEraser = true;
      _controller.freeStyleMode = FreeStyleMode.erase;
      _controller.freeStyleStrokeWidth = _eraserSize;
    });
  }

  void _changeColor(Color color) {
    setState(() {
      _selectedColor = color;
      _isEraser = false;
      _controller.freeStyleMode = FreeStyleMode.draw;
      _controller.freeStyleColor = color;
    });
  }

  void _changeBrushSize(double size) {
    setState(() {
      _brushSize = size;
      if (!_isEraser) _controller.freeStyleStrokeWidth = _brushSize;
    });
  }

  void _changeEraserSize(double size) {
    setState(() {
      _eraserSize = size;
      if (_isEraser) _controller.freeStyleStrokeWidth = _eraserSize;
    });
  }

  void _undo() {
    if (_controller.canUndo) _controller.undo();
  }

  void _redo() {
    if (_controller.canRedo) _controller.redo();
  }

  Future<void> _clearCanvas() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ClearCanvasDialog(
        onClear: () => Navigator.of(ctx).pop(true),
        onKeep: () => Navigator.of(ctx).pop(false),
      ),
    );
    if (confirm == true && mounted) {
      _controller.clearDrawables();
    }
  }

  Future<void> _saveScribble() async {
    if (_controller.value.drawables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add something to save')),
      );
      return;
    }

    final state = ref.read(scribbleControllerProvider);
    if (state.isSaving) return;

    try {
      final size = MediaQuery.of(context).size;
      final ui.Image image = await _controller.renderImage(size);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode image.');

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final String base64 = base64Encode(pngBytes);

      final saved = await ref.read(scribbleControllerProvider.notifier).saveScribble(
            contentBase64: base64,
            entryDate: DateTime.now(),
          );

      if (!mounted) return;
      if (saved) {
        setState(() => _showSavedConfirmation = true);
      } else {
        final err = ref.read(scribbleControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Failed to save')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scribbleState = ref.watch(scribbleControllerProvider);

    ref.listen<ScribbleState>(scribbleControllerProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(next.errorMessage!)),
            );
          }
        });
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_showSavedConfirmation) {
          Navigator.of(context).pop();
          return;
        }
        final navigator = Navigator.of(context);
        final shouldPop = await _onBackPressed();
        if (shouldPop) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9F7),
        body: Stack(
          children: [
            const Positioned.fill(
              child: DottedBackground(dotColor: Color(0x22FF6E5A)),
            ),
            SafeArea(
                  child: _showSavedConfirmation
                  ? _buildConfirmationScreen(context, scribbleState)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopBar(context, scribbleState),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1A000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FlutterPainter(
                                  controller: _controller,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBottomToolbar(context),
                      ],
                    ),
            ),
            if (scribbleState.isSaving && !_showSavedConfirmation)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationScreen(
      BuildContext context, ScribbleState scribbleState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.gesture,
            size: 56,
            color: AppColors.expressBase,
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your brain on paper.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Love it',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 44,
                        child: Center(
                          child: Text(
                            'Go to Home',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: GoogleFonts.syneMono().fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xFFFF6E5A),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showSavedConfirmation = false;
                          _controller.clearDrawables();
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 44,
                        child: Center(
                          child: Text(
                            'Scribble Again',
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ScribbleState scribbleState) {
    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final shouldPop = await _onBackPressed();
              if (shouldPop) navigator.pop();
            },
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          const Spacer(),
          Text(
            'Today · ${formatDayMonth(DateTime.now())}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: GoogleFonts.syneMono().fontFamily,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: scribbleState.isSaving ? null : _saveScribble,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/tick.svg',
                    width: 34,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primaryBase,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.syneMono().fontFamily,
                      color: AppColors.primaryBase,
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

  Future<bool> _onBackPressed() async {
    if (_controller.value.drawables.isEmpty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'Discard scribble?',
          style: TextStyle(
            fontSize: 24,
            fontFamily: GoogleFonts.syneMono().fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'You have unsaved changes. Save or discard?',
          style: TextStyle(
            fontSize: 16,
            fontFamily: GoogleFonts.syneMono().fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('Discard'),
            child: Text(
              'Discard',
              style: TextStyle(
                fontSize: 16,
                fontFamily: GoogleFonts.syneMono().fontFamily,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('Stay'),
            child: Text(
              'Stay',
              style: TextStyle(
                fontSize: 16,
                fontFamily: GoogleFonts.syneMono().fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
    return choice == 'Discard';
  }

  Widget _buildBottomToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_penSelected) _buildColorAndSliderRow(),
          if (_isEraser) _buildEraserSizeRow(),
          if (_penSelected || _isEraser)
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade700,
              indent: 0,
              endIndent: 0,
            ),
          if (_penSelected || _isEraser) const SizedBox(height: 12),
          _buildIconBar(),
        ],
      ),
    );
  }

  Widget _buildEraserSizeRow() {
    return Row(
      children: [
        Text(
          'Size',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: GoogleFonts.syneMono().fontFamily,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.grey.shade700,
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: Colors.white,
              overlayColor: Colors.transparent,
            ),
            child: Slider(
              value: _eraserSize,
              min: 4.0,
              max: 40.0,
              divisions: 36,
              onChanged: _changeEraserSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorAndSliderRow() {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: _colors.map((color) {
            final selected = color == _selectedColor && !_isEraser;
            return GestureDetector(
              onTap: () => _changeColor(color),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.grey.shade400,
                    width: selected ? 1 : 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.grey.shade700,
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: Colors.white,
              overlayColor: Colors.transparent,
            ),
            child: Slider(
              value: _brushSize,
              min: 1.0,
              max: 30.0,
              divisions: 29,
              onChanged: _changeBrushSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScribbleToolIcon(
          asset: 'assets/cards/pen.svg',
          selected: _penSelected,
          selectedColor: _penSelected ? _selectedColor : null,
          onTap: _togglePen,
        ),
        const SizedBox(width: 12),
        ScribbleToolIcon(
          asset: 'assets/cards/eraser.svg',
          selected: _isEraser,
          selectedColor: const Color(0xFFFFB74D),
          onTap: _selectEraser,
        ),
        const SizedBox(width: 28),
        ScribbleToolIcon(
          asset: 'assets/cards/undo.svg',
          selected: false,
          onTap: _undo,
        ),
        const SizedBox(width: 12),
        ScribbleToolIcon(
          asset: 'assets/cards/redo.svg',
          selected: false,
          onTap: _redo,
        ),
        const SizedBox(width: 12),
        ScribbleToolIcon(
          asset: 'assets/cards/broom.svg',
          selected: false,
          onTap: _clearCanvas,
        ),
      ],
    );
  }
}
