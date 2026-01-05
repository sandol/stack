#!/usr/bin/env bash

# Copyright:: Copyright (c) 2016 Been Kyung-yoon (http://www.php79.com/)
# License:: The MIT License (MIT)

STACK_ROOT=$( cd "$( dirname "$0" )" && pwd )
source "${STACK_ROOT}/includes/function.inc.sh"

cd ${STACK_ROOT}

welcome_short

title "시스템, 디비 계정을 생성합니다."

function show_usage
{
  echo
  echo "Example:"
  outputComment "  ${0} --user=php79 --password='php79!@'"
  outputComment "  ${0} --user=php79 --password='php79!@' --sftp-only"
  echo

  echo
  echo "Usage:"

  echo -n "  "
  outputInfo  "--user"
  echo "      시스템/디비 계정에 사용될 아이디를 입력하세요."
  echo

  echo -n "  "
  outputInfo  "--password"
  echo "  비밀번호.  특수문자 사용시엔 반드시 작은 따옴표(')로 감싸주어야 합니다."
  echo

  echo -n "  "
  outputInfo  "--sftp-only"
  echo "  (선택) SFTP 전용 사용자로 생성합니다. SSH 터미널 접속은 불가하며, /home/아이디/master 디렉토리만 접근 가능합니다."
  echo "          보안성이 높아 웹 호스팅 환경에 적합합니다."
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
  INPUT_SFTP_ONLY=0
  for i in "${@}"
  do
  case ${i} in
    --user=*)
      shift
      INPUT_USER="${i#*=}"
      ;;
    --password=*)
      shift
      INPUT_PASSWORD="${i#*=}"
      ;;
    --skip-guide-app-install=*)
      shift
      GUIDE_APP_INSTALL="${i#*=}"
      ;;
    --sftp-only)
      shift
      INPUT_SFTP_ONLY=1
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

if [ ! -z $(id -u ${INPUT_USER} 2>/dev/null) ]; then
  input_abort "이미 생성된 user 입니다."
fi

if [ -z ${INPUT_PASSWORD} ]; then
  input_abort "password 항목을 입력하세요."
fi


# System account
# TODO: /home 대신 다른 파티션을 지정하거나, HOME_DIR 을 입력받도록 개선
useradd ${INPUT_USER} \
&& chmod -v 710 "/home/${INPUT_USER}" \
&& chgrp -v nobody "/home/${INPUT_USER}" \
&& echo "${INPUT_USER}:${INPUT_PASSWORD}" | chpasswd

if [ "${?}" != "0" ]; then
  abort "[ ${INPUT_USER} ] 시스템 계정 생성이 실패하였습니다."
fi

notice "시스템 계정이 생성되었습니다. /home/${INPUT_USER} 디렉토리를 사용하세요."


# TODO: PHP 와 mariadb 서버가 분리된 경우 대응 고려
# MariaDB account & database
mysql -uroot mysql -e "CREATE DATABASE \`${INPUT_USER}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" \
&& mysql -uroot mysql -e "GRANT USAGE ON * . * TO \`${INPUT_USER}\`@'localhost' IDENTIFIED BY '${INPUT_PASSWORD}';" \
&& mysql -uroot mysql -e "GRANT ALL PRIVILEGES ON \`${INPUT_USER}\` . * TO \`${INPUT_USER}\`@'localhost' WITH GRANT OPTION ;"

if [ "${?}" != "0" ]; then
  abort "[ ${INPUT_USER} ] 디비 계정 생성이 실패하였습니다."
fi

notice "디비 계정이 생성되었습니다.  디비 인코딩은 utf8mb4 입니다."


notice "생성된 디비 계정 접속을 테스트합니다."
MYSQL_TEST="mysql -u${INPUT_USER} -p'${INPUT_PASSWORD}' ${INPUT_USER} -e \"SHOW TABLES;\""
eval ${MYSQL_TEST}
if [ "${?}" != "0" ]; then
  echo "  접속 실패) ${MYSQL_TEST}"
  abort "[ ${INPUT_USER} ] 디비 계정 접속 테스트가 실패하였습니다."
else
  echo "  접속 성공) ${MYSQL_TEST}"
fi
echo

if [ -z ${GUIDE_APP_INSTALL} ]; then
  outputInfo "[ ${INPUT_USER} ] 시스템, 디비 계정이 생성되었습니다."
  echo
  echo "  앱 자동 설치) ./app-install.sh 으로 원하는 앱을 쉽게 설치하실 수 있습니다."
  echo "  앱 수동 설치) ./apps/laravel51/template-server.conf 예제를 참고하여,  /etc/nginx/conf.d/${INPUT_USER}.conf 설정 파일을 생성하면 됩니다."
fi

# SFTP 전용 설정
if [ ${INPUT_SFTP_ONLY} = "1" ]; then
  echo
  notice "SFTP 전용 사용자로 설정합니다."
  ${STACK_ROOT}/scripts/sftp-setup.sh --user=${INPUT_USER}
fi
