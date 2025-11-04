# Rhymix 자동 설치 스크립트

[Rhymix](https://rhymix.org/)는 XpressEngine을 기반으로 개발된 강력한 오픈소스 PHP CMS입니다.

- **공식 사이트**: https://rhymix.org/
- **GitHub 저장소**: https://github.com/rhymix/rhymix
- **문서**: https://github.com/rhymix/rhymix-docs

## 시스템 요구사항

- **PHP**: 7.4 이상 (8.0 이상 권장)
- **MariaDB/MySQL**: 5.5 이상
- **Web Server**: Nginx 또는 Apache
- **Composer**: PHP 패키지 관리자

## 자동 설치 방법

### 1. 기본 설치 (권장)

app-install.sh 스크립트를 사용하여 한 번에 설치할 수 있습니다:

```bash
cd /root/stack
./app-install.sh --user=rhymix --domain=rhymix.example.com --app=rhymix --php=82 --ssl
```

**옵션 설명:**
- `--user`: 시스템 사용자명 (생성됨)
- `--domain`: 도메인 주소
- `--app=rhymix`: Rhymix 앱 설치
- `--php=82`: PHP 8.2 사용 (74, 80, 81, 82, 83, 84 지원)
- `--ssl`: Let's Encrypt SSL 인증서 자동 발급

### 2. 수동 설치

이미 사용자 계정이 있는 경우 수동으로 설치할 수 있습니다:

```bash
# 1. 사용자 계정으로 전환
su - rhymix

# 2. Rhymix 설치 스크립트 실행
bash /root/stack/apps/rhymix/install.sh

# 3. 웹브라우저에서 설치 진행
# http://도메인주소/ 접속하여 설치 마법사 실행
```

## 설치 후 작업

### 웹 설치 마법사

1. 웹브라우저에서 도메인 주소로 접속
2. 설치 마법사가 자동으로 실행됨
3. 데이터베이스 정보 입력:
   - **DB 호스트**: localhost
   - **DB 이름**: (사용자명)
   - **DB 사용자**: (사용자명)
   - **DB 비밀번호**: (자동 생성된 비밀번호 - `/root/.my.cnf` 확인)
4. 관리자 계정 생성
5. 설치 완료

### 비밀번호 확인

데이터베이스 비밀번호는 설치 시 자동 생성되며 다음 위치에 저장됩니다:

```bash
# root 계정에서 확인
cat /home/사용자명/.my.cnf
```

## 업데이트

Rhymix를 최신 버전으로 업데이트하려면:

```bash
# 사용자 계정으로 전환
su - rhymix

# Rhymix 디렉토리로 이동
cd ~/master/public

# 업데이트 스크립트 실행
bash /root/stack/apps/rhymix/update.sh
```

업데이트 스크립트는 자동으로:
1. 현재 files, config 디렉토리 백업 생성
2. Git을 통해 최신 코드 다운로드
3. Composer 의존성 업데이트
4. 캐시 삭제

## 주요 디렉토리 구조

```
~/master/public/
├── index.php          # 메인 진입점
├── admin/             # 관리자 페이지
├── common/            # 공통 라이브러리
├── modules/           # 모듈
├── addons/            # 애드온
├── widgets/           # 위젯
├── layouts/           # 레이아웃
├── files/             # 업로드 파일 (쓰기 권한 필요)
├── config/            # 설정 파일 (쓰기 권한 필요)
└── vendor/            # Composer 패키지
```

## 보안 설정

다음 디렉토리/파일들은 웹 접근이 차단됩니다:
- `/files/*.php` - 업로드 디렉토리에서 PHP 실행 차단
- `/vendor/` - Composer 패키지 접근 차단
- `/config/*.php` - 설정 파일 접근 차단
- `/common/defaults/` - 기본 설정 접근 차단
- `/.git/`, `/.env` - 버전관리 및 환경 설정 파일 차단

## 관리자 페이지

- **URL**: http://도메인주소/admin
- **초기 접속**: 설치 시 생성한 관리자 계정으로 로그인

## 문제 해결

### 파일 업로드 문제

업로드 크기 제한을 변경하려면:

```bash
# Nginx 설정 수정
vi /etc/nginx/conf.d/사용자명-server.conf

# client_max_body_size 값 수정 (예: 100m)
client_max_body_size 100m;

# Nginx 재시작
systemctl restart nginx

# PHP 설정 수정 (PHP 8.2 예시)
vi /etc/opt/remi/php82/php.d/z-php79.ini

# upload_max_filesize, post_max_size 값 수정
upload_max_filesize = 100M
post_max_size = 100M

# PHP-FPM 재시작
systemctl restart php82-php-fpm
```

### 권한 문제

파일 및 디렉토리 권한 재설정:

```bash
# 사용자 계정으로
cd ~/master/public

# 디렉토리 권한 설정
chmod 0707 files files/*
chmod 0707 common/defaults

# 소유자 설정 (nobody 그룹)
chgrp -R nobody files common/defaults
```

### 캐시 삭제

문제가 발생하면 캐시를 삭제해보세요:

```bash
cd ~/master/public
rm -rf files/cache/*
```

## 지원 및 커뮤니티

- **공식 포럼**: https://rhymix.org/
- **GitHub Issues**: https://github.com/rhymix/rhymix/issues
- **문서**: https://github.com/rhymix/rhymix-docs

## 라이선스

Rhymix는 GPL-2.0 라이선스로 배포됩니다.

