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

`flutter pub get` 및 첫 빌드가 Flutter Gradle wrapper와 로컬 SDK 경로를 준비합니다. `android/local.properties`가 없다는 오류가 나면 Flutter SDK가 정상 설치된 상태에서 `flutter build apk`를 실행하세요. `flutter create .`로 기존 파일을 덮어쓰지 마세요. 앱 ID는 `com.choisangjin.pokopia`입니다. 새 앱이므로 첫 의존성 해석에서 생성되는 `pubspec.lock`은 커밋하고 이후에는 `flutter pub get --enforce-lockfile`로 재현성을 유지하세요. 앱용 `pubspec.lock`을 저장소에 포함하며 CI는 frozen 해석을 사용합니다.

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

의존성은 [pubspec.yaml](pubspec.yaml)에 선언했습니다: `provider`, `http`, `shared_preferences`, `cached_network_image`. 인터넷 권한은 [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)에 있습니다. API 키나 앱용 환경 변수는 필요하지 않습니다. 데이터 통신에는 `raw.githubusercontent.com`, `pokeapi.co`, `cdn.pokopiapi.com` HTTPS 접근이 필요합니다.

## 실제 데이터 계약

- JSON: `https://raw.githubusercontent.com/QuesoCaliente/pokopiapi/main/src/data/pokemon.json`
- 목록 응답은 **배열**이며, 각 항목이 상세 정보까지 포함합니다. GitHub Raw에는 `/api/v1/pokemon` Fastify 라우트가 없으므로 해당 경로를 호출하거나 백엔드를 실행하지 않습니다.
- `localNumber`는 `001`, `E007` 등 문자열입니다. 일반·이벤트·Basin 도감을 구분하는 번호와 slug를 합쳐 Hero ID를 구성합니다.
- `types`, `specialties`, `climates`, `timeAvailability`는 이름 객체 배열, `habitats`는 이름·희귀도 객체 배열, `spawnZones`는 문자열 배열입니다.
- 원본 이름은 영어이며 조건은 주로 스페인어입니다. upstream의 `translations/es.json`과 `en.json`에서 만든 번들 사전으로 영어 조건을 표시하고 번역이 없으면 원문을 유지합니다. 포켓몬 한국어 이름은 아래 PokeAPI 절차를 따르며 서식 조건 번역은 upstream 사전을 유지합니다.
- null 이미지, 키/무게, 미확인 날씨·시간·지역 등은 fallback 또는 ‘미제공’으로 표시합니다. 상세 이미지도 upstream이 제공하는 URL을 사용하며 별도 고해상도 URL이나 전투 스탯을 만들어내지 않습니다.
- `availability`는 과거 이벤트 일정일 수도 있습니다. 표시된 기간이 현재 유효하다는 의미는 아닙니다. 원본 데이터의 정확성을 보증하지 않습니다.
- 이미지 호스트: `cdn.pokopiapi.com`. 실패 시 아이콘으로 대체합니다.

## 오프라인 동작

성공적으로 파싱한 **전체 JSON과 저장 시각**을 SharedPreferences의 단일 버전 키에 저장합니다. 재실행 시 캐시를 즉시 표시한 뒤 네트워크로 갱신합니다. 오프라인·HTTP 오류·잘못된 응답은 기존 캐시를 덮어쓰지 않습니다. 저장 실패는 사용자에게 알립니다. 캐시가 없는 첫 실행은 인터넷 연결이 필요합니다.

이미지는 `cached_network_image` 디스크 캐시를 사용하며 실제로 본 이미지부터 저장합니다. 이미지 캐시는 용량/보존기간에 따라 삭제될 수 있습니다. 이미지가 없어도 목록과 상세 텍스트는 탐색할 수 있습니다. 앱 데이터 삭제/제거 시 캐시도 삭제됩니다. 별도 DB, 계정, 서버는 없습니다.

## 한국어 포켓몬 이름

