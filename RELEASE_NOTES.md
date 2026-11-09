포켓몬 이름을 한국어로 표시합니다. 예: Bulbasaur → 이상해씨.

- PokeAPI `pokemon-species/{전국도감번호}/` 응답의 `names[].language.name == ko` 이름 사용
- 목록·상세·한글/영문 검색 지원
- 공식 PokeAPI 한국어 기본 이름 탑재, 상세 화면에서 API 갱신 및 7일 캐시
- 네트워크 오류 시 저장된 한국어 이름 유지
- ARM64 release(AOT) 빌드로 APK 용량 축소; 포켓몬 이미지는 APK에 넣지 않고 필요할 때 내려받아 캐시

Assets의 `pokopia-habitat-guide-arm64-preview.apk`를 다운로드해 설치하세요. Android 7.0 이상 ARM64 기기용입니다.

이 APK는 release 모드로 최적화했지만 Android 개발용 키로 서명한 **테스트용 사전 릴리즈**입니다. 이전 미리보기와 서명이 다르면 기존 앱을 삭제한 뒤 설치해야 합니다. 삭제 시 기존 캐시도 지워집니다. 실제 기기 동작은 추가 확인이 필요합니다.
