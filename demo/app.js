const state = {
  apiBase: "",
  users: { a: null, b: null },
  group: null,
  pet: null,
  sockets: { a: null, b: null },
  revealed: new Set(),
  countdowns: new Map(),
};

const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => [...document.querySelectorAll(selector)];

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function actorLabel(actor) {
  return actor === "a" ? "A" : actor === "b" ? "B" : "system";
}

function logEvent(actor, message) {
  const row = document.createElement("li");
  const time = new Date().toLocaleTimeString("ko-KR", { hour12: false });
  row.innerHTML = `<time>${time}</time><span class="event-${actor}">${actorLabel(actor)}</span><p>${escapeHtml(message)}</p>`;
  const log = $("#event-log");
  log.prepend(row);
  while (log.children.length > 80) log.lastElementChild.remove();
}

let toastTimer;
function toast(message, isError = false) {
  const node = $("#toast");
  node.textContent = message;
  node.classList.toggle("error", isError);
  node.classList.add("visible");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => node.classList.remove("visible"), 2600);
}

function setStatus(selector, text, kind) {
  const node = $(selector);
  node.textContent = text;
  node.className = `status status-${kind}`;
}

function authHeaders(actor) {
  return { Authorization: `Bearer ${state.users[actor].token}` };
}

async function request(path, { actor, method = "GET", json, body } = {}) {
  const headers = actor ? authHeaders(actor) : {};
  if (json !== undefined) headers["Content-Type"] = "application/json";
  const response = await fetch(`${state.apiBase}${path}`, {
    method,
    headers,
    body: json !== undefined ? JSON.stringify(json) : body,
  });
  if (response.status === 204) return null;
  const contentType = response.headers.get("content-type") || "";
  const payload = contentType.includes("application/json") ? await response.json() : await response.text();
  if (!response.ok) {
    const message = payload?.error?.message || payload?.detail || `${response.status} ${response.statusText}`;
    throw new Error(message);
  }
  return payload;
}

async function checkHealth() {
  try {
    const health = await request("/health");
    setStatus("#api-status", `API ${health.db === "ok" ? "정상" : "DB 오류"}`, health.db === "ok" ? "ok" : "error");
    return health.db === "ok";
  } catch (error) {
    setStatus("#api-status", "API 연결 실패", "error");
    throw error;
  }
}

async function register(displayName, deviceUid) {
  return request("/auth/register", {
    method: "POST",
    json: { display_name: displayName, device_uid: deviceUid },
  });
}

function disconnectSockets() {
  Object.values(state.sockets).forEach((socket) => socket?.disconnect());
  state.sockets = { a: null, b: null };
  ["a", "b"].forEach((actor) => $("#socket-" + actor).classList.remove("connected"));
}

function attachSocket(actor) {
  const origin = state.apiBase.replace(/\/v1\/?$/, "");
  const socket = io(`${origin}/rt`, {
    path: "/socket.io",
    transports: ["websocket"],
    auth: { token: state.users[actor].token },
    reconnection: true,
  });
  state.sockets[actor] = socket;

  socket.on("connect", () => {
    $("#socket-" + actor).classList.add("connected");
    logEvent(actor, `Socket.IO 연결됨 (${socket.id})`);
    updateSocketSummary();
  });
  socket.on("disconnect", (reason) => {
    $("#socket-" + actor).classList.remove("connected");
    logEvent(actor, `Socket.IO 연결 종료: ${reason}`);
    updateSocketSummary();
  });
  socket.on("connect_error", (error) => {
    logEvent(actor, `Socket.IO 오류: ${error.message}`);
    updateSocketSummary();
  });
  ["doodle:new", "doodle:expired", "poke", "pet:activity", "pet:levelup", "diary:new"].forEach((event) => {
    socket.on(event, async (payload) => {
      logEvent(actor, `${event} ${JSON.stringify(payload)}`);
      if (event.startsWith("doodle:")) await loadDoodles();
      if (event.startsWith("pet:")) await loadPet();
    });
  });
}

function updateSocketSummary() {
  const count = Object.values(state.sockets).filter((socket) => socket?.connected).length;
  setStatus("#socket-status", `소켓 ${count}/2`, count === 2 ? "ok" : count ? "idle" : "error");
}

function setControls(enabled) {
  $$(".send-button, .poke-button, .pat-button, #refresh-button, #report-button").forEach((button) => {
    button.disabled = !enabled;
  });
}

