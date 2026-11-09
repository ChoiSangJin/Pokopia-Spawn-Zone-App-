import 'package:flutter/material.dart';

export '../models/content_source.dart';

class ContentFilter extends StatelessWidget {
  const ContentFilter({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.count,
  });
  final String selected;
  final ValueChanged<String> onChanged;
  final int Function(String) count;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final scope in const ['all', 'base', 'event', 'basin', 'update'])
          if (scope != 'update' || count(scope) > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(switch (scope) {
                  'event' => Icons.celebration_outlined,
                  'basin' => Icons.waves,
                  'update' => Icons.system_update,
                  _ => Icons.auto_awesome_mosaic_outlined,
                }, size: 18),
                label: Text(
                  '${switch (scope) {
                    'all' => '전체',
                    'base' => '기본',
                    'event' => '이벤트',
                    'basin' => '해저 · DLC',
                    _ => '무료 업데이트',
                  }} ${count(scope)}',
                ),
                selected: selected == scope,
                onSelected: (_) => onChanged(scope),
              ),
            ),
      ],
    ),
  );
}
