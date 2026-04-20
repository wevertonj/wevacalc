import 'dart:math';

import 'package:flutter/material.dart';

/// A display that renders each character individually with animations:
/// - New characters pop-in (width 0 → target, pushing others left)
/// - Changed characters roll (old slides up, new slides up from below)
/// - Includes a blinking cursor at the end
class AnimatedInputDisplay extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  final Color operatorColor;
  final bool multiline;

  const AnimatedInputDisplay({
    super.key,
    required this.text,
    this.fontSize = 48,
    this.fontWeight = FontWeight.w300,
    required this.textColor,
    required this.operatorColor,
    this.multiline = false,
  });

  @override
  State<AnimatedInputDisplay> createState() => _AnimatedInputDisplayState();
}

class _AnimatedInputDisplayState extends State<AnimatedInputDisplay> {
  final ScrollController _scrollController = ScrollController();
  List<_CharSlot> _slots = [];
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _slots = _buildSlots(widget.text, animate: false);
    _previousText = widget.text;
  }

  @override
  void didUpdateWidget(covariant AnimatedInputDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      setState(() {
        _slots = _diffAndBuildSlots(_previousText, widget.text);
        _previousText = widget.text;
      });
      _scrollToEnd();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // -- Diff logic --

  List<_CharSlot> _buildSlots(String text, {required bool animate}) {
    return [
      for (int i = 0; i < text.length; i++)
        _CharSlot(
          char: text[i],
          type: animate ? _AnimType.popIn : _AnimType.none,
        ),
    ];
  }

  List<_CharSlot> _diffAndBuildSlots(String oldText, String newText) {
    if (oldText.isEmpty) {
      return _buildSlots(newText, animate: true);
    }

    // Find common prefix
    int prefixLen = 0;
    final minLen = min(oldText.length, newText.length);
    while (prefixLen < minLen && oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    // Find common suffix (from remaining after prefix)
    int suffixLen = 0;
    final maxSuffix = minLen - prefixLen;
    while (suffixLen < maxSuffix &&
        oldText[oldText.length - 1 - suffixLen] ==
            newText[newText.length - 1 - suffixLen]) {
      suffixLen++;
    }

    final oldMiddleStart = prefixLen;
    final oldMiddleLen = oldText.length - suffixLen - prefixLen;

    final slots = <_CharSlot>[];

    for (int i = 0; i < newText.length; i++) {
      if (i < prefixLen || i >= newText.length - suffixLen) {
        // Common prefix or suffix — no animation
        slots.add(_CharSlot(char: newText[i], type: _AnimType.none));
      } else {
        final middleOffset = i - prefixLen;
        if (middleOffset < oldMiddleLen) {
          final oldChar = oldText[oldMiddleStart + middleOffset];
          if (oldChar != newText[i]) {
            slots.add(
              _CharSlot(
                char: newText[i],
                oldChar: oldChar,
                type: _AnimType.roll,
              ),
            );
          } else {
            slots.add(_CharSlot(char: newText[i], type: _AnimType.none));
          }
        } else {
          // Extra character — pop in
          slots.add(_CharSlot(char: newText[i], type: _AnimType.popIn));
        }
      }
    }

    return slots;
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.fontSize),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedSize, _) {
        return _buildContent(animatedSize);
      },
    );
  }

  Widget _buildContent(double fontSize) {
    final charWidgets = [for (final slot in _slots) _buildChar(slot, fontSize)];

    if (widget.multiline) {
      final tokenWidgets = _groupIntoTokens(charWidgets);

      return Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: tokenWidgets,
      );
    }

    final children = [...charWidgets];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChar(_CharSlot slot, double fontSize) {
    final isOperator = _isOperator(slot.char);
    final color = isOperator ? widget.operatorColor : widget.textColor;
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: widget.fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    switch (slot.type) {
      case _AnimType.popIn:
        return _PopInChar(key: slot.key, char: slot.char, style: style);
      case _AnimType.roll:
        return _RollingChar(
          key: slot.key,
          newChar: slot.char,
          oldChar: slot.oldChar!,
          style: style,
        );
      case _AnimType.none:
        return _charText(slot.char, style);
    }
  }

  static bool _isOperator(String char) {
    return char == '+' || char == '−' || char == '×' || char == '÷';
  }

  /// Groups individual character widgets into token rows so that Wrap
  /// only breaks between tokens (operators/spaces), never mid-number.
  List<Widget> _groupIntoTokens(List<Widget> charWidgets) {
    final tokens = <Widget>[];
    var currentGroup = <Widget>[];

    for (int i = 0; i < _slots.length; i++) {
      final char = _slots[i].char;
      if (char == ' ' || _isOperator(char)) {
        // Flush current number group
        if (currentGroup.isNotEmpty) {
          tokens.add(
            Row(mainAxisSize: MainAxisSize.min, children: currentGroup),
          );
          currentGroup = [];
        }
        // Operator/space as its own token
        tokens.add(charWidgets[i]);
      } else {
        currentGroup.add(charWidgets[i]);
      }
    }

    // Flush remaining group
    if (currentGroup.isNotEmpty) {
      tokens.add(Row(mainAxisSize: MainAxisSize.min, children: currentGroup));
    }

    return tokens;
  }
}

/// Renders a single character using RichText to avoid being found by
/// `find.text()` in widget tests (prevents ambiguity with keypad buttons).
Widget _charText(String char, TextStyle style) {
  return RichText(
    text: TextSpan(text: char, style: style),
    textDirection: TextDirection.ltr,
  );
}

// -- Data classes --

enum _AnimType { none, popIn, roll }

class _CharSlot {
  final String char;
  final String? oldChar;
  final _AnimType type;
  final UniqueKey key;

  _CharSlot({required this.char, this.oldChar, required this.type})
    : key = UniqueKey();
}

// -- Animated character widgets --

double _measureCharWidth(String char, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: char, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  return painter.width;
}

class _PopInChar extends StatelessWidget {
  final String char;
  final TextStyle style;

  const _PopInChar({super.key, required this.char, required this.style});

  @override
  Widget build(BuildContext context) {
    final targetWidth = _measureCharWidth(char, style);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return SizedBox(
          width: targetWidth * value,
          child: ClipRect(
            child: Align(
              alignment: Alignment.centerRight,
              widthFactor: 1.0,
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.5 + 0.5 * value.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: _charText(char, style),
    );
  }
}

class _RollingChar extends StatelessWidget {
  final String newChar;
  final String oldChar;
  final TextStyle style;

  const _RollingChar({
    super.key,
    required this.newChar,
    required this.oldChar,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final charWidth = _measureCharWidth(newChar, style);
    final charHeight = style.fontSize ?? 48;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: charWidth,
          height: charHeight * 1.2,
          child: ClipRect(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Old char slides up and fades out
                Transform.translate(
                  offset: Offset(0, -value * charHeight * 0.5),
                  child: Opacity(
                    opacity: 1.0 - value,
                    child: _charText(oldChar, style),
                  ),
                ),
                // New char slides up from below
                Transform.translate(
                  offset: Offset(0, (1.0 - value) * charHeight * 0.5),
                  child: Opacity(
                    opacity: value,
                    child: _charText(newChar, style),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