목록과 상세 이름은 PokeAPI의 한국어 이름으로 표시하며 한글/영문/번호로 검색할 수 있습니다. 예: Bulbasaur → 이상해씨. 조회 키는 포코피아 `localNumber`가 아닌 **전국 도감 번호 `nationalNumber`**입니다.

`https://pokeapi.co/api/v2/pokemon-species/{nationalNumber}/` 응답의 `names`에서 `language.name == "ko"`인 항목만 선택합니다. 공식 PokeAPI 저장소의 `data/v2/csv/pokemon_species_names.csv`(한국어 언어 ID 3)에서 생성한 작은 기본 이름 사전을 탑재해 첫 목록부터 한글을 표시합니다. 상세 화면을 열면 종 API로 갱신하고 7일간 캐시합니다. API 오류·누락·오프라인에는 캐시/기본 이름을 유지하고 한국어 명칭이 없으면 원문 이름을 표시합니다. 포코피아의 서식지 데이터는 기존 pokopiapi를 계속 사용합니다.

## 바로 설치하는 APK 미리보기

PR 검증·머지 후 `main`에서 `Deliver installable APK`를 수동 실행하면 `v1.2.0-preview.1` 사전 릴리즈에 APK와 SHA-256이 게시됩니다. PokeAPI 실제 응답, 분석·테스트, ARM64 빌드·서명·앱 이름·버전을 검사합니다. PR 생성과 merge는 검증 결과를 확인한 뒤 수행하며 워크플로는 저장소 규칙을 우회하지 않습니다.

```sh
gh workflow run deliver-preview.yml --ref main
```

기존 약 83 MB APK는 **debug 빌드의 Flutter 엔진/JIT 실행 파일** 때문에 컸습니다. 포켓몬 이미지는 APK에 탑재하지 않으며 앱 실행 후 네트워크에서 받아 캐시합니다. 이번 미리보기는 **release/AOT 모드**로 최적화하고, `POKOPIA_PREVIEW_SIGNING=true`일 때에만 표준 Android 개발 키로 서명합니다. 정식 배포 키를 사용한 제품 릴리즈와 구분되는 테스트용입니다. 서명이 달라지면 이전 앱을 삭제한 뒤 재설치해야 할 수 있습니다. 삭제 시 기존 앱 캐시가 지워집니다.

앱 표시 이름은 **포코피아 서식지 도감**, 아이콘은 숲색 배경의 책·잎 모양입니다.

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
3. 정식 서명 배포는 GitHub의 `release` Environment에 `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` secrets를 설정합니다. 비밀 값을 채팅이나 저장소 파일에 넣지 마세요.
4. `main`에서 `Release Android` workflow를 실행하고 `tag`를 `v1.2.0`(pubspec 버전과 일치)으로 지정합니다. 테스트·ARM64 빌드·서명 검증이 통과해야 APK와 SHA-256 파일을 GitHub Release에 게시합니다. 기존 태그/릴리즈를 덮어쓰지 않습니다.
5. Play Store 배포는 이 워크플로 범위가 아닙니다. APK는 GitHub Release를 통한 직접 배포용입니다.

```sh
gh pr create --base main --head feat/pokopia-android --title 'Add offline Pokopia Android field guide' --body-file /path/to/pr-body.md
gh pr checks --watch
gh pr merge --squash --delete-branch
gh workflow run release.yml --ref main -f tag=v1.2.0
```

## 검증 상태

원격 데이터 계약과 fixture 365개 항목을 확인했습니다. GitHub Actions에서 Flutter 정적 분석, 자동 테스트 15개, Android debug/release APK 빌드가 실행됐습니다. ABI 검사에서 Flutter가 ARM64 외 아키텍처를 포함시키는 문제가 확인되어 `disable-abi-filtering=true`로 수정했습니다. 최종 ABI/서명/앱 이름 및 배포 결과는 해당 커밋의 Actions 실행과 Release에서 확인하세요. 실제 Android 기기 실행은 별도 검증이 필요합니다.

