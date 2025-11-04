#!/usr/bin/env bash
# Rhymix - https://rhymix.org/
# GitHub: https://github.com/rhymix/rhymix
# updated: 2025-10-24

if [ $(whoami) = "root" ]; then
  echo "root 계정으로 실행할 수 없습니다.  설치된 사용자 계정으로 실행해 주세요.  ex) su - new_user"
  exit 1
fi

cd ~ \
&& mkdir master \
&& cd master \
&& git clone --depth=1 --branch=master https://github.com/rhymix/rhymix.git public \
&& cd public \

# Composer 의존성 설치
if [ -f /usr/local/bin/composer ]; then
  /usr/local/bin/composer install --no-dev --optimize-autoloader
fi

# files 디렉토리 생성 및 권한 설정
mkdir -p files/cache files/config files/attach files/member_extra_info files/thumbnails
chmod -v 0707 files
chmod -v 0707 files/*

# common/defaults 디렉토리 권한 설정
chmod -v 0707 common/defaults

# 쉬운 설치 지원 (config 파일 생성을 위한 권한)
chmod -v a+rw ./

echo ""
echo "==============================================="
echo "Rhymix 설치 준비가 완료되었습니다."
echo "웹브라우저로 접속하여 설치를 계속 진행하여 주세요."
echo ""
echo "설치 URL: http://도메인주소/"
echo "관리자 페이지: http://도메인주소/admin"
echo "==============================================="

