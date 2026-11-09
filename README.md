# 포코피아 서식지 도감

별도 서버·외부 DB 없이 GitHub Raw JSON을 읽는 Flutter Android 포켓몬 서식지 도감입니다. Material 3, 반응형 2–6열 그리드, 이름/번호 검색, 타입 필터, Hero 상세 전환, 당겨서 갱신, 오류 재시도를 제공합니다.

## 개발 환경과 실행

Flutter **3.47.9 stable**(구현 시점 stable 브랜치), 해당 SDK의 Dart, Java 17, Android SDK 및 Flutter가 요구하는 SDK/NDK를 사용합니다. Android Studio의 SDK Manager에서 설치 후 Android 라이선스에 동의하세요. iOS 개발 환경은 필요하지 않습니다.

```sh
flutter --version
flutter doctor -v
flutter doctor --android-licenses
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d <android-device-id>
```

`flutter pub get` 및 첫 빌드가 Flutter Gradle wrapper와 로컬 SDK 경로를 준비합니다. `android/local.properties`가 없다는 오류가 나면 Flutter SDK가 정상 설치된 상태에서 `flutter build apk`를 실행하세요. `flutter create .`로 기존 파일을 덮어쓰지 마세요. 앱 ID는 `com.choisangjin.pokopia`입니다. 새 앱이므로 첫 의존성 해석에서 생성되는 `pubspec.lock`은 커밋하고 이후에는 `flutter pub get --enforce-lockfile`로 재현성을 유지하세요. 이 환경에서는 SDK 다운로드가 차단되어 아직 lockfile이 생성되지 않았습니다.

## 구조

```text
lib/
  main.dart                         # Provider 구성, 테마, 초기화 재시도
  models/pokemon.dart               # Pokemon, Habitat 및 null-safe 파싱
  services/catalog_service.dart     # HTTP, 시간 제한, 검증 후 JSON 캐시
  services/translations.dart        # upstream ES→EN 사전
  controllers/catalog_controller.dart # 로딩/오류/검색/타입 상태
  views/catalog_view.dart           # 반응형 lazy grid
  views/detail_view.dart            # 프로필/출현 조건/서식지/이벤트
  widgets/pokemon_image.dart        # Hero, 이미지 캐시, fallback
android/                            # Kotlin/Gradle 및 INTERNET 권한
assets/                             # 번역 사전, 데이터 저작권 고지
test/                               # 실제 응답 fixture, 오프라인·오류·UI 테스트
tool/verify_arm64.py                 # APK 내부 ABI 검사
.github/workflows/                  # 검증 빌드, 서명 릴리즈
```

의존성은 [pubspec.yaml](pubspec.yaml)에 선언했습니다: `provider`, `http`, `shared_preferences`, `cached_network_image`. 인터넷 권한은 [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)에 있습니다. API 키나 앱용 환경 변수는 필요하지 않습니다.

## 실제 데이터 계약

- JSON: `https://raw.githubusercontent.com/QuesoCaliente/pokopiapi/main/src/data/pokemon.json`
- 목록 응답은 **배열**이며, 각 항목이 상세 정보까지 포함합니다. GitHub Raw에는 `/api/v1/pokemon` Fastify 라우트가 없으므로 해당 경로를 호출하거나 백엔드를 실행하지 않습니다.
- `localNumber`는 `001`, `E007` 등 문자열입니다. 일반·이벤트·Basin 도감을 구분하는 번호와 slug를 합쳐 Hero ID를 구성합니다.
- `types`, `specialties`, `climates`, `timeAvailability`는 이름 객체 배열, `habitats`는 이름·희귀도 객체 배열, `spawnZones`는 문자열 배열입니다.
- 원본 이름은 영어이며 조건은 주로 스페인어입니다. upstream의 `translations/es.json`과 `en.json`에서 만든 번들 사전으로 영어 조건을 표시하고 번역이 없으면 원문을 유지합니다. 한국어 이름을 임의로 만들지 않습니다.
- null 이미지, 키/무게, 미확인 날씨·시간·지역 등은 fallback 또는 ‘미제공’으로 표시합니다. 상세 이미지도 upstream이 제공하는 URL을 사용하며 별도 고해상도 URL이나 전투 스탯을 만들어내지 않습니다.
- `availability`는 과거 이벤트 일정일 수도 있습니다. 표시된 기간이 현재 유효하다는 의미는 아닙니다. 원본 데이터의 정확성을 보증하지 않습니다.
- 이미지 호스트: `cdn.pokopiapi.com`. 실패 시 아이콘으로 대체합니다.

## 오프라인 동작

성공적으로 파싱한 **전체 JSON과 저장 시각**을 SharedPreferences의 단일 버전 키에 저장합니다. 재실행 시 캐시를 즉시 표시한 뒤 네트워크로 갱신합니다. 오프라인·HTTP 오류·잘못된 응답은 기존 캐시를 덮어쓰지 않습니다. 저장 실패는 사용자에게 알립니다. 캐시가 없는 첫 실행은 인터넷 연결이 필요합니다.

이미지는 `cached_network_image` 디스크 캐시를 사용하며 실제로 본 이미지부터 저장합니다. 이미지 캐시는 용량/보존기간에 따라 삭제될 수 있습니다. 이미지가 없어도 목록과 상세 텍스트는 탐색할 수 있습니다. 앱 데이터 삭제/제거 시 캐시도 삭제됩니다. 별도 DB, 계정, 서버는 없습니다.