async function bootDemo() {
  const button = $("#boot-button");
  button.disabled = true;
  setControls(false);
  disconnectSockets();
  state.apiBase = $("#api-base").value.trim().replace(/\/$/, "");
  state.revealed.clear();
  try {
    await checkHealth();
    const nonce = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
    const [registeredA, registeredB] = await Promise.all([
      register("종화", `demo-a-${nonce}`),
      register("종혁", `demo-b-${nonce}`),
    ]);
    state.users.a = { ...registeredA.user, token: registeredA.token };
    state.users.b = { ...registeredB.user, token: registeredB.token };

    const created = await request("/groups", {
      actor: "a",
      method: "POST",
      json: { name: "Memory Pager 데모", pet_name: "삐삐" },
    });
    state.group = created.group;
    state.pet = created.pet;
    await request("/groups/join", {
      actor: "b",
      method: "POST",
      json: { invite_code: state.group.invite_code },
    });

    renderIdentity();
    attachSocket("a");
    attachSocket("b");
    await refreshAll();
    setControls(true);
    logEvent("system", `그룹 ${state.group.id}에 사용자 A/B 매칭 완료`);
    toast("2인 데모 공간이 준비되었습니다.");
  } catch (error) {
    logEvent("system", `초기화 실패: ${error.message}`);
    toast(error.message, true);
  } finally {
    button.disabled = false;
  }
}

function renderIdentity() {
  ["a", "b"].forEach((actor) => {
    const user = state.users[actor];
    $("#name-" + actor).textContent = user.display_name;
    $("#identity-" + actor).textContent = `user ${user.id} · group ${state.group.id}`;
  });
  $("#group-name").textContent = state.group.name;
}

async function sendDoodle(actor, form) {
  const text = $("#message-" + actor).value.trim();
  if (!text) return toast("메시지를 입력하세요.", true);
  const mode = form.querySelector(`input[name="mode-${actor}"]:checked`).value;
  const data = new FormData();
  data.set("mode", mode);
  data.set("content_type", "text");
  data.set("text_body", text);
  try {
    const doodle = await request("/doodles", { actor, method: "POST", body: data });
    $("#message-" + actor).value = "";
    logEvent(actor, `낙서 ${doodle.id} 전송 (${mode})`);
    await Promise.all([loadDoodles(), loadPet()]);
  } catch (error) {
    toast(error.message, true);
  }
}

async function sendPoke(actor) {
  const target = actor === "a" ? "b" : "a";
  try {
    await request(`/groups/${state.group.id}/pokes`, {
      actor,
      method: "POST",
      json: { to_user_id: state.users[target].id },
    });
    logEvent(actor, `${target.toUpperCase()}에게 찌르기 전송`);
    await loadPet();
  } catch (error) {
    toast(error.message, true);
  }
}

async function patPet(actor) {
  try {
    const response = await request(`/pets/${state.pet.id}/pat`, { actor, method: "POST" });
    $("#pet-response p").textContent = `${state.users[actor].display_name}: ${response.utterance} (+${response.exp_gained} EXP)`;
    logEvent(actor, `펫 쓰다듬기: ${response.activity}`);
    await loadPet();
  } catch (error) {
    toast(error.message, true);
  }
}

async function loadPet() {
  if (!state.group) return;
  state.pet = await request(`/groups/${state.group.id}/pet`, { actor: "a" });
  $("#pet-stats").innerHTML = `<span>Lv. ${state.pet.level}</span><span>EXP ${state.pet.exp}</span><span>Coin ${state.pet.coins}</span>`;
}

function receiverFor(doodle) {
  return String(doodle.sender_id) === String(state.users.a.id) ? "b" : "a";
}

async function loadDoodles() {
  if (!state.group) return;
  const [viewA, viewB] = await Promise.all([
    request(`/groups/${state.group.id}/doodles?limit=50`, { actor: "a" }),
    request(`/groups/${state.group.id}/doodles?limit=50`, { actor: "b" }),
  ]);
  const byB = new Map(viewB.items.map((item) => [item.id, item]));
  const merged = viewA.items.map((item) => {
    const receiver = receiverFor(item);
    return receiver === "a" ? item : { ...item, viewed_by_me: byB.get(item.id)?.viewed_by_me ?? false };
  });
  renderTimeline(merged);
}

