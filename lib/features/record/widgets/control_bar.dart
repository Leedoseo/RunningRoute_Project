import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  const ControlBar({
    super.key,
    required this.onStart,
    required this.onPause,
    required this.onStop,
    this.buttonHeight = 72, // ← 높이 조절 파라미터 (기본: 기존 크기)
  });

  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onStop;
  final double buttonHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 버튼 공통 스타일 (높이를 최소 높이로 강제)
    ButtonStyle _filled(double h) => FilledButton.styleFrom(
      minimumSize: Size.fromHeight(h),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    ButtonStyle _outlined(double h) => OutlinedButton.styleFrom(
      minimumSize: Size.fromHeight(h),
      padding: EdgeInsets.zero,
      side: BorderSide(color: cs.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    ButtonStyle _elevated(double h) => ElevatedButton.styleFrom(
      minimumSize: Size.fromHeight(h),
      padding: EdgeInsets.zero,
      elevation: 0.5,
      backgroundColor: cs.errorContainer,
      foregroundColor: cs.onErrorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    const gap = SizedBox(width: 6);

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('시작'),
            ),
            style: _filled(buttonHeight),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPause,
            icon: const Icon(Icons.pause_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('일시정지'),
            ),
            style: _outlined(buttonHeight),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onStop,
            style: _elevated(buttonHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.stop_circle_rounded),
                  gap,
                  Text('종료'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
