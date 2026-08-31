"use strict";

const copy = {
  id: {
    skip: "Lewati ke konten", argument: "Kode penting tetap lokal, terlihat hanya ketika dibutuhkan.", accessEyebrow: "AKSES DIBUTUHKAN",
    accessTitle: "Hubungkan ke vault", accessHelp: "Token hanya disimpan dalam memori tab ini dan hilang saat halaman ditutup.", tokenLabel: "Token akses",
    connect: "Hubungkan", controls: "Kontrol vault", search: "Cari akun", add: "Tambah OTP", theme: "Tema terang", themeDark: "Tema gelap", language: "Bahasa",
    statusLabel: "Status vault", total: "Total", visible: "Terlihat", sync: "Sinkron", privacy: "Privasi", privacyValue: "Tersembunyi",
    newEntry: "ENTRI BARU", editEntry: "EDIT ENTRI", editorTitle: "Tambahkan authenticator", editorEditTitle: "Perbarui authenticator", close: "Tutup",
    label: "Label", issuer: "Issuer", account: "Account", secret: "Secret BASE32", digits: "Digits", period: "Period", algorithm: "Algorithm",
    qr: "QR OTP (PNG/JPG/WebP, maks. 1 MB)", save: "Simpan", scan: "Baca QR", vaultEyebrow: "VAULT TERENKRIPSI", vaultTitle: "Authenticator",
    refresh: "Muat ulang", loading: "Membuka daftar…", loadingHelp: "Vault tetap terenkripsi di disk.", empty: "Vault masih kosong", emptyHelp: "Tambahkan authenticator pertama untuk mulai.",
    ready: "Vault siap", readyHelp: "Kode tetap tersembunyi sampai Anda memilih Tampilkan.", unauthorized: "Token ditolak", unauthorizedHelp: "Masukkan token akses yang benar.",
    offline: "Tidak terhubung", offlineHelp: "Periksa server SAT lalu muat ulang.", error: "Permintaan gagal", reveal: "Tampilkan", hide: "Sembunyikan", copy: "Salin", copied: "Kode disalin",
    edit: "Edit", delete: "Hapus", destructive: "TINDAKAN DESTRUKTIF", deleteTitle: "Hapus authenticator?", deletePrompt: "Entri {label} akan dihapus dari vault terenkripsi.", cancel: "Batal",
    saved: "Authenticator disimpan", updated: "Authenticator diperbarui", deleted: "Authenticator dihapus", qrReady: "QR dibaca. Periksa data sebelum menyimpan.",
    honestEyebrow: "BATAS SISTEM", honestTitle: "Keamanan berhenti di perangkat ini", honestText: "SAT melindungi vault saat tersimpan. Perangkat yang sudah dikuasai pihak lain tetap dapat merekam layar atau input saat vault sedang digunakan."
  },
  en: {
    skip: "Skip to content", argument: "Important codes stay local and appear only when needed.", accessEyebrow: "ACCESS REQUIRED", accessTitle: "Connect to the vault",
    accessHelp: "The token stays in this tab's memory and disappears when the page closes.", tokenLabel: "Access token", connect: "Connect", controls: "Vault controls",
    search: "Search accounts", add: "Add OTP", theme: "Light theme", themeDark: "Dark theme", language: "Language", statusLabel: "Vault status", total: "Total",
    visible: "Visible", sync: "Synced", privacy: "Privacy", privacyValue: "Hidden", newEntry: "NEW ENTRY", editEntry: "EDIT ENTRY", editorTitle: "Add authenticator",
    editorEditTitle: "Update authenticator", close: "Close", label: "Label", issuer: "Issuer", account: "Account", secret: "BASE32 secret", digits: "Digits",
    period: "Period", algorithm: "Algorithm", qr: "OTP QR (PNG/JPG/WebP, max 1 MB)", save: "Save", scan: "Read QR", vaultEyebrow: "ENCRYPTED VAULT",
    vaultTitle: "Authenticators", refresh: "Reload", loading: "Opening list…", loadingHelp: "The vault stays encrypted on disk.", empty: "The vault is empty",
    emptyHelp: "Add the first authenticator to begin.", ready: "Vault ready", readyHelp: "Codes stay hidden until you choose Reveal.", unauthorized: "Token rejected",
    unauthorizedHelp: "Enter the correct access token.", offline: "Not connected", offlineHelp: "Check the SAT server and reload.", error: "Request failed", reveal: "Reveal",
    hide: "Hide", copy: "Copy", copied: "Code copied", edit: "Edit", delete: "Delete", destructive: "DESTRUCTIVE ACTION", deleteTitle: "Delete authenticator?",
    deletePrompt: "The {label} entry will be removed from the encrypted vault.", cancel: "Cancel", saved: "Authenticator saved", updated: "Authenticator updated",
    deleted: "Authenticator deleted", qrReady: "QR read. Check the values before saving.", honestEyebrow: "SYSTEM LIMIT", honestTitle: "Security ends at this device",
    honestText: "SAT protects the vault at rest. A compromised device can still record the screen or input while the vault is in use."
  }
};