function renderTimeline(items) {
  const timeline = $("#timeline");
  if (!items.length) {
    timeline.innerHTML = '<div class="empty-state">아직 공유된 메시지가 없습니다.</div>';
    return;
  }
  timeline.innerHTML = items.map((item) => {
    const sender = String(item.sender_id) === String(state.users.a.id) ? "a" : "b";
    const isLocked = item.mode === "ephemeral" && !item.viewed_by_me && !state.revealed.has(item.id);
    const isRevealed = state.revealed.has(item.id);
    const message = isLocked ? "열기 전까지 내용이 숨겨집니다." : item.text_body || `[${item.content_type}]`;
    const action = isLocked
      ? `<button class="reveal-button" data-reveal="${item.id}"><i data-lucide="lock-keyhole"></i> 열기</button>`
      : isRevealed
        ? `<span class="countdown" data-countdown="${item.id}">5.0s</span>`
        : "";
    return `<article class="doodle-item" data-doodle="${item.id}">
      <span class="doodle-sender actor-${sender}">${sender.toUpperCase()}</span>
      <div class="doodle-copy">
        <div class="doodle-meta"><strong>${escapeHtml(state.users[sender].display_name)}</strong><span>${new Date(item.created_at).toLocaleTimeString("ko-KR", { hour: "2-digit", minute: "2-digit" })}</span>${item.mode === "ephemeral" ? '<span class="mode-tag">5초</span>' : ""}</div>
        <p>${escapeHtml(message)}</p>
      </div>${action}
    </article>`;
  }).join("");
  window.lucide?.createIcons();
  $$('[data-reveal]').forEach((button) => button.addEventListener("click", () => revealDoodle(button.dataset.reveal)));
}

async function revealDoodle(doodleId) {
  const list = await request(`/groups/${state.group.id}/doodles?limit=50`, { actor: "a" });
  const doodle = list.items.find((item) => item.id === doodleId);
  if (!doodle) return;
  const receiver = receiverFor(doodle);
  try {
    const viewed = await request(`/doodles/${doodleId}/view`, { actor: receiver, method: "POST" });
    state.revealed.add(doodleId);
    startCountdown(doodleId, viewed.expires_at);
    logEvent(receiver, `사라지기 낙서 ${doodleId} 확인`);
    await loadDoodles();
  } catch (error) {
    toast(error.message, true);
  }
}

function startCountdown(doodleId, expiresAt) {
  clearInterval(state.countdowns.get(doodleId));
  const end = new Date(expiresAt).getTime();
  const timer = setInterval(() => {
    const node = document.querySelector(`[data-countdown="${doodleId}"]`);
    const remaining = Math.max(0, end - Date.now());
    if (node) node.textContent = `${(remaining / 1000).toFixed(1)}s`;
    if (!remaining) {
      clearInterval(timer);
      state.countdowns.delete(doodleId);
    }
  }, 100);
  state.countdowns.set(doodleId, timer);
}

async function generateReport() {
  const parts = new Intl.DateTimeFormat("en", {
    timeZone: "Asia/Seoul",
    year: "numeric",
    month: "2-digit",
  }).formatToParts(new Date());
  const year = parts.find((part) => part.type === "year").value;
  const monthNumber = parts.find((part) => part.type === "month").value;
  const month = `${year}-${monthNumber}`;
  try {
    const report = await request(`/groups/${state.group.id}/reports/${month}/generate`, { actor: "a", method: "POST" });
    $("#pet-response p").textContent = `${month}: 사진 ${report.photo_count}, 그림 ${report.drawing_count}, 글 ${report.text_count}, 찌르기 ${report.poke_count}`;
    logEvent("system", `${month} 월간 레포트 생성 완료`);
  } catch (error) {
    toast(error.message, true);
  }
}

async function refreshAll() {
  try {
    await Promise.all([checkHealth(), loadPet(), loadDoodles()]);
  } catch (error) {
    toast(error.message, true);
  }
}

$("#boot-button").addEventListener("click", bootDemo);
$("#refresh-button").addEventListener("click", refreshAll);
$("#report-button").addEventListener("click", generateReport);
$("#clear-log").addEventListener("click", () => { $("#event-log").innerHTML = ""; });
$$('[data-composer]').forEach((form) => form.addEventListener("submit", (event) => {
  event.preventDefault();
  sendDoodle(form.dataset.composer, form);
}));
$$('.poke-button').forEach((button) => button.addEventListener("click", () => sendPoke(button.dataset.from)));
$$('.pat-button').forEach((button) => button.addEventListener("click", () => patPet(button.dataset.actor)));

window.lucide?.createIcons();
