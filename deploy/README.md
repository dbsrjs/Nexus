# 배포 — VM 한 대 + Cloudflare Tunnel + R2

설계와 이유는 [docs/인프라-설계.md](../docs/인프라-설계.md). 여기는 절차다.

```
브라우저 · 앱 ──https──▶ Cloudflare ──터널──▶ cloudflared ─▶ web(nginx) ─┬─ /            Flutter 웹 정적 파일
                                                                      ├─ /api/        server:3000
                                                                      └─ /socket.io/  server:3000 (WebSocket)
                                                 server ─▶ postgres(pgvector) · R2(첨부) · Gemini(AI)
```

**웹과 API 를 한 주소로 낸다.** 웹을 Pages 같은 다른 사이트에 두면 리프레시 쿠키
(`SameSite=Lax`)가 웹의 요청에 실리지 않아 15분마다 로그인이 풀린다(nginx.conf 머리 주석).

## 처음 한 번

1. **VM** — Docker 와 Compose 플러그인을 깐다. 인바운드 포트는 SSH 하나만 연다(터널은 밖으로 나가는 연결이다).
2. **저장소** — `git clone https://github.com/dbsrjs/Nexus.git && cd Nexus/deploy`
3. **R2 버킷** — Cloudflare 대시보드에서 버킷(`nexus-attachments`)을 만든다.
   **수명주기 규칙이 없는지 확인한다** — 무기한 보관이 제품 특성이다.
   API 토큰은 그 버킷에만 «Object Read & Write» 로 발급해 키 둘을 받는다.
4. **터널** — Zero Trust → Networks → Tunnels 에서 터널을 만들고 토큰을 받는다.
   공개 호스트 이름(예: `nexus.example.com`)의 서비스를 **`http://web:80`** 으로 둔다.
5. **GitHub OAuth App** — 콜백을 `https://<공개 주소>/api/auth/github/callback` 으로 하나 더 만든다(개발용과 따로).
6. **값** — `cp .env.prod.example .env` 후 채운다. 무작위 값은 base64url 로 만든다(파일 머리 주석).
   **`OAUTH_TOKEN_KEY` 를 잃으면 DB 에 든 GitHub 토큰을 못 푼다** — 백업과 함께 보관한다.
7. **웹 빌드 넣기** — 아래 절.
8. **띄우기**
   ```bash
   docker compose -f docker-compose.prod.yml --profile tunnel up -d --build
   docker compose -f docker-compose.prod.yml run --rm migrate npm run seed   # 데모 스페이스(1회)
   ```
9. **확인** — VM 안에서 `curl -sI http://127.0.0.1:8080/` 가 200 · `Cache-Control: no-cache`,
   `docker compose -f docker-compose.prod.yml logs server` 에 `스토리지 드라이버: s3` · `S3 버킷 확인` · `trust proxy: 1`.

## 웹 빌드 넣기

`API_BASE` 는 **공개 주소 그 자체**다(웹과 API 가 한 오리진). 빌드는 Flutter 가 있는 개발 PC 에서 한다.

```bash
cd app
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE=https://nexus.example.com
scp -r build/web/. <vm>:~/Nexus/deploy/web/
```

**`--no-web-resources-cdn` 을 붙인다.** 빼면 CanvasKit(렌더러)을 `www.gstatic.com` 에서 받는데, 그 주소가 막힌
네트워크(회사 방화벽 · 이 검증 환경)에서는 **흰 화면만 뜬다**(2026-10-09 겪음). 붙이면 같은 오리진에서 받는다.

초대 링크(`/#/invite/<코드>`)는 이 주소를 기준으로 만들어진다 — 앱의 `WEB_BASE` 기본값이 `API_BASE` 다(웹과 API 가 한 오리진).

nginx 가 정적 파일 전부에 `Cache-Control: no-cache` 를 붙인다 — Flutter 웹 산출물은 이름에 해시가
없어 캐시를 허락하면 배포 뒤에도 옛 `main.dart.js` 가 남는다. 파일을 바꾸면 컨테이너를 다시 띄울 필요가 없다.

## 갱신

```bash
git pull
docker compose -f docker-compose.prod.yml --profile tunnel up -d --build   # migrate 가 먼저 돈다
```

`server` 는 `migrate` 가 성공해야 새로 뜬다(`service_completed_successfully`). 실패하면 `up` 이 거기서
멈춘다 — `docker compose -f docker-compose.prod.yml logs migrate` 로 본다.

## 백업 · 복구

`backup` 서비스가 하루 한 번 `backups/nexus-<UTC 시각>.dump` 를 쓰고 이레가 지난 것을 지운다.
**VM 디스크에만 있다** — VM 을 잃으면 함께 잃는다. 밖으로 옮기는 것은 아직 없다(인프라 설계 §7).

```bash
# 복구 — 빈 DB 에 덮는다. 서버를 먼저 내린다.
docker compose -f docker-compose.prod.yml stop server
docker compose -f docker-compose.prod.yml exec -T postgres \
  pg_restore -U nexus -d nexus --clean --if-exists < backups/nexus-XXXX.dump
docker compose -f docker-compose.prod.yml start server
```

## 확인한 것 · 확인하지 못한 것 (2026-10-09)

- 확인: 이 구성을 로컬 Docker 로 띄워 `migrate` → `server` → `web` 순서 기동, nginx 경유 계약 검증
  (실시간 56 · 첨부 43 · 멤버 97 · 프레즌스 30 — WebSocket 업그레이드 포함), 정적 파일 `no-cache` · 경로 새로고침 200,
  `Cf-Connecting-IP` 가 `req.ip` 로 들어가고 지어낸 `X-Forwarded-For` 는 무시됨, `backup` 첫 덤프 생성.
  S3 드라이버는 SeaweedFS 로 첨부 43 · 설정 53(CI 가 push 마다 다시 돈다).
- **확인하지 못한 것**: 실제 R2 · 실제 Cloudflare Tunnel · ARM VM. 특히 **터널을 지난 요청에
  `Cf-Connecting-IP` 가 실리는지**는 Cloudflare 문서상 그렇다는 것까지만 알고 직접 보지 못했다 —
  배포 뒤 `refresh_tokens.ip` 에 실제 주소가 찍히는지 본다(전부 같은 사설 주소면 로그인 시도 제한이 모두를 한 사람으로 센다).
  Dockerfile 의 `apt-get install openssl` 줄은 이 검증 환경의 송신 정책이 Debian 미러를 막아 돌리지 못했다(같은 bookworm 의 libssl 을 옮겨 대신했다).
