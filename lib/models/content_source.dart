String contentScope(String? value) => switch (value) {
  'event' => 'event',
  'expansion-pass' => 'basin',
  'free-update' => 'update',
  _ => 'base',
};
String contentLabel(String? value) => switch (contentScope(value)) {
  'event' => '이벤트',
  'basin' => '해저 · 확장팩',
  'update' => '무료 업데이트',
  _ => '기본 콘텐츠',
};
