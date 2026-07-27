# Do Not Sleep

키보드와 마우스 입력이 일정 시간 없으면 포인터로 큰 원을 그려 macOS와
앱이 유휴 상태로 전환되는 것을 방지하는 가벼운 메뉴바 앱입니다.

## 주요 기능

- 키보드와 마우스의 시스템 유휴 시간 감지
- 기본 5분 후 마우스 포인터로 반지름 250픽셀의 원을 10초 동안 이동
- 유휴 시간을 1분부터 120분까지 설정
- 메뉴바에서 잠자기 방지 즉시 켜기/끄기
- 로그인 시 자동 실행
- 입력 내용과 마우스 위치 이력을 저장하지 않는 로컬 동작
- Apple Silicon 및 Intel Mac을 지원하는 Universal 앱

## 설치

1. [Releases](https://github.com/LimFull/do-not-sleep/releases/latest)에서
   `DoNotSleep-1.3.0-universal.dmg`를 내려받습니다.
2. DMG를 열고 **DoNotSleep**을 **Applications** 폴더로 드래그합니다.
3. Applications 폴더에서 앱을 마우스 오른쪽 버튼으로 클릭하고 **열기**를
   선택합니다.
4. 안내에 따라
   `시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용`에서
   **Do Not Sleep**을 허용합니다.

현재 배포 파일은 Apple Developer ID로 공증되지 않은 ad-hoc 서명 빌드입니다.
따라서 최초 실행 시 Finder의 **마우스 오른쪽 버튼 > 열기**가 필요할 수
있습니다.

## 사용 방법

메뉴바의 달 아이콘을 클릭해 **잠자기 방지**를 켜거나 끌 수 있습니다.
**설정…**에서는 다음 항목을 변경할 수 있습니다.

- 마우스를 움직일 유휴 시간: 1~120분, 기본값 5분
- 로그인 시 자동 실행
- 접근성 권한 상태 확인

로그인 자동 실행은 앱을 Applications 폴더로 옮긴 뒤 활성화하는 것을
권장합니다.

## 개인정보 보호

앱은 키보드 입력 내용이나 마우스 위치 이력을 읽거나 저장하지 않습니다.
Quartz가 제공하는 마지막 키보드·마우스 이벤트 이후의 경과 시간만 확인합니다.
접근성 권한은 유휴 시간이 지난 뒤 마우스 이동 이벤트를 보내는 용도로만
사용합니다.

## 직접 빌드

요구 사항:

- macOS 14 이상
- Xcode 15 이상 또는 Swift 6 도구 모음

Universal 앱 번들 만들기:

```sh
make app
```

DMG 만들기:

```sh
make dmg
```

결과물은 `dist/`에 생성됩니다.

개발용 빌드:

```sh
swift build
```

## 기술 구성

- Swift 6
- SwiftUI `MenuBarExtra`
- Quartz `CGEventSource` 및 `CGEvent`
- ServiceManagement `SMAppService`

## 지원 환경

- macOS 14 Sonoma 이상
- Apple Silicon 및 Intel Mac
