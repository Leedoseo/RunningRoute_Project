import 'package:flutter/material.dart';
import 'package:routelog_project/features/settings/widgets/widgets.dart';
import 'package:routelog_project/features/routes/route_import_sheet.dart';
import 'package:routelog_project/features/routes/route_export_sheet.dart';
import 'package:routelog_project/core/theme/theme_controller.dart';
import 'package:routelog_project/features/settings/state/settings_controller.dart';
import 'package:routelog_project/core/auth/auth_controller.dart';
import 'package:routelog_project/core/navigation/app_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  static const routeName = "/settings";

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _distanceUnit = "km";

  @override
  void initState() {
    super.initState();
    // 설정 로드 (비동기지만 화면 진입 시점에 최신값 반영)
    SettingsController.instance.load();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _themeModeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.system: return "시스템";
      case ThemeMode.light:  return "라이트";
      case ThemeMode.dark:   return "다크";
    }
  }

  String _accuracyLabel(GpsAccuracyOption a) {
    switch (a) {
      case GpsAccuracyOption.high:     return "높음(배터리↑)";
      case GpsAccuracyOption.balanced: return "보통(배터리↓)";
    }
  }

  Future<void> _pickThemeMode() async {
    final ctrl = ThemeController.instance;
    ThemeMode temp = ctrl.mode;

    final result = await showModalBottomSheet<ThemeMode>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHeader(ctx, "테마 모드"),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system, groupValue: temp, title: const Text("시스템"),
                    onChanged: (v) => setModalState(() => temp = v!),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light, groupValue: temp, title: const Text("라이트"),
                    onChanged: (v) => setModalState(() => temp = v!),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark, groupValue: temp, title: const Text("다크"),
                    onChanged: (v) => setModalState(() => temp = v!),
                  ),
                  _sheetButtons(
                    onCancel: () => Navigator.of(ctx).pop(),
                    onApply:  () => Navigator.of(ctx).pop(temp),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null && result != ThemeController.instance.mode) {
      ThemeController.instance.setMode(result);
      if (mounted) setState(() {});
      _snack("테마 모드: ${_themeModeLabel(result)}");
    }
  }

  Future<void> _pickDistanceUnit() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String temp = _distanceUnit;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHeader(ctx, "거리 단위"),
                  RadioListTile<String>(
                    value: "km", groupValue: temp, title: const Text("킬로미터 (km)"),
                    onChanged: (v) => setModalState(() => temp = v!),
                  ),
                  RadioListTile<String>(
                    value: "mi", groupValue: temp, title: const Text("마일 (mi)"),
                    onChanged: (v) => setModalState(() => temp = v!),
                  ),
                  _sheetButtons(
                    onCancel: () => Navigator.of(ctx).pop(),
                    onApply:  () => Navigator.of(ctx).pop(temp),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null && result != _distanceUnit) {
      setState(() => _distanceUnit = result);
      _snack("거리 단위 변경(목업): $_distanceUnit");
    }
  }

  Future<void> _pickGpsAccuracy() async {
    final s = SettingsController.instance;
    var temp = s.accuracy;

    final result = await showModalBottomSheet<GpsAccuracyOption>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHeader(ctx, "GPS 정확도"),
                RadioListTile<GpsAccuracyOption>(
                  value: GpsAccuracyOption.high,
                  groupValue: temp,
                  title: const Text("높음 (배터리 소모 ↑)"),
                  subtitle: const Text("실시간 경로 기록에 적합"),
                  onChanged: (v) => setModalState(() => temp = v!),
                ),
                RadioListTile<GpsAccuracyOption>(
                  value: GpsAccuracyOption.balanced,
                  groupValue: temp,
                  title: const Text("보통 (배터리 소모 ↓)"),
                  subtitle: const Text("도보/조깅 등 일반 상황"),
                  onChanged: (v) => setModalState(() => temp = v!),
                ),
                _sheetButtons(
                  onCancel: () => Navigator.of(ctx).pop(),
                  onApply:  () => Navigator.of(ctx).pop(temp),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result != null) {
      s.setAccuracy(result);
      if (mounted) setState(() {});
      _snack("GPS 정확도: ${_accuracyLabel(result)}");
    }
  }

  Future<void> _pickAutoPause() async {
    final s = SettingsController.instance;
    var enabled = s.autoPause;
    double speed = s.autoPauseMinSpeedKmh;
    int sec = s.autoPauseGraceSec;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHeader(ctx, "자동 일시정지"),
                SwitchListTile(
                  title: const Text("자동 일시정지 사용"),
                  value: enabled,
                  onChanged: (v) => setModalState(() => enabled = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("임계 속도"),
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        initialValue: speed.toStringAsFixed(1),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          suffixText: "km/h",
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final x = double.tryParse(v.replaceAll(',', '.'));
                          if (x != null) setModalState(() => speed = x.clamp(0.1, 5.0));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("유지 시간"),
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        initialValue: sec.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          suffixText: "초",
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final x = int.tryParse(v);
                          if (x != null) setModalState(() => sec = x.clamp(3, 30));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sheetButtons(
                  onCancel: () => Navigator.of(ctx).pop(),
                  onApply:  () => Navigator.of(ctx).pop({
                    'enabled': enabled,
                    'speed': speed,
                    'sec': sec,
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result != null) {
      s.setAutoPause(result['enabled'] as bool);
      s.setAutoPauseSpeed((result['speed'] as num).toDouble());
      s.setAutoPauseGrace(result['sec'] as int);
      if (mounted) setState(() {});
      _snack("자동 일시정지: ${s.autoPause ? "ON" : "OFF"} (${s.autoPauseMinSpeedKmh.toStringAsFixed(1)}km/h · ${s.autoPauseGraceSec}s)");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ThemeController.instance.mode;
    final s = SettingsController.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("설정")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const SettingsSectionTitle("표시 & 단위"),
          const SizedBox(height: 8),
          SettingsTile(
            leading: Icons.brightness_6_rounded,
            title: "테마 모드",
            subtitle: "시스템/라이트/다크 중 선택",
            trailing: Text(_themeModeLabel(themeMode), style: Theme.of(context).textTheme.labelLarge),
            onTap: _pickThemeMode,
          ),
          const SizedBox(height: 8),
          SettingsTile(
            leading: Icons.straighten_rounded,
            title: "거리 단위",
            subtitle: "러닝/루트의 거리 표기 단위",
            trailing: Text(_distanceUnit.toUpperCase(), style: Theme.of(context).textTheme.labelLarge),
            onTap: _pickDistanceUnit,
          ),

          const SizedBox(height: 24),
          const SettingsSectionTitle("기록 옵션"),
          const SizedBox(height: 8),
          SettingsTile(
            leading: Icons.gps_fixed_rounded,
            title: "GPS 정확도",
            subtitle: "현재: ${_accuracyLabel(s.accuracy)}",
            onTap: _pickGpsAccuracy,
          ),
          const SizedBox(height: 8),
          SettingsTile(
            leading: Icons.pause_circle_filled_rounded,
            title: "자동 일시정지",
            subtitle: "저속 감지 시 자동으로 일시정지",
            trailing: Switch(
              value: s.autoPause,
              onChanged: (v) {
                s.setAutoPause(v);
                setState(() {});
              },
            ),
            onTap: _pickAutoPause,
          ),

          const SizedBox(height: 24),
          const SettingsSectionTitle("백업 & 내보내기"),
          const SizedBox(height: 8),
          SettingsTile(
            leading: Icons.ios_share_rounded,
            title: "데이터 내보내기",
            subtitle: "GPX/JSON으로 내보내기 (미구현)",
            onTap: () => showRouteExportSheet(context),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            leading: Icons.file_download_rounded,
            title: "데이터 가져오기",
            subtitle: "GPX/JSON으로 가져오기 (미구현)",
            onTap: () => showRouteImportSheet(context, from: "설정"),
          ),

          const SizedBox(height: 24),
          const SettingsSectionTitle("계정"),
          const SizedBox(height: 8),
          SettingsTile(
            leading: Icons.logout_rounded,
            title: "로그아웃",
            subtitle: "현재 계정에서 로그아웃",
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AuthController.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    Routes.login,
                    (route) => false,
                  );
                }
              }
            },
          ),

          const SizedBox(height: 24),
          const SettingsSectionTitle("정보"),
          const SizedBox(height: 8),
          SettingsTile(
            leading: Icons.info_outline_rounded,
            title: "버전 정보",
            subtitle: "RouteLog 0.1.0 (mock)",
            onTap: () => _snack("버전 정보는 나중에 연결"),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            leading: Icons.description_outlined,
            title: "오픈소스 라이선스",
            subtitle: "사용한 라이브러리 목록 (미구현)",
            onTap: () => _snack("라이선스 화면은 나중에 연결"),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            leading: Icons.privacy_tip_outlined,
            title: "약관 및 개인정보처리방침",
            subtitle: "문서 보기 (미구현)",
            onTap: () => _snack("문서 화면은 나중에 연결"),
          ),
        ],
      ),
    );
  }

  // 공용: 시트 헤더/버튼
  Widget _sheetHeader(BuildContext ctx, String title) {
    return Row(
      children: [
        Text(title, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        IconButton(
          tooltip: "닫기",
          onPressed: () => Navigator.of(ctx).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _sheetButtons({required VoidCallback onCancel, required VoidCallback onApply}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text("취소"),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: onApply,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text("적용"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
