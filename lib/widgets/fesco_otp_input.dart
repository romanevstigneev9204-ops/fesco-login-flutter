import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/fesco_colors.dart';

/// Four OTP cells with underline; active cell uses Figma `#FF6900`.
class FescoOtpInput extends StatelessWidget {
  const FescoOtpInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;

  static const double _cellWidth = 48;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final code = controller.text;
    final focusIndex = code.length.clamp(0, 3);

    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final char = index < code.length ? code[index] : '';
              final isActive = index == focusIndex && code.length < 4;
              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : _gap),
                child: _OtpCell(
                  char: char,
                  showCursor: isActive && char.isEmpty,
                  underlineColor:
                      isActive ? FescoColors.otpAccent : FescoColors.textInverse,
                ),
              );
            }),
          ),
          Positioned.fill(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.char,
    required this.showCursor,
    required this.underlineColor,
  });

  final String char;
  final bool showCursor;
  final Color underlineColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: FescoOtpInput._cellWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 28,
            child: Center(
              child: showCursor
                  ? const Text(
                      '|',
                      style: TextStyle(
                        color: FescoColors.textInverse,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        fontFamily: 'Arial',
                      ),
                    )
                  : Text(
                      char,
                      style: const TextStyle(
                        color: FescoColors.textInverse,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        fontFamily: 'Arial',
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            color: underlineColor,
          ),
        ],
      ),
    );
  }
}
