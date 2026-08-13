#!/bin/bash
#
# WSL2 Ubuntu 안에 Nexus 개발용 Postgres + pgvector 를 준비한다. (root 로 실행)
#
# 한 번만 실행하면 되고, 여러 번 돌려도 안전하다(멱등).
# Docker 가 있는 환경이라면 이 스크립트 대신 `npm run db:up:docker` 를 쓰면 된다.
#
# 사용: npm run db:setup   (server/scripts/db-setup-wsl.ps1 이 이 파일을 호출한다)
set -euo pipefail

DB_NAME="${NEXUS_DB_NAME:-nexus}"
DB_USER="${NEXUS_DB_USER:-nexus}"
DB_PASS="${NEXUS_DB_PASS:-nexus}"

echo "=== 1) 패키지 설치 ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

# Ubuntu 버전마다 기본 Postgres 메이저 버전이 다르다(24.04→16, 26.04→18).
# 메타패키지를 먼저 깔고, 실제로 설치된 버전에 맞는 pgvector 를 뒤이어 깐다.
apt-get install -y -qq postgresql

PGVER="$(ls -1 /etc/postgresql 2>/dev/null | sort -V | tail -1)"
if [ -z "$PGVER" ]; then
  echo "postgresql 설치를 확인할 수 없습니다." >&2
  exit 1
fi
echo "  PostgreSQL 메이저 버전: $PGVER"

if ! apt-get install -y -qq "postgresql-${PGVER}-pgvector"; then
  echo "postgresql-${PGVER}-pgvector 설치 실패." >&2
  echo "pgvector 없이는 init 마이그레이션이 CREATE EXTENSION 에서 실패합니다." >&2
  exit 1
fi

CONF="/etc/postgresql/${PGVER}/main/postgresql.conf"
HBA="/etc/postgresql/${PGVER}/main/pg_hba.conf"

echo "=== 2) 네트워크 설정 ==="
# WSL2 는 Windows -> Linux 로 localhost 를 포워딩하지만, 대상이 루프백에만
# 바인딩되어 있으면 닿지 않는다. 모든 인터페이스에서 듣게 한다.
# (WSL VM 은 Windows 호스트 뒤에 있고 외부에 노출되지 않는다.)
sed -i "s/^#\?listen_addresses.*/listen_addresses = '*'/" "$CONF"

if ! grep -q "nexus-dev" "$HBA"; then
  cat >> "$HBA" <<'EOF'

# nexus-dev: Windows 호스트에서 오는 개발용 접속
host    all             all             0.0.0.0/0               scram-sha-256
host    all             all             ::/0                    scram-sha-256
EOF
fi

echo "=== 3) 기동 ==="
# systemd 가 켜져 있으면(/etc/wsl.conf 의 [boot] systemd=true) 배포판 기동 시
# Postgres 도 자동으로 뜬다. 없으면 pg_ctlcluster 로 직접 올린다.
pg_ctlcluster "$PGVER" main restart 2>/dev/null || service postgresql restart
sleep 2
pg_isready -q && echo "  postgres 응답 OK"

echo "=== 4) 역할 · 데이터베이스 ==="
psql_su() { su - postgres -c "psql -tAc \"$1\""; }

if [ "$(psql_su "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'")" != "1" ]; then
  psql_su "CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}'" >/dev/null
  echo "  역할 생성: ${DB_USER}"
else
  echo "  역할 이미 있음: ${DB_USER}"
fi

if [ "$(psql_su "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'")" != "1" ]; then
  su - postgres -c "createdb -O ${DB_USER} ${DB_NAME}"
  echo "  DB 생성: ${DB_NAME}"
else
  echo "  DB 이미 있음: ${DB_NAME}"
fi

# init 마이그레이션이 CREATE EXTENSION vector 를 실행한다. 확장 생성은 슈퍼유저
# 권한이 필요하므로 개발 DB 에서는 부여한다. (운영이라면 DBA 가 미리 확장을 만들고
# 이 권한은 주지 않는다.)
psql_su "ALTER ROLE ${DB_USER} SUPERUSER" >/dev/null

echo "=== 5) 확인 ==="
echo "  pgvector: $(psql_su "SELECT default_version FROM pg_available_extensions WHERE name='vector'")"
echo "  listen_addresses: $(psql_su 'SHOW listen_addresses')"
PGPASSWORD="${DB_PASS}" psql -h 127.0.0.1 -U "${DB_USER}" -d "${DB_NAME}" -tAc \
  "SELECT '  접속 확인: ' || current_user || '@' || current_database()"

cat <<EOF

준비 완료. server/.env 의 DATABASE_URL 을 아래로 맞추십시오:

  DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@127.0.0.1:5432/${DB_NAME}

  ⚠ localhost 가 아니라 127.0.0.1 이어야 합니다. Windows 에서 localhost 는
    ::1(IPv6)로 먼저 해석되는데 WSL 포워딩은 IPv4 만 동작합니다.

다음:
  npm run db:up                                # 세션 유지 + 기동 대기
  npm --prefix server exec prisma migrate deploy
  npm run db:seed
EOF