const elements = Object.fromEntries([
  "accessGate", "accessForm", "tokenInput", "searchInput", "addButton", "themeButton", "languageSelect", "totalCount", "visibleCount", "syncTime",
  "editor", "editorMode", "editorTitle", "closeEditor", "entryForm", "currentLabel", "labelInput", "issuerInput", "accountInput", "secretInput", "digitsInput",
  "periodInput", "algorithmInput", "qrInput", "scanButton", "refreshButton", "statePanel", "stateTitle", "stateMessage", "otpGrid", "otpTemplate", "deleteDialog",
  "deleteDescription", "confirmDelete", "toast"
].map((id) => [id, document.getElementById(id)]));

let language = localStorage.getItem("sat-language") === "en" ? "en" : "id";
let theme = localStorage.getItem("sat-theme") === "light" ? "light" : "dark";
let accessToken = "";
let entries = [];
let activeCodes = new Map();
let pendingDelete = "";
let toastTimer = 0;

function text(key, replacements = {}) {
  let value = copy[language][key] || key;
  Object.entries(replacements).forEach(([name, replacement]) => { value = value.replace(`{${name}}`, replacement); });
  return value;
}

function applyPreferences() {
  document.documentElement.lang = language;
  document.documentElement.dataset.theme = theme;
  elements.languageSelect.value = language;
  elements.themeButton.setAttribute("aria-pressed", String(theme === "light"));
  document.querySelectorAll("[data-i18n]").forEach((node) => { node.textContent = text(node.dataset.i18n); });
  document.querySelectorAll("[data-i18n-aria]").forEach((node) => { node.setAttribute("aria-label", text(node.dataset.i18nAria)); });
  elements.themeButton.textContent = text(theme === "dark" ? "theme" : "themeDark");
  renderEntries();
}

function showToast(message) {
  window.clearTimeout(toastTimer);
  elements.toast.textContent = message;
  elements.toast.hidden = false;
  toastTimer = window.setTimeout(() => { elements.toast.hidden = true; }, 3000);
}

function setState(state, title, message) {
  elements.statePanel.dataset.state = state;
  elements.stateTitle.textContent = title;
  elements.stateMessage.textContent = message;
  elements.statePanel.hidden = false;
}

async function api(path, options = {}) {
  const headers = { ...(options.headers || {}) };
  if (options.body) headers["Content-Type"] = "application/json";
  if (accessToken) headers["X-SAT-Token"] = accessToken;
  try {
    const response = await fetch(path, { ...options, headers });
    const data = await response.json().catch(() => ({}));
    if (response.status === 401) {
      elements.accessGate.hidden = false;
      setState("unauthorized", text("unauthorized"), text("unauthorizedHelp"));
    }
    return { ok: response.ok, status: response.status, data };
  } catch (error) {
    setState("error", text("offline"), text("offlineHelp"));
    return { ok: false, status: 0, data: { message: text("offlineHelp") } };
  }
}

function formatCode(code) {
  const midpoint = Math.ceil(code.length / 2);
  return `${code.slice(0, midpoint)} ${code.slice(midpoint)}`;
}

function filteredEntries() {
  const query = elements.searchInput.value.trim().toLocaleLowerCase(language);
  if (!query) return entries;
  return entries.filter((entry) => `${entry.label} ${entry.issuer} ${entry.account}`.toLocaleLowerCase(language).includes(query));
}

function updateCounts(visible) {
  elements.totalCount.value = String(entries.length);
  elements.totalCount.textContent = String(entries.length);
  elements.visibleCount.value = String(visible);
  elements.visibleCount.textContent = String(visible);
}

