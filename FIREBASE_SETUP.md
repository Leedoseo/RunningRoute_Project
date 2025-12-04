# Firebase Firestore 설정 가이드

이 앱은 Firebase Firestore를 백엔드 데이터베이스로 사용합니다.

## 1. Firestore 보안 규칙 배포

Firebase Console에서 Firestore 보안 규칙을 설정해야 합니다.

### 방법 1: Firebase CLI 사용 (권장)

```bash
# Firebase CLI 설치 (한 번만)
npm install -g firebase-tools

# Firebase 로그인
firebase login

# 프로젝트 초기화 (첫 실행 시)
firebase init firestore

# 보안 규칙 및 인덱스 배포
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

### 방법 2: Firebase Console에서 수동 설정

1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 선택
3. Firestore Database → 규칙 탭
4. `firestore.rules` 파일 내용을 복사해서 붙여넣기
5. 게시 버튼 클릭

## 2. Firestore 보안 규칙 설명

```
users/{userId}/routes/{routeId}
```

- 각 사용자는 자신의 `users/{userId}/routes` 컬렉션만 접근 가능
- 인증된 사용자만 자신의 데이터를 읽고 쓸 수 있음
- 다른 사용자의 데이터는 접근 불가

## 3. 데이터 구조

### Route 문서 구조

```
users/{userId}/routes/{routeId}
├── id: string (문서 ID)
├── title: string
├── startedAt: timestamp
├── endedAt: timestamp
├── path: array of {lat: number, lng: number}
├── distanceMeters: number
├── movingTimeSec: number
├── avgPaceSecPerKm: number | null
├── tags: array of {id: string, name: string, color: number}
├── notes: string | null
└── source: string ('recorded' | 'imported')
```

## 4. 인덱스

자동으로 생성되는 인덱스:
- `startedAt` (내림차순) - 최신 기록 순 정렬
- `distanceMeters` (내림차순) - 거리순 정렬

## 5. 로컬 개발

Firebase 에뮬레이터를 사용하려면:

```bash
firebase emulators:start
```

앱의 `main.dart`에서 에뮬레이터 연결 코드 추가:
```dart
if (kDebugMode) {
  await FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
}
```

## 6. 비용 최적화

Firestore는 읽기/쓰기/삭제 작업당 과금됩니다.

- 무료 할당량: 하루 50,000 읽기, 20,000 쓰기
- 캐싱을 활용하여 비용 절감
- 페이지네이션 구현 권장 (현재는 미구현)

## 7. 문제 해결

### "User not authenticated" 에러
- Firebase Authentication으로 로그인했는지 확인
- `AuthController.instance.isAuthenticated`가 true인지 확인

### 권한 거부 에러
- Firestore 보안 규칙이 올바르게 배포되었는지 확인
- 사용자 UID가 올바른지 확인

### 데이터가 보이지 않음
- Firebase Console의 Firestore 데이터 탭에서 데이터 확인
- 네트워크 연결 확인
- 앱 재시작