## 바로 설치하는 APK 미리보기

`Deliver installable APK` 워크플로는 기능 브랜치 push 시 분석·테스트·ARM64 debug APK 빌드·서명/앱 이름 검사를 실행합니다. 모두 통과하면 PR 생성과 merge를 시도한 뒤 `v1.0.0-preview.1` GitHub 사전 릴리즈에 설치 가능한 APK와 SHA-256을 첨부합니다. GitHub 저장소 Settings → Actions → General에서 워크플로의 PR 생성 권한이 허용되어 있어야 합니다. 브랜치 보호 규칙은 우회하지 않습니다.

미리보기는 표준 Android debug 키로 서명한 **테스트용**이며, 정식 서명 비밀 값 없이 다운로드/설치할 수 있습니다. 다음 빌드의 서명이 다르면 기존 앱을 제거하고 다시 설치해야 할 수 있습니다. 실제 기기 실행 검증은 별도로 필요합니다. 앱 표시 이름은 **포코피아 서식지 도감**, 아이콘은 숲색 배경의 책·잎 모양입니다.

## arm64-v8a 전용 릴리즈

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
python3 tool/verify_arm64.py build/app/outputs/flutter-apk/app-release.apk
```

결과: `build/app/outputs/flutter-apk/app-release.apk`. Gradle에도 `abiFilters += "arm64-v8a"`를 설정하고 `disable-abi-filtering=true`로 Flutter 플러그인이 전체 ABI 기본값으로 덮어쓰지 않게 했습니다. 실제 ARM64 Android 기기에서 설치·검색·상세·비행기 모드 재실행을 확인하세요. x86 에뮬레이터용 APK는 생성하지 않습니다.

### 서명

서명 정보가 없으면 unsigned release를 만들며 설치/배포용으로 간주하지 않습니다. debug 키로 릴리즈를 서명하지 않습니다. 배포할 때는 본인 소유의 지속적으로 보관할 키스토어를 사용하세요.

로컬 `android/key.properties`(Git 제외):

```properties
storeFile=/absolute/path/to/release.keystore
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

값은 로컬에서만 입력하고 커밋하지 마세요. 키스토어와 비밀번호를 안전하게 백업해야 동일 앱 업데이트가 가능합니다.

### GitHub PR·Release

1. 기능 브랜치를 push하고 `main` 대상 PR을 만듭니다. `Verify Android`는 analyze, tests, unsigned ARM64 빌드, ABI 검사 후 검토용 artifact를 보관합니다.
2. CI 통과와 검토 후 PR을 merge합니다. 실패하거나 실행되지 않은 CI를 통과로 취급하지 않습니다.
3. GitHub의 `release` Environment에 `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` secrets를 설정합니다. 비밀 값을 채팅이나 저장소 파일에 넣지 마세요.
4. `main`에서 `Release Android` workflow를 실행하고 `tag`를 `v1.0.0`(pubspec 버전과 일치)으로 지정합니다. 테스트·ARM64 빌드·서명 검증이 통과해야 APK와 SHA-256 파일을 GitHub Release에 게시합니다. 기존 태그/릴리즈를 덮어쓰지 않습니다.
5. Play Store 배포는 이 워크플로 범위가 아닙니다. APK는 GitHub Release를 통한 직접 배포용입니다.

```sh
gh pr create --base main --head feat/pokopia-android --title 'Add offline Pokopia Android field guide' --body-file /path/to/pr-body.md
gh pr checks --watch
gh pr merge --squash --delete-branch
gh workflow run release.yml --ref main -f tag=v1.0.0
```

## 검증 상태

원격 데이터 계약과 fixture 365개 항목을 확인했습니다. GitHub Actions에서 Flutter 정적 분석, 자동 테스트 6개, Android debug/release APK 빌드가 실행됐습니다. ABI 검사에서 Flutter가 ARM64 외 아키텍처를 포함시키는 문제가 확인되어 `disable-abi-filtering=true`로 수정했습니다. 최종 ABI/서명/앱 이름 및 배포 결과는 해당 커밋의 Actions 실행과 Release에서 확인하세요. 실제 Android 기기 실행은 별도 검증이 필요합니다.

로컬 클라우드 머신은 SDK 다운로드(`storage.googleapis.com`)와 GitHub API(`api.github.com`)가 정책으로 차단되어 빌드/배포를 저장소의 GitHub Actions에서 수행합니다. 정식 서명 릴리즈에는 배포 서명 키가 필요하지만 테스트용 APK 미리보기는 별도 사용자 비밀 값 없이 생성합니다.

## 출처와 라이선스

[QuesoCaliente/pokopiapi](https://github.com/QuesoCaliente/pokopiapi), 참조 커밋 `893936af1adb51f6d2aab18aa8fa359fc401dd0a`. 원본 365개 항목은 테스트 fixture로만 포함되며 앱의 사전 탑재 데이터로 사용하지 않습니다. 파생 번역과 fixture에는 BSD-3-Clause 고지를 [assets/licenses/pokopiapi.txt](assets/licenses/pokopiapi.txt)에 보존했습니다. 앱 정보 → 라이선스에서도 확인할 수 있습니다. 프로젝트 자체 라이선스는 [LICENSE](LICENSE)를 따릅니다. Pokémon은 해당 권리자의 상표이며 이 앱은 비공식 팬 프로젝트입니다.
