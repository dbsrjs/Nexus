/* ONE 워크스페이스 — 프론트엔드 API 클라이언트
 * 백엔드(NestJS, http://localhost:3000/api)와 통신. 토큰은 localStorage 보관.
 * window.API 전역으로 노출되어 index.html의 React 컴포넌트에서 사용한다.
 */
(function () {
  const BASE = (window.ONEWORK_API_BASE || 'http://localhost:3000/api').replace(/\/+$/, '');
  const ORIGIN = BASE.replace(/\/api$/, '');
  const TOKEN_KEY = 'onework_token';
  const REFRESH_KEY = 'onework_refresh';
  const USER_KEY = 'onework_user';

  class ApiError extends Error {
    constructor(status, message, body) {
      super(message || ('HTTP ' + status));
      this.status = status;
      this.body = body;
    }
  }

  const getToken = () => localStorage.getItem(TOKEN_KEY);
  const getRefresh = () => localStorage.getItem(REFRESH_KEY);
  const getUser = () => {
    try { return JSON.parse(localStorage.getItem(USER_KEY) || 'null'); } catch { return null; }
  };
  function setSession(token, refreshToken, user) {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    if (refreshToken) localStorage.setItem(REFRESH_KEY, refreshToken);
    if (user) localStorage.setItem(USER_KEY, JSON.stringify(user));
  }
  function clearSession() {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(REFRESH_KEY);
    localStorage.removeItem(USER_KEY);
  }

  async function tryRefresh() {
    const rt = getRefresh();
    if (!rt) return false;
    try {
      const r = await fetch(BASE + '/auth/refresh', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: rt }),
      });
      if (!r.ok) return false;
      const d = await r.json();
      setSession(d.token, d.refreshToken, null);
      return true;
    } catch { return false; }
  }

  // Core authed request with a single transparent refresh-retry on 401.
  async function req(method, path, body, _retried) {
    const headers = {};
    const token = getToken();
    if (token) headers['Authorization'] = 'Bearer ' + token;

    const opts = { method, headers };
    if (body instanceof FormData) {
      opts.body = body; // browser sets multipart boundary
    } else if (body !== undefined) {
      headers['Content-Type'] = 'application/json';
      opts.body = JSON.stringify(body);
    }

    const res = await fetch(BASE + path, opts);

    if (res.status === 401 && !_retried && getRefresh()) {
      if (await tryRefresh()) return req(method, path, body, true);
    }
    if (res.status === 401) { clearSession(); throw new ApiError(401, '인증이 만료되었습니다.'); }

    const text = await res.text();
    let data = null;
    try { data = text ? JSON.parse(text) : null; } catch { data = text; }
    if (!res.ok) throw new ApiError(res.status, (data && data.message) || res.statusText, data);
    return data;
  }

  const API = {
    base: BASE,
    origin: ORIGIN,
    getToken,
    getUser,
    isAuthed: () => !!getToken(),

    async login(email, password) {
      const r = await fetch(BASE + '/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const d = await r.json().catch(() => null);
      if (!r.ok) throw new ApiError(r.status, (d && d.message) || '로그인에 실패했습니다.', d);
      setSession(d.token, d.refreshToken, d.user);
      return d.user;
    },
    logout() { clearSession(); },

    // users
    me: () => req('GET', '/me'),
    users: () => req('GET', '/users'),

    // channels + messages
    channels: () => req('GET', '/channels'),
    messages: (channelId, cursor) =>
      req('GET', '/channels/' + channelId + '/messages' + (cursor ? '?cursor=' + encodeURIComponent(cursor) : '')),
    sendMessage: (channelId, body) => req('POST', '/channels/' + channelId + '/messages', { body }),
    editMessage: (id, body) => req('PATCH', '/messages/' + id, { body }),
    messageEdits: (id) => req('GET', '/messages/' + id + '/edits'),

    // files
    channelFiles: (channelId) => req('GET', '/channels/' + channelId + '/files'),
    uploadFile: (channelId, file) => {
      const fd = new FormData();
      fd.append('file', file);
      return req('POST', '/channels/' + channelId + '/files', fd);
    },
    fileUrl: (id) => BASE + '/files/' + id,

    // issues
    issues: () => req('GET', '/issues'),
    issue: (id) => req('GET', '/issues/' + id),
    createIssue: (data) => req('POST', '/issues', data),
    updateIssue: (id, data) => req('PATCH', '/issues/' + id, data),
    addIssueComment: (id, body) => req('POST', '/issues/' + id + '/comments', { body }),

    // worklogs / attendance
    worklogs: () => req('GET', '/worklogs'),
    createWorklog: (data) => req('POST', '/worklogs', data),
    attendance: () => req('GET', '/attendance'),
    checkIn: () => req('POST', '/attendance/check-in'),
    checkOut: () => req('POST', '/attendance/check-out'),

    // notices / notifications
    notices: () => req('GET', '/notices'),
    notifications: () => req('GET', '/notifications'),
    unreadCount: () => req('GET', '/notifications/unread-count'),
    readNotification: (id) => req('POST', '/notifications/' + id + '/read'),

    // permissions (admin)
    permissions: () => req('GET', '/admin/permissions'),
    setPermission: (channelId, role, data) => req('PUT', '/admin/permissions/' + channelId + '/' + role, data),

    // gitlab / ai
    gitlabRepos: () => req('GET', '/gitlab/repos'),
    syncGitlab: () => req('POST', '/gitlab/sync'),
    aiAnalyze: (data) => req('POST', '/ai/analyze', data),

    /** Connect Socket.IO with the current JWT. handler(event, payload). Returns the socket (or null). */
    connectSocket(handler) {
      if (!window.io) { console.warn('[api] socket.io client not loaded'); return null; }
      const socket = window.io(ORIGIN, {
        auth: { token: getToken() },
        transports: ['websocket', 'polling'],
      });
      ['message:new', 'message:edited', 'notification:new', 'read:synced', 'typing'].forEach((ev) =>
        socket.on(ev, (payload) => handler(ev, payload)),
      );
      return socket;
    },
  };

  window.API = API;
  window.ApiError = ApiError;
})();