function hideCode(label, card) {
  activeCodes.delete(label);
  const code = card.querySelector(".otp-card__code");
  code.value = "";
  code.textContent = "••• •••";
  card.querySelector(".otp-card__value").dataset.state = "hidden";
  card.querySelector(".reveal-button").textContent = text("reveal");
  card.querySelector(".copy-button").disabled = true;
  const progress = card.querySelector("progress");
  progress.value = 0;
  card.querySelector(".otp-card__timer span").textContent = "—";
}

async function revealCode(entry, card) {
  if (activeCodes.has(entry.label)) {
    hideCode(entry.label, card);
    return;
  }
  const button = card.querySelector(".reveal-button");
  button.disabled = true;
  const result = await api(`/api/code?label=${encodeURIComponent(entry.label)}`);
  button.disabled = false;
  if (!result.ok) {
    showToast(result.data.message || text("error"));
    return;
  }
  activeCodes.set(entry.label, { code: result.data.code, remaining: result.data.expires_in, period: result.data.period, card });
  const code = card.querySelector(".otp-card__code");
  code.value = result.data.code;
  code.textContent = formatCode(result.data.code);
  card.querySelector(".otp-card__value").dataset.state = "visible";
  button.textContent = text("hide");
  card.querySelector(".copy-button").disabled = false;
  updateTimer(entry.label);
}

function updateTimer(label) {
  const active = activeCodes.get(label);
  if (!active) return;
  const progress = active.card.querySelector("progress");
  progress.max = active.period;
  progress.value = active.remaining;
  active.card.querySelector(".otp-card__timer span").textContent = `${active.remaining}s`;
}

async function copyActiveCode(label) {
  const active = activeCodes.get(label);
  if (!active) return;
  try {
    await navigator.clipboard.writeText(active.code);
    showToast(text("copied"));
  } catch (error) {
    showToast(text("error"));
  }
}

function openEditor(entry = null) {
  elements.entryForm.reset();
  elements.periodInput.value = "30";
  elements.digitsInput.value = "6";
  elements.algorithmInput.value = "SHA1";
  elements.currentLabel.value = entry ? entry.label : "";
  elements.editorMode.textContent = text(entry ? "editEntry" : "newEntry");
  elements.editorTitle.textContent = text(entry ? "editorEditTitle" : "editorTitle");
  elements.secretInput.required = !entry;
  if (entry) {
    elements.labelInput.value = entry.label;
    elements.issuerInput.value = entry.issuer || "";
    elements.accountInput.value = entry.account || "";
    elements.digitsInput.value = String(entry.digits || 6);
    elements.periodInput.value = String(entry.period || 30);
    elements.algorithmInput.value = entry.algo || "SHA1";
  }
  elements.editor.hidden = false;
  elements.labelInput.focus();
}

function renderEntries() {
  if (!elements.otpGrid) return;
  elements.otpGrid.replaceChildren();
  activeCodes.clear();
  const visible = filteredEntries();
  updateCounts(visible.length);
  visible.forEach((entry) => {
    const fragment = elements.otpTemplate.content.cloneNode(true);
    const card = fragment.querySelector(".otp-card");
    card.dataset.label = entry.label;
    card.querySelector(".otp-card__issuer").textContent = entry.issuer || "—";
    card.querySelector(".otp-card__label").textContent = entry.label;
    card.querySelector(".otp-card__account").textContent = entry.account || "—";
    card.querySelector(".otp-card__algorithm").textContent = `${entry.algo || "SHA1"} · ${entry.digits || 6}D`;
    const reveal = card.querySelector(".reveal-button");
    const copyButton = card.querySelector(".copy-button");
    const edit = card.querySelector(".edit-button");
    const remove = card.querySelector(".delete-button");
    [reveal, copyButton, edit, remove].forEach((button) => { button.textContent = text(button.dataset.i18n); });
    reveal.addEventListener("click", () => revealCode(entry, card));
    copyButton.addEventListener("click", () => copyActiveCode(entry.label));
    edit.addEventListener("click", () => openEditor(entry));
    remove.addEventListener("click", () => {
      pendingDelete = entry.label;
      elements.deleteDescription.textContent = text("deletePrompt", { label: entry.label });
      elements.deleteDialog.showModal();
    });
    elements.otpGrid.append(card);
  });
  elements.statePanel.hidden = visible.length > 0;
  if (!entries.length) setState("empty", text("empty"), text("emptyHelp"));
  else if (!visible.length) setState("ready", text("ready"), `${text("visible")}: 0`);
}

