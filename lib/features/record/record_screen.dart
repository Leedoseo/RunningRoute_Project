import 'package:flutter/material.dart';
import 'package:routelog_project/features/record/record_finish_sheet.dart';
import 'package:routelog_project/features/record/widgets/widgets.dart'
    show RecordStatusBadge, ControlBar;
import 'package:routelog_project/core/widgets/widgets.dart' show PermissionBanner;
import 'package:routelog_project/features/record/widgets/record_timer_gauge_card.dart';
import 'package:routelog_project/features/record/widgets/record_google_map.dart';
import 'package:routelog_project/core/utils/notifier_provider.dart';
import 'package:routelog_project/features/record/state/record_controller.dart';
import 'package:routelog_project/core/navigation/app_router.dart';
import 'package:routelog_project/core/data/repository/repo_registry.dart';
import 'package:routelog_project/features/record/services/record_saver.dart';
import 'package:routelog_project/core/data/models/models.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});
  static const routeName = "/record";

  @override
  Widget build(BuildContext context) {
    final ctrl = NotifierProvider.of<RecordController>(context);

    const double baseButtonHeight = 72;
    const double buttonHeight = 36;
    const double baseMapHeight = 220;
    final double mapHeight = baseMapHeight + (baseButtonHeight - buttonHeight);

    String durText(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      final s = d.inSeconds % 60;
      if (h > 0) {
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    String kmText(double m) {
      final km = m / 1000.0;
      return km >= 10 ? '${km.toStringAsFixed(0)} km' : '${km.toStringAsFixed(2)} km';
    }

    String paceText(double? secPerKm) {
      if (secPerKm == null || secPerKm.isNaN || secPerKm.isInfinite || secPerKm <= 0) return '-- /km';
      final m = secPerKm ~/ 60;
      final s = (secPerKm % 60).round().toString().padLeft(2, '0');
      return "$m'$s\"/km";
    }

    double progressFrom(Duration elapsed, {int goalMinutes = 40}) {
      final p = elapsed.inMinutes / goalMinutes;
      if (p.isNaN || p.isInfinite) return 0;
      return p.clamp(0, 1).toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("기록"),
        actions: [
          IconButton(
            onPressed: () => _snack(context, "설정/권한 안내 (미구현)"),
            icon: const Icon(Icons.info_outline),
            tooltip: "도움말",
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: ctrl,
          builder: (context, _) {
            final hasPermission = ctrl.permission == LocationPermissionState.granted;

            final statusLabel = () {
              switch (ctrl.status) {
                case RecordStatus.idle: return "대기중";
                case RecordStatus.recording: return "기록 중";
                case RecordStatus.paused: return "일시정지";
                case RecordStatus.finished: return "완료";
              }
            }();

            final durationText = durText(ctrl.elapsed);
            final distanceText = kmText(ctrl.distanceMeters);
            final pace = paceText(ctrl.paceSecPerKm);
            final progress = progressFrom(ctrl.elapsed);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    children: [
                      RecordStatusBadge(statusText: statusLabel),
                      const SizedBox(height: 8),
                      RecordGoogleMap(
                        key: const ValueKey('record_google_map'),
                        height: mapHeight,
                        path: ctrl.path,
                        followUser: true,
                      ),
                      if (!hasPermission ||
                          ctrl.permission == LocationPermissionState.serviceDisabled) ...[
                        const SizedBox(height: 8),
                        PermissionBanner(
                          title: !hasPermission
                              ? "위치 권한이 필요해요"
                              : "위치 서비스가 꺼져 있어요",
                          message: !hasPermission
                              ? "실시간 기록을 위해 위치 접근 권한을 허용해 주세요"
                              : "설정에서 위치 서비스를 켜 주세요",
                          actionLabel: "설정",
                          onAction: () => _snack(context, "권한/서비스 설정 화면 이동은 다음 단계에서 연결"),
                        ),
                      ],
                      const SizedBox(height: 8),
                      RecordTimerGaugeCard(
                        progress: progress,
                        durationText: durationText,
                        distanceText: distanceText,
                        paceText: pace,
                        heartRateText: "-- bpm",
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ControlBar(
                    buttonHeight: buttonHeight,
                    onStart: () async {
                      if (ctrl.status == RecordStatus.paused) {
                        await ctrl.resume();
                      } else if (ctrl.status == RecordStatus.recording) {
                        // noop
                      } else {
                        await ctrl.start();
                      }
                    },
                    onPause: () async {
                      if (ctrl.status == RecordStatus.recording) {
                        await ctrl.pause();
                      }
                    },
                    onStop: () async {
                      // 1) 기록 종료
                      await ctrl.stop();

                      // 2) 저장
                      final saver = RecordSaver(repo: RepoRegistry.I.routeRepo);
                      RouteLog saved;
                      try {
                        saved = await saver.saveFromController(ctrl);
                      } catch (e) {
                        if (!context.mounted) return;
                        _snack(context, "저장 실패: $e");
                        return;
                      }

                      // 3) 완료 시트
                      if (!context.mounted) return;
                      await showRecordFinishSheet(
                        context,
                        distanceText: distanceText,
                        durationText: durationText,
                        paceText: pace,
                      );
                      if (!context.mounted) return;

                      // 4) 상세로 이동(실제 id)
                      Navigator.pushNamed(context, Routes.routeDetail(saved.id));
                      // 레포 watch()로 홈은 자동 갱신됨
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
