import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'screen_toolbar.dart';

export 'reference_editor.dart';

class CompareScreen extends StatefulWidget {
  final Uint8List original;
  final Uint8List edited;
  const CompareScreen({
    super.key,
    required this.original,
    required this.edited,
  });

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  double amount = 0.5;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Before / after'),
      actions: [
        ScreenToolbar(
          tools: [
            ScreenTool(
              ScreenAction.reset,
              label: 'Reset comparison',
              onPressed: amount == .5
                  ? null
                  : () => setState(() => amount = .5),
            ),
            ScreenTool.help(
              context,
              title: 'Before / after',
              message: 'Drag the slider to reveal the selected design over the original. Reset returns it to the centre. Crops or different camera viewpoints may not align exactly.',
            ),
          ],
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Slide to reveal the selected design against the original. Crops or changed camera angles will not align perfectly.',
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, bounds) {
                final width = bounds.maxWidth;
                const height = 420.0;
                return SizedBox(
                  height: height,
                  width: width,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(
                        widget.original,
                        fit: BoxFit.contain,
                        cacheWidth: 1600,
                      ),
                      ClipRect(
                        clipper: _FractionClipper(amount),
                        child: Image.memory(
                          widget.edited,
                          fit: BoxFit.contain,
                          cacheWidth: 1600,
                        ),
                      ),
                      Align(
                        alignment: Alignment(amount * 2 - 1, 0),
                        child: const VerticalDivider(
                          thickness: 3,
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Slider(
              value: amount,
              onChanged: (value) => setState(() => amount = value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [Text('Original'), Text('Selected design')],
            ),
          ],
        ),
      ),
    ),
  );
}

class _FractionClipper extends CustomClipper<Rect> {
  final double fraction;
  const _FractionClipper(this.fraction);
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  @override
  bool shouldReclip(covariant _FractionClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