async function loadEntries() {
  setState("loading", text("loading"), text("loadingHelp"));
  const result = await api("/api/list");
  if (!result.ok) {
    if (result.status !== 401 && result.status !== 0) setState("error", text("error"), result.data.message || text("error"));
    return;
  }
  elements.accessGate.hidden = true;
  entries = result.data.entries || [];
  elements.syncTime.dateTime = new Date().toISOString();
  elements.syncTime.textContent = new Date().toLocaleTimeString(language);
  renderEntries();
  if (entries.length) setState("ready", text("ready"), text("readyHelp"));
}

async function submitEntry(event) {
  event.preventDefault();
  const current = elements.currentLabel.value;
  const payload = {
    label: elements.labelInput.value.trim(), issuer: elements.issuerInput.value.trim(), account: elements.accountInput.value.trim(),
    digits: Number(elements.digitsInput.value), period: Number(elements.periodInput.value), algo: elements.algorithmInput.value
  };
  const secret = elements.secretInput.value.trim();
  if (secret) payload.secret = secret;
  if (current) payload.current_label = current;
  const result = await api(current ? "/api/update" : "/api/add", { method: "POST", body: JSON.stringify(payload) });
  if (!result.ok) {
    showToast(result.data.message || text("error"));
    return;
  }
  showToast(text(current ? "updated" : "saved"));
  elements.editor.hidden = true;
  await loadEntries();
}

async function scanQr() {
  const file = elements.qrInput.files[0];
  if (!file || file.size > 1000000) {
    showToast(file ? "QR > 1 MB" : text("qr"));
    return;
  }
  const encoded = await new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result).split(",").pop());
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
  const result = await api("/api/scan-qr", { method: "POST", body: JSON.stringify({ image: encoded }) });
  if (!result.ok) {
    showToast(result.data.message || text("error"));
    return;
  }
  elements.labelInput.value ||= result.data.label || "";
  elements.issuerInput.value ||= result.data.issuer || "";
  elements.accountInput.value ||= result.data.account || "";
  elements.secretInput.value = result.data.secret || "";
  elements.digitsInput.value = String(result.data.digits || 6);
  elements.periodInput.value = String(result.data.period || 30);
  elements.algorithmInput.value = result.data.algo || "SHA1";
  showToast(text("qrReady"));
}

elements.accessForm.addEventListener("submit", (event) => { event.preventDefault(); accessToken = elements.tokenInput.value; elements.tokenInput.value = ""; loadEntries(); });
elements.searchInput.addEventListener("input", renderEntries);
elements.addButton.addEventListener("click", () => openEditor());
elements.closeEditor.addEventListener("click", () => { elements.editor.hidden = true; elements.addButton.focus(); });
elements.entryForm.addEventListener("submit", submitEntry);
elements.scanButton.addEventListener("click", scanQr);
elements.refreshButton.addEventListener("click", loadEntries);
elements.themeButton.addEventListener("click", () => { theme = theme === "dark" ? "light" : "dark"; localStorage.setItem("sat-theme", theme); applyPreferences(); });
elements.languageSelect.addEventListener("change", () => { language = elements.languageSelect.value; localStorage.setItem("sat-language", language); applyPreferences(); });
elements.deleteDialog.addEventListener("close", async () => {
  if (elements.deleteDialog.returnValue !== "confirm" || !pendingDelete) { pendingDelete = ""; return; }
  const result = await api("/api/delete", { method: "POST", body: JSON.stringify({ label: pendingDelete }) });
  pendingDelete = "";
  if (!result.ok) { showToast(result.data.message || text("error")); return; }
  showToast(text("deleted"));
  await loadEntries();
});

window.setInterval(() => {
  activeCodes.forEach((active, label) => {
    active.remaining -= 1;
    if (active.remaining <= 0) {
      hideCode(label, active.card);
    } else {
      updateTimer(label);
    }
  });
}, 1000);

window.addEventListener("offline", () => setState("error", text("offline"), text("offlineHelp")));
applyPreferences();
loadEntries();
