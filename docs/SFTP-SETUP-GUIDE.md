# SFTP 전용 사용자 설정 가이드

## 개요

SFTP 전용 사용자는 SSH 터미널 접속이 차단되고 SFTP(파일 전송)만 가능한 계정입니다.
보안성이 높아 웹 호스팅 환경에 적합하며, 사용자는 `/home/아이디/master` 디렉토리만 접근할 수 있습니다.

## 주요 특징

### 일반 SSH 사용자 vs SFTP 전용 사용자

| 구분 | 일반 SSH 사용자 | SFTP 전용 사용자 |
|------|----------------|-----------------|
| SSH 터미널 접속 | ✅ 가능 | ❌ 불가 |
| SFTP 파일 전송 | ✅ 가능 | ✅ 가능 |
| 접근 가능 경로 | 서버 전체 | /master 디렉토리만 |
| 보안성 | 보통 | 높음 |
| 용도 | 개발/관리 | 웹 호스팅 |

### 디렉토리 구조

```
/home/아이디/                    (root 소유, 755 권한 - chroot 지점)
├── master/                      (사용자 소유 - SFTP 접근 가능)
│   ├── public/                  (웹 문서 루트)
│   ├── session/                 (세션 저장 디렉토리)
│   └── ...
└── logs/                        (로그 디렉토리)
```

## 사용 방법

### 1. 새로운 SFTP 전용 사용자 생성

#### 방법 1: user-add.sh 사용 (권장)

```bash
./user-add.sh --user=php79 --password='php79!@' --sftp-only
```

#### 방법 2: app-install.sh 사용 (앱 설치와 동시에)

```bash
./app-install.sh --user=php79 --domain=php79.net --app=wordpress --php=81 --sftp-only
```

### 2. 기존 사용자를 SFTP 전용으로 변경

```bash
./scripts/sftp-setup.sh --user=php79
```

## 접속 방법

### FileZilla 설정 예시

```
호스트: sftp://서버IP 또는 도메인
프로토콜: SFTP - SSH File Transfer Protocol
포트: 22
로그온 유형: 일반
사용자: php79
비밀번호: php79!@
```

### 명령줄 SFTP 접속

```bash
sftp php79@서버IP
```

접속 후 보이는 경로:
```
sftp> pwd
Remote working directory: /master
```

실제 서버 경로는 `/home/php79/master` 이지만, SFTP에서는 `/master`로 보입니다.

## 파일 업로드 경로

웹 문서는 **`/master/public`** 디렉토리에 업로드하세요.

```
/master/public/           ← 웹 루트 (Nginx document root)
/master/public/index.php  ← 메인 페이지
/master/public/images/    ← 이미지 파일
```

## 기술 상세

### chroot 설정

SFTP 전용 사용자는 `/etc/ssh/sshd_config`에 다음과 같이 설정됩니다:

```bash
Match Group sftpusers
    ChrootDirectory /home/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
```

### 디렉토리 권한 요구사항

chroot 환경에서는 다음 규칙을 반드시 지켜야 합니다:

1. **chroot 디렉토리** (`/home/아이디`):
   - 소유자: root
   - 권한: 755
   - 이유: SSH 보안 정책

2. **사용자 작업 디렉토리** (`/home/아이디/master`):
   - 소유자: 사용자
   - 권한: 755
   - 이유: 사용자가 파일을 읽고 쓸 수 있어야 함

### 사용자 그룹 및 쉘

```bash
# 사용자를 sftpusers 그룹에 추가
usermod -g sftpusers php79

# 쉘을 /sbin/nologin으로 변경 (SSH 접속 차단)
usermod -s /sbin/nologin php79
```

## 문제 해결

### SFTP 접속이 안 될 때

1. **sshd 서비스 상태 확인**
   ```bash
   systemctl status sshd
   ```

2. **sshd 설정 테스트**
   ```bash
   /usr/sbin/sshd -t
   ```

3. **사용자 그룹 확인**
   ```bash
   groups php79
   # 출력: php79 : sftpusers
   ```

4. **디렉토리 권한 확인**
   ```bash
   ls -ld /home/php79
   # 출력: drwxr-xr-x. 4 root root ... /home/php79

   ls -ld /home/php79/master
   # 출력: drwxr-xr-x. 4 php79 php79 ... /home/php79/master
   ```

### 권한 오류 (Permission denied)

chroot 디렉토리(`/home/아이디`)의 소유자가 root가 아니거나 권한이 755가 아닌 경우 발생합니다.

**해결 방법:**
```bash
chown root:root /home/php79
chmod 755 /home/php79
systemctl restart sshd
```

### "Write failed: Broken pipe" 오류

sshd_config 설정이 잘못되었을 가능성이 있습니다.

**해결 방법:**
```bash
# 백업에서 복원
cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
systemctl restart sshd

# 다시 설정
./scripts/sftp-setup.sh --user=php79
```

## 일반 SSH 사용자로 되돌리기

SFTP 전용 사용자를 다시 일반 SSH 사용자로 변경하려면:

```bash
# 1. 사용자 그룹을 원래대로 변경
usermod -g php79 php79

# 2. 쉘을 bash로 변경
usermod -s /bin/bash php79

# 3. 홈 디렉토리 권한 변경
chown php79:php79 /home/php79
chmod 710 /home/php79

# 4. sshd_config에서 Match Group sftpusers 섹션 제거 (선택)
# 다른 SFTP 전용 사용자가 있다면 제거하지 마세요
vi /etc/ssh/sshd_config

# 5. sshd 재시작
systemctl restart sshd
```

## 참고 자료

- OpenSSH SFTP chroot: https://www.ssh.com/academy/ssh/chroot
- CentOS/Rocky Linux SFTP 설정: https://wiki.centos.org/HowTos/Network/SecuringSSH
- FileZilla 공식 문서: https://filezilla-project.org/

## 작성자

- stack-master 프로젝트
- 최종 수정: 2025-01-05
