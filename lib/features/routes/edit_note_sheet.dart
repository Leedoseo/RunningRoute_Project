import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:routelog_project/features/routes/widgets/tag_selector.dart';

// 메모 편집
Future<void> showEditNoteSheet(
    BuildContext context, {
      String? initialText,
      List<String>? availableTags,
      Set<String>? initialSelectedTags,
    }) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true, // 키보드 올릴 때 높이 확보
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => EditNoteAndTagsSheet(
        initialText: initialText ?? '',
      availableTags: availableTags ??
        const ["러닝", "산책", "출근길", "퇴근길", "강변", "오르막", "내리막", "자전거길"],
      initialSelectedTags: initialSelectedTags ?? const {"러닝", "퇴근길"},
    ),
  );
}

class EditNoteAndTagsSheet extends StatefulWidget { // 실제 시트 위젯 (탭: 메모 / 태그)
  final String initialText;
  final List<String> availableTags;
  final Set<String> initialSelectedTags;

  const EditNoteAndTagsSheet({
    super.key,
    required this.initialText,
    required this.availableTags,
    required this.initialSelectedTags,
  });

  @override
  State<EditNoteAndTagsSheet> createState() => _EditNoteAndTagsSheetState();
}

class _EditNoteAndTagsSheetState extends State<EditNoteAndTagsSheet> {
  late final TextEditingController _controller;
  late final Set<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _selectedTags = {...widget.initialSelectedTags};
  }
  @override
  void dispose() {
  _controller.dispose();
  super.dispose();
  }

  void _notImplemented(String msg) { // StatefulWidget 내부에서만 스낵바가 필요해서 굳이 전역으로 뺄 필요가 없어서 위로 올림
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bottom  = MediaQuery.of(context).viewInsets.bottom; // 키보드 높이
    final sheetHeight = MediaQuery.of(context).size.height * 0.55; // 탭 본문 높이

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 그랩 핸들
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 12),

            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "편집",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: "닫기",
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 탭 헤더
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                tabs: [
                  Tab(text: "메모"),
                  Tab(text: "태그"),
                ],
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: sheetHeight,
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(), // 스와이프 금지
                children: [
                  // 탭1 : 메모
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      minLines: 4,
                      maxLines: 8,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: "루트에 대한 메모를 입력하세요",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)
                        ),
                      ),
                    ),
                  ),
                  // 탭2: 태그
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: SingleChildScrollView(
                      child: TagSelector(
                        tags: widget.availableTags,
                        selected: _selectedTags,
                        onToggle: (t) {
                          setState(() {
                            _selectedTags.contains(t)
                                ? _selectedTags.remove(t)
                                : _selectedTags.add(t);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 하단 액션
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text("취소"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        _notImplemented("적용은 나중에 연결");
                        Navigator.of(context).pop(); // 시트 닫기
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text("적용"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}