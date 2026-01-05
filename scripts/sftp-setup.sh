#!/usr/bin/env bash

# Copyright:: Copyright (c) 2025 Been Kyung-yoon (http://www.php79.com/)
# License:: The MIT License (MIT)
# Description: SFTP 전용 사용자 chroot 환경 설정 스크립트

STACK_ROOT=$( cd "$( dirname "$0" )/.." && pwd )
source "${STACK_ROOT}/includes/function.inc.sh"

function show_usage
{
  welcome_short

  title "SFTP 전용 사용자 chroot 환경을 설정합니다."
  echo
  outputComment "  이 스크립트는 기존 사용자를 SFTP 전용으로 변경하거나, 새 SFTP 전용 사용자를 생성합니다."
  outputComment "  chroot 설정으로 사용자는 /home/아이디/master 디렉토리만 접근할 수 있습니다."
  echo

  echo
  echo "Example:"
  outputComment "  ${0} --user=php79"
  echo

  echo
  echo "Usage:"

  echo -n "  "
  outputInfo  "--user"
  echo "      SFTP chroot를 설정할 시스템 계정 아이디를 입력하세요."
  echo
}

function input_abort
{
  outputError "${1}"
  echo
  exit 1
}

# Options
if [ -z ${1} ]; then
  show_usage
  exit
else
  for i in "${@}"
  do
  case ${i} in
    --user=*)
      shift
      INPUT_USER="${i#*=}"
      ;;
    -h | --help )
      show_usage
      exit
      ;;
  esac
  done
fi

# 입력값 검사
if [ -z ${INPUT_USER} ]; then
  input_abort "user 항목을 입력하세요."
fi

# 사용자 존재 확인
if [ -z $(id -u ${INPUT_USER} 2>/dev/null) ]; then
  input_abort "존재하지 않는 사용자입니다. 먼저 ./user-add.sh 로 사용자를 생성하세요."
fi

# 홈 디렉토리 확인
USER_HOME=$(eval echo ~${INPUT_USER})
if [ ! -d "${USER_HOME}" ]; then
  input_abort "사용자의 홈 디렉토리가 존재하지 않습니다: ${USER_HOME}"
fi

notice "SFTP chroot 환경을 설정합니다."

#-------------------
# 1. 디렉토리 구조 및 권한 설정
#-------------------
outputComment "1. 디렉토리 권한을 설정합니다."

# 홈 디렉토리는 root 소유, 755 권한 필요 (chroot 요구사항)
chown root:root "${USER_HOME}"
chmod 755 "${USER_HOME}"
echo "  - ${USER_HOME} : root 소유, 755 권한으로 변경"

# master 디렉토리 생성 (없으면)
if [ ! -d "${USER_HOME}/master" ]; then
  mkdir -v "${USER_HOME}/master"
fi

# master 디렉토리는 사용자 소유
chown -R ${INPUT_USER}:${INPUT_USER} "${USER_HOME}/master"
chmod 755 "${USER_HOME}/master"
echo "  - ${USER_HOME}/master : ${INPUT_USER} 소유, 755 권한으로 변경"

# public 디렉토리 생성 및 권한 설정
if [ ! -d "${USER_HOME}/master/public" ]; then
  mkdir -v "${USER_HOME}/master/public"
  chown ${INPUT_USER}:${INPUT_USER} "${USER_HOME}/master/public"
  chmod 707 "${USER_HOME}/master/public"
  echo "  - ${USER_HOME}/master/public : ${INPUT_USER} 소유, 707 권한으로 생성"
fi

# logs 디렉토리 생성
if [ ! -d "${USER_HOME}/logs" ]; then
  mkdir -v "${USER_HOME}/logs"
  chown ${INPUT_USER}:${INPUT_USER} "${USER_HOME}/logs"
  chmod 755 "${USER_HOME}/logs"
  echo "  - ${USER_HOME}/logs : ${INPUT_USER} 소유로 생성"
fi

echo

#-------------------
# 2. sftpusers 그룹 생성
#-------------------
outputComment "2. sftpusers 그룹을 확인합니다."

if ! getent group sftpusers > /dev/null 2>&1; then
  groupadd sftpusers
  echo "  - sftpusers 그룹 생성 완료"
else
  echo "  - sftpusers 그룹이 이미 존재합니다."
fi

# 사용자를 sftpusers 그룹에 추가
usermod -g sftpusers -s /sbin/nologin ${INPUT_USER}
echo "  - ${INPUT_USER} 사용자를 sftpusers 그룹에 추가하고 쉘을 /sbin/nologin으로 변경"
echo

#-------------------
# 3. sshd_config 설정 추가
#-------------------
outputComment "3. /etc/ssh/sshd_config 설정을 업데이트합니다."

SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_MATCH_BLOCK="Match Group sftpusers"

# 이미 설정이 있는지 확인
if grep -q "${SSHD_MATCH_BLOCK}" "${SSHD_CONFIG}"; then
  echo "  - sftpusers 그룹 설정이 이미 존재합니다."
else
  # 백업 생성
  cp -av "${SSHD_CONFIG}" "${SSHD_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

  # sshd_config 끝에 설정 추가
  cat >> "${SSHD_CONFIG}" << 'SSHD_EOF'

# SFTP chroot 설정 for sftpusers group
Match Group sftpusers
    ChrootDirectory /home/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
SSHD_EOF

  echo "  - sftpusers 그룹 chroot 설정 추가 완료"
fi

echo

#-------------------
# 4. sshd 서비스 재시작
#-------------------
outputComment "4. sshd 설정을 테스트하고 서비스를 재시작합니다."

# sshd 설정 테스트
/usr/sbin/sshd -t

if [ "${?}" != "0" ]; then
  outputError "sshd 설정에 오류가 있습니다. 백업 파일을 확인하세요."
  abort
fi

echo "  - sshd 설정 테스트 통과"

# sshd 재시작
if [ "$SYSTEMCTL" = "1" ]; then
  systemctl restart sshd
else
  service sshd restart
fi

if [ "${?}" = "0" ]; then
  echo "  - sshd 서비스 재시작 완료"
else
  outputError "sshd 서비스 재시작 실패"
  abort
fi

echo

#-------------------
# 완료
#-------------------
outputComment "### SFTP chroot 설정이 완료되었습니다. ###\n\n"

outputInfo "  - 사용자           : ${INPUT_USER}\n"
outputInfo "  - 접속 방식        : SFTP 전용 (SSH 접속 불가)\n"
outputInfo "  - 접근 가능 경로   : /master 디렉토리만\n"
outputInfo "  - 실제 경로        : ${USER_HOME}/master\n"
echo

outputComment "주의사항:"
echo "  1. SSH 터미널 접속은 불가능하며, SFTP(FileZilla 등)로만 접속 가능합니다."
echo "  2. SFTP 클라이언트에서 접속 시 루트 디렉토리가 /master 로 보입니다."
echo "  3. 웹 문서는 /master/public 디렉토리에 업로드하세요."
echo

outputComment "접속 테스트:"
echo "  sftp ${INPUT_USER}@서버IP"
echo
