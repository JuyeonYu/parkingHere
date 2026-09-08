# Apple Watch 앱 계획

작성일: 2026-09-09 · 대상 버전: 1.1 다음 배포

## 원칙

- 워치 앱은 기존 앱 업데이트에 번들로 포함된다. 스토어 등록을 따로 하지 않는다.
- 세션 모델과 저장소(`ParkingSession`, `ParkingSessionStore`, `CarImageStore`)는 화면 코드와 분리돼 있으므로 워치 타겟에 그대로 공유한다. 새 기능도 화면 코드에 상태 로직을 섞지 않는다.

## 설계 결정

1. **진실의 원천은 iPhone.** 세션은 iPhone이 소유하고 워치는 사본을 본다. 워치에서 시작·종료하면 iPhone에 요청하고, iPhone이 없으면 워치가 임시 세션을 만들었다가 연결되면 합친다. 충돌은 "더 최근 시작 시각이 이긴다".
2. **동기화 채널은 두 겹.** WatchConnectivity로 즉시 전달하고, iCloud 키-값 저장소(`NSUbiquitousKeyValueStore`)를 보조로 둬서 폰이 꺼져 있거나 멀리 있어도 몇 분 안에 맞춰지게 한다. 서버 코드는 없다. 사진은 WatchConnectivity 파일 전송으로 축소본만 보낸다.
3. **워치 단독 동작 범위.** 워치 GPS로 시작·종료·나침반까지는 단독으로 된다. 사진 촬영과 단축어 자동화는 iPhone 전용.
4. **최소 watchOS 10.** SwiftUI 워치 앱, WidgetKit 컴플리케이션, App Intents가 안정적인 첫 버전. Smart Stack 라이브 액티비티(watchOS 11)는 iPhone 쪽 위젯 익스텐션이 담당하므로 워치 앱 최소 버전과 무관하다.

## 단계

### 1주차: 뼈대와 동기화
- watchOS App 타겟 추가(SwiftUI). 번들 ID `com.johnny.findMyCar.watchkitapp`.
- 공유 모델 파일 연결.
- WatchConnectivity 세션 동기화(양방향, 최근 시작 시각 우선).
- 워치 메인 화면: 주차 중 여부, 경과 시간, 메모, 시작·종료 버튼.

### 2주차: 나침반
- 워치 위치와 방향으로 차까지 화살표와 거리 표시. 워치 앱의 핵심 화면.
- 지하 등 GPS가 없을 때는 "마지막으로 잡힌 위치 기준" 표시와 사진 축소본으로 대체.

### 3주차: 주변부
- 컴플리케이션(경과 시간, 탭하면 나침반). 번들 ID `com.johnny.findMyCar.watchkitapp.widget`.
- 워치 Siri: "주차 시작", "내 차 어디야" (App Intents를 워치 타겟에도 포함).
- iPhone 라이브 액티비티에 Smart Stack용 작은 레이아웃(`supplementalActivityFamilies([.small])`).
- iCloud 키-값 보조 동기화.

### 마무리
- Apple Watch 스크린샷 세트(현재 요구 규격: Series 10 기준 416×496).
- 워치 Info.plist 위치 권한 문구(5개 언어).
- 새 번들 ID 두 개의 프로파일.
- TestFlight으로 실제 주차 상황에서 며칠 사용 후 제출.

## 미리 준비할 것

- 테스트용 Apple Watch 한 대와 개발자 계정 등록. 시뮬레이터로는 GPS, 나침반, WatchConnectivity를 검증할 수 없다.
- 앱 ID에 iCloud 기능 켜기. 프로파일을 다시 만들어야 하므로 워치 작업을 시작할 때 켠다.
- 디자인 톤은 iPhone 앱의 노란 브랜드 색과 둥근 서체를 그대로 사용. 컴플리케이션은 단색 틴트로 그려지므로 전용 아이콘만 정한다.

## 이번 배포(1.1)에서의 결정

- 워치 관련 코드는 넣지 않는다. 실기기 검증에서 확인한 사용 패턴(자동화 시작 비율, 사진을 나중에 붙이는지)을 워치 기능 우선순위의 근거로 삼는다.