로컬 클라우드 머신은 SDK 다운로드(`storage.googleapis.com`)와 GitHub API(`api.github.com`)가 정책으로 차단되어 빌드/배포를 저장소의 GitHub Actions에서 수행합니다. 정식 서명 릴리즈에는 배포 서명 키가 필요하지만 테스트용 APK 미리보기는 별도 사용자 비밀 값 없이 생성합니다.

## 출처와 라이선스

[QuesoCaliente/pokopiapi](https://github.com/QuesoCaliente/pokopiapi), 참조 커밋 `893936af1adb51f6d2aab18aa8fa359fc401dd0a`. 원본 365개 항목은 테스트 fixture로만 포함되며 앱의 사전 탑재 데이터로 사용하지 않습니다. 파생 번역과 fixture에는 BSD-3-Clause 고지를 [assets/licenses/pokopiapi.txt](assets/licenses/pokopiapi.txt)에 보존했습니다. 앱 정보 → 라이선스에서도 확인할 수 있습니다. 프로젝트 자체 라이선스는 [LICENSE](LICENSE)를 따릅니다. Pokémon은 해당 권리자의 상표이며 이 앱은 비공식 팬 프로젝트입니다.

PokeAPI 기본 이름 사전 출처: https://github.com/PokeAPI/pokeapi/blob/master/data/v2/csv/pokemon_species_names.csv (2026-11-09 조회). PokeAPI 저작권 고지는 `assets/licenses/pokeapi.txt`와 앱 라이선스 화면에 포함합니다.

배포 시 PokeAPI 실제 접속은 재시도 후 확인합니다. 네트워크 오류면 경고와 SKIPPED로 기록하며, 기본 이름/오프라인 테스트는 계속 필수입니다. 200 응답의 종 번호·한국어 이름이 잘못되면 배포를 중단합니다. 외부 API 중단만으로 오프라인 앱 APK 배포를 막지는 않습니다.

## 1.2 아이템·이미지 도감

하단 `포켓몬 / 아이템` 탭으로 전환합니다. 아이템 탭은 GitHub Raw `src/data/items.json`의 전체 아이템(구현 시점 1,767개)을 가져와 `pokopia.items.v1` 키에 포켓몬 캐시와 별도로 저장합니다. 목록은 lazy grid이며 검색·카테고리·콘텐츠 필터를 조합할 수 있습니다. 이벤트 46개, 해저 확장팩 219개는 원본 `contentSource`로 구분하며 무료 업데이트와 혼동하지 않습니다. 상세에서 이미지, 설명, 입수 위치, 제작 재료·수량, 불완전한 제작법 상태와 이벤트 기간을 확인합니다.

`Habitat.iconUrl`과 포켓몬 타입·특기·날씨·시간대·생산의 `iconUrl`을 모델에서 보존합니다. 이미지 캡슐은 실제 제공 URL만 사용하고, 없거나 실패하면 텍스트와 접근 가능한 대체 아이콘을 유지합니다. 제작 재료는 원본 iconUrl 또는 동일 slug인 실제 아이템의 imageUrl만 사용하며 임의 CDN 주소를 만들어내지 않습니다. 아이템 이름/설명 및 번역이 없는 서식지 이름은 원문을 보존합니다. `assets/visual_labels_ko.json`은 일반 개념의 한국어 보조 표기이며 공식 게임 현지화 데이터로 보장하지 않습니다.

새 파일: `models/item.dart`, `models/visual_fact.dart`, `models/content_source.dart`, `services/items_service.dart`, `controllers/items_controller.dart`, `views/home_view.dart`, `views/items_view.dart`, `views/item_detail_view.dart`, `widgets/guide_visual.dart`, `widgets/content_filter.dart`.

아이템 fixture는 기존 pokopiapi BSD 고지의 적용을 받으며 앱 APK에 포함하지 않습니다. 사진·아이콘은 실행 중 CDN에서 내려받아 디스크 캐시하므로 아이템 개수만큼 APK가 커지지 않습니다. 새 미리보기 태그는 `v1.2.0-preview.1`, 앱 버전은 `1.2.0+3`입니다.
