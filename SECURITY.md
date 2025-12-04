# 보안 가이드

## Firebase 설정 보안

### ⚠️ 중요: firebase_options.dart 관리

`lib/firebase_options.dart` 파일은 **민감한 API 키**를 포함하고 있습니다. 이 파일은 `.gitignore`에 추가되어 Git에 커밋되지 않도록 설정되어 있습니다.

### 새로운 팀원이나 환경에서 설정하는 방법

#### 1. FlutterFire CLI 설치

```bash
dart pub global activate flutterfire_cli
```

#### 2. Firebase 프로젝트와 연결

```bash
flutterfire configure
```

이 명령어를 실행하면:
- Firebase 프로젝트 선택
- 플랫폼 선택 (iOS, Android, Web 등)
- `lib/firebase_options.dart` 자동 생성

#### 3. 생성된 파일 확인

`lib/firebase_options.dart` 파일이 생성되었는지 확인하세요. 이 파일은 **절대 Git에 커밋하지 마세요**.

### 프로덕션 환경 보안 강화

#### Firestore 보안 규칙

`firestore.rules` 파일에 정의된 보안 규칙을 반드시 배포하세요:

```bash
firebase deploy --only firestore:rules
```

**핵심 규칙:**
- 사용자는 자신의 데이터만 접근 가능
- 인증되지 않은 사용자는 읽기/쓰기 불가
- 서버 측 검증을 통한 데이터 무결성 보장

#### Firebase Authentication 설정

1. **이메일/비밀번호 인증 활성화**
   - Firebase Console → Authentication → Sign-in method
   - Email/Password 활성화

2. **비밀번호 정책**
   - 최소 6자 이상 (Firebase 기본값)
   - 복잡도 요구사항은 클라이언트에서 추가 검증

3. **계정 보호**
   - 이메일 인증 활성화 권장
   - 비밀번호 재설정 이메일 템플릿 커스터마이징

### API 키 노출 시 대응

만약 실수로 `firebase_options.dart`가 Git에 커밋되었다면:

#### 1. Git 히스토리에서 제거

```bash
# 파일을 Git 히스토리에서 완전히 제거
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch lib/firebase_options.dart" \
  --prune-empty --tag-name-filter cat -- --all

# 강제 푸시 (주의: 팀원과 조율 필요)
git push origin --force --all
```

#### 2. Firebase 프로젝트 키 재생성

1. Firebase Console → 프로젝트 설정
2. 일반 탭에서 앱 삭제 후 재생성
3. `flutterfire configure` 재실행

#### 3. 기존 사용자에게 알림

- 보안 패치 업데이트 배포
- 필요시 사용자 재인증 요청

### 환경 변수 사용 (선택사항)

더 높은 보안이 필요한 경우 환경 변수 사용:

#### 1. flutter_dotenv 설치

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

#### 2. .env 파일 생성

```env
FIREBASE_API_KEY=your-api-key
FIREBASE_APP_ID=your-app-id
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_PROJECT_ID=your-project-id
```

#### 3. .env를 .gitignore에 추가

```gitignore
.env
.env.local
```

### 보안 체크리스트

프로덕션 배포 전 확인사항:

- [ ] `lib/firebase_options.dart`가 .gitignore에 포함됨
- [ ] Firestore 보안 규칙이 배포됨
- [ ] Firebase Console에서 API 키 제한 설정 확인
- [ ] 인증 없이 접근 가능한 엔드포인트가 없는지 확인
- [ ] 민감한 데이터가 로그에 출력되지 않는지 확인
- [ ] HTTPS만 사용하도록 설정

### 문제 발생 시

보안 관련 문제가 발생하면:

1. 즉시 Firebase Console에서 API 키 비활성화
2. 프로젝트 관리자에게 알림
3. 키 재생성 및 앱 업데이트 배포

### 추가 리소스

- [Firebase 보안 가이드](https://firebase.google.com/docs/rules)
- [Flutter 보안 베스트 프랙티스](https://flutter.dev/security)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
