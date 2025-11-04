#!/usr/bin/env bash
# Rhymix Update Script
# https://rhymix.org/
# GitHub: https://github.com/rhymix/rhymix
# updated: 2025-10-24

if [ $(whoami) = "root" ]; then
  echo "root 계정으로 실행할 수 없습니다.  설치된 사용자 계정으로 실행해 주세요.  ex) su - new_user"
  exit 1
fi

echo "==============================================="
echo "Rhymix 업데이트를 시작합니다."
echo "==============================================="
echo ""

# 현재 디렉토리 확인
if [ ! -f "index.php" ] || [ ! -d "common" ]; then
  echo "오류: Rhymix 디렉토리에서 실행해주세요."
  echo "예시: cd ~/master/public && ./update.sh"
  exit 1
fi

# 백업 생성
BACKUP_DIR="../backup_$(date +%Y%m%d_%H%M%S)"
echo "1. 백업을 생성합니다: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -r files config "$BACKUP_DIR/"
echo "   - files, config 디렉토리 백업 완료"
echo ""

# Git Pull
echo "2. 최신 버전을 다운로드합니다."
git fetch origin
git pull origin master
echo ""

# Composer 업데이트
if [ -f /usr/local/bin/composer ]; then
  echo "3. Composer 의존성을 업데이트합니다."
  /usr/local/bin/composer install --no-dev --optimize-autoloader
  echo ""
else
  echo "3. Composer가 설치되지 않아 건너뜁니다."
  echo ""
fi

# 캐시 삭제
echo "4. 캐시를 삭제합니다."
rm -rf files/cache/*
echo "   - 캐시 삭제 완료"
echo ""

echo "==============================================="
echo "Rhymix 업데이트가 완료되었습니다."
echo "웹브라우저에서 사이트에 접속하여 정상 작동을 확인하세요."
echo ""
echo "백업 위치: $BACKUP_DIR"
echo "==============================================="

