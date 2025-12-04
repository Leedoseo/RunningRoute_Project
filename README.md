# RouteLog 🏃‍♂️

러닝 경로를 기록하고 관리하는 Flutter 앱

## 📱 주요 기능

- **실시간 경로 기록**: GPS를 활용한 정확한 러닝 경로 추적
- **통계 분석**: 거리, 시간, 페이스 등 상세한 러닝 데이터 분석
- **경로 관리**: 기록한 경로 검색, 정렬, 태그 관리
- **다크 모드**: 시스템 설정 연동 또는 수동 테마 전환
- **Firebase 통합**: 클라우드 기반 데이터 저장 및 사용자 인증

## 🏗️ 기술 스택

### Frontend
- **Flutter** (Dart)
- **Google Maps Flutter**: 지도 및 경로 시각화
- **Geolocator**: GPS 위치 추적

### Backend
- **Firebase Authentication**: 이메일/비밀번호 인증
- **Cloud Firestore**: NoSQL 데이터베이스
- **Firebase Core**: Firebase 초기화 및 설정

### 상태 관리
- **ChangeNotifier**: Flutter 기본 상태 관리
- **Provider 패턴**: 의존성 주입

### 아키텍처
- **Repository 패턴**: 데이터 레이어 추상화
- **Feature-first 구조**: 기능별 모듈화
- **Clean Architecture**: 계층 분리 및 의존성 관리

## 📂 프로젝트 구조

```
lib/
├── core/                          # 핵심 공통 코드
│   ├── auth/                      # 인증 관리
│   ├── data/                      # 데이터 모델 및 Repository
│   │   ├── models/                # RouteLog, Tag 등 데이터 모델
│   │   └── repository/            # Repository 인터페이스 및 구현체
│   │       ├── firestore/         # Firestore 구현
│   │       ├── file/              # 로컬 파일 구현
│   │       └── mock/              # 목 데이터
│   ├── navigation/                # 라우팅
│   └── theme/                     # 테마 설정
├── features/                      # 기능별 모듈
│   ├── auth/                      # 로그인/회원가입
│   ├── home/                      # 홈 화면
│   ├── record/                    # 경로 기록
│   ├── routes/                    # 경로 목록 및 상세
│   ├── stats/                     # 통계
│   ├── search/                    # 검색
│   └── settings/                  # 설정
└── main.dart                      # 앱 진입점
```


## 📊 주요 기능 상세

### 1. 경로 기록 (Record)

- 실시간 GPS 추적
- 거리, 시간, 페이스 계산
- 자동 일시정지 (설정 가능)
- 백그라운드 위치 업데이트 (iOS/Android)

### 2. 경로 관리 (Routes)

- 경로 목록 보기 (날짜/거리 정렬)
- 경로 검색 (제목, 노트)
- 태그 기반 필터링
- 경로 상세 정보 및 지도 표시

### 3. 통계 (Stats)

- 총 거리, 총 시간
- 평균 페이스
- 최장 거리 기록
- 월별/주별 통계

### 4. 설정 (Settings)

- 테마 설정 (라이트/다크/시스템)
- GPS 정확도 설정
- 자동 일시정지 설정
- 로그아웃


## 📝 개발 로그

주요 개선 사항:

- ✅ Firebase Firestore 백엔드 통합
- ✅ 사용자 인증 시스템
- ✅ 메모리 릭 수정 (Timer 사용)
- ✅ 에러 핸들링 강화
- ✅ 보안 설정 개선


## 📄 라이선스

이 프로젝트는 개인 포트폴리오용으로 제작되었습니다.
