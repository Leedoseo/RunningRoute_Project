import 'package:flutter/material.dart';
import 'package:routelog_project/core/decoration/app_background.dart';
import 'package:routelog_project/features/stats/widgets/widgets.dart';
import 'package:routelog_project/core/utils/notifier_provider.dart';
import 'package:routelog_project/features/stats/state/stats_controller.dart';
import 'package:routelog_project/core/navigation/app_router.dart';
import 'package:routelog_project/core/data/repository/repo_registry.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});
  static const routeName = "/stats";

  @override
  Widget build(BuildContext context) {
    final ctrl = NotifierProvider.of<StatsController>(context);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("통계")),
      body: AppBackground(
        child: AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) {
            if (ctrl.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final isWeekly = ctrl.period == StatsPeriod.weekly;
            final values = ctrl.series;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // 탭 토글 (주간/월간) + 기간 이동
                Row(
                  children: [
                    SegmentChip(
                      label: "주간",
                      selected: isWeekly,
                      onTap: () => ctrl.setPeriod(StatsPeriod.weekly),
                    ),
                    const SizedBox(width: 8),
                    SegmentChip(
                      label: "월간",
                      selected: !isWeekly,
                      onTap: () => ctrl.setPeriod(StatsPeriod.monthly),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: "이전",
                      onPressed: ctrl.previous,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(ctrl.periodLabel, style: t.labelLarge),
                    IconButton(
                      tooltip: "다음",
                      onPressed: ctrl.next,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 요약 카드
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final tiles = [
                      SummaryCard(icon: Icons.route_rounded,  label: "총 거리",    value: ctrl.totalDistanceText),
                      SummaryCard(icon: Icons.timer_outlined, label: "총 시간",    value: ctrl.totalTimeText),
                      SummaryCard(icon: Icons.speed_rounded,  label: "평균 페이스", value: ctrl.avgPaceText),
                    ];

                    if (w < 380) {
                      return Column(
                        children: [
                          Row(children: [Expanded(child: tiles[0]), const SizedBox(width: 12), Expanded(child: tiles[1])]),
                          const SizedBox(height: 12),
                          tiles[2],
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(child: tiles[0]),
                          const SizedBox(width: 12),
                          Expanded(child: tiles[1]),
                          const SizedBox(width: 12),
                          Expanded(child: tiles[2]),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 추세 차트
                TrendCard(
                  title: "러닝 추세",
                  subtitle: isWeekly ? "일별 거리(km)" : "일별 거리(km)",
                  periodLabel: ctrl.periodLabel,
                  values: values,
                  xDivisions: isWeekly ? 7 : 6,
                ),
                const SizedBox(height: 16),

                // 세션 요약
                Text("세션 요약", style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),

                if (ctrl.sessions.isEmpty)
                  Text("해당 기간에 세션이 없어요.", style: t.bodySmall)
                else
                  ...List.generate(ctrl.sessions.length, (i) {
                    final s = ctrl.sessions[i];
                    final dateStr = "${s.startedAt.year}-${s.startedAt.month.toString().padLeft(2, '0')}-${s.startedAt.day.toString().padLeft(2, '0')}";
                    final km = s.distanceMeters / 1000.0;
                    final distanceText = km >= 10 ? '${km.toStringAsFixed(0)} km' : '${km.toStringAsFixed(2)} km';
                    final pace = s.avgPaceSecPerKm;
                    final paceText = pace == null ? '-' : "${(pace ~/ 60)}'${(pace % 60).round().toString().padLeft(2, '0')}\"/km";
                    final meta = "$distanceText · ${_fmtDurShort(s.movingTime)} · $paceText";

                    return Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                      child: Dismissible(
                        key: ValueKey('stats_session_${s.id}'),
                        direction: DismissDirection.endToStart,
                        background: _dismissBg(context),
                        confirmDismiss: (_) async {
                          final ok = await _confirmDelete(context, s.title);
                          if (ok != true) return false;

                          final repo = RepoRegistry.I.routeRepo;
                          final backup = s;
                          try {
                            await repo.delete(s.id);
                            if (!context.mounted) return false;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('루트를 삭제했습니다.'),
                                action: SnackBarAction(
                                  label: '되돌리기',
                                  onPressed: () async {
                                    await repo.create(backup);
                                  },
                                ),
                              ),
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('삭제 실패: $e')),
                              );
                            }
                          }
                          return false; // watch()로 새로고침되므로 false
                        },
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(context, Routes.routeDetail(s.id)),
                          borderRadius: BorderRadius.circular(12),
                          child: SplitTile(title: dateStr, meta: meta),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _fmtDurShort(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Widget _dismissBg(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제하시겠어요?'),
        content: Text('‘$title’ 루트를 삭제하면 복구할 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
  }
}
