import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
// import 'package:flutter_painter/flutter_painter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:flutter_painter_v2/flutter_painter_extensions.dart';
import 'package:flutter_painter_v2/flutter_painter_pure.dart';

/// PaintScreen
///
/// Full-screen canvas using `flutter_painter` and `PainterController`.
/// Features:
/// - Freehand drawing with finger
/// - Brush color picker (4 colors)
/// - Brush size slider
/// - Eraser tool
/// - Undo / Redo
/// - Clear canvas
/// - Save drawing as PNG image
///
/// Note: This file is self-contained. Add `flutter_painter` and
/// `path_provider` to your `pubspec.yaml` if not already present.
class PaintScreen extends StatefulWidget {
  const PaintScreen({Key? key}) : super(key: key);

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  late final PainterController _controller;

  // UI state
  Color _selectedColor = Colors.black;
  double _brushSize = 6.0;
  bool _isEraser = false;

  // Preset colors for quick selection
  final List<Color> _colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
  ];

  @override
  void initState() {
    super.initState();

    // Initialize the PainterController with sensible defaults.
    _controller = PainterController();
    // Use the extension setters provided by flutter_painter for freestyle settings
    _controller.freeStyleStrokeWidth = _brushSize;
    _controller.freeStyleColor = _selectedColor;
    // Use a white canvas background for drawing.
    _controller.background = Colors.white.backgroundDrawable;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleEraser() {
    setState(() {
      _isEraser = !_isEraser;
      _controller.freeStyleMode = _isEraser ? FreeStyleMode.erase : FreeStyleMode.draw;
      if (!_isEraser) _controller.freeStyleColor = _selectedColor;
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
      _controller.freeStyleStrokeWidth = _brushSize;
    });
  }

  void _undo() {
    if (_controller.canUndo) _controller.undo();
  }

  void _redo() {
    if (_controller.canRedo) _controller.redo();
  }

  void _clearCanvas() {
    _controller.clearDrawables();
  }

  Future<void> _saveAsPng() async {
    try {
      // Render at the logical screen size so exported image matches display size
      final Size size = MediaQuery.of(context).size;
      final ui.Image image = await _controller.renderImage(size);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode image.');

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final Directory dir = await getTemporaryDirectory();
      final String filePath = '${dir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved drawing to ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving drawing: $e')),
      );
    }
  }

  Widget _buildColorPicker() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _colors.map((color) {
        final bool selected = color == _selectedColor && !_isEraser;
        return GestureDetector(
          onTap: () => _changeColor(color),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: selected ? 40 : 34,
            height: selected ? 40 : 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.grey.shade300,
                width: selected ? 3 : 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Undo',
                onPressed: _undo,
                color: Colors.white,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                tooltip: 'Redo',
                onPressed: _redo,
                color: Colors.white,
                icon: const Icon(Icons.redo),
              ),
              IconButton(
                tooltip: 'Clear',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear canvas?'),
                      content: const Text('This will remove all drawings permanently.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _clearCanvas();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                },
                color: Colors.white,
                icon: const Icon(Icons.clear),
              ),
              IconButton(
                tooltip: 'Save as PNG',
                onPressed: _saveAsPng,
                color: Colors.white,
                icon: const Icon(Icons.save),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorPicker(),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Eraser',
                onPressed: _toggleEraser,
                color: _isEraser ? Colors.orangeAccent : Colors.white,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                child: Row(
                  children: [
                    const Icon(Icons.brush, color: Colors.white),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 1.0,
                        max: 30.0,
                        divisions: 29,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                        label: _brushSize.toStringAsFixed(0),
                        onChanged: (value) {
                          _changeBrushSize(value);
                        },
                      ),
                    ),
                    Text(
                      _brushSize.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterPainter(
                controller: _controller,
              ),
            ),

            Positioned(
              top: 12,
              left: 12,
              child: ClipOval(
                child: Material(
                  color: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Center(
                child: _buildControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
