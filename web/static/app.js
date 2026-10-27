"use strict";

const copy = {
  id: {
    skip: "Lewati ke konten", instrumentLabel: "SAT–02 · INSTRUMEN KEAMANAN LOKAL", argument: "Kode penting tetap lokal, terlihat hanya ketika dibutuhkan.", accessEyebrow: "AKSES DIBUTUHKAN",
    accessTitle: "Hubungkan ke vault", accessHelp: "Token hanya disimpan dalam memori tab ini dan hilang saat halaman ditutup.", tokenLabel: "Token akses",
    connect: "Hubungkan", controls: "Kontrol vault", search: "Cari akun", add: "Tambah OTP", appearance: "Tampilan", appearanceHelp: "Pilih ground Signal tanpa mengubah data atau keamanan vault.", personalize: "PREFERENSI SIGNAL", active: "Aktif", language: "Bahasa", localOnly: "Lokal saja", vaultDisconnected: "Vault · Terputus", showToken: "Tampilkan", hideToken: "Sembunyikan", systemAppearance: "Ikuti tampilan perangkat", systemAppearanceHelp: "Signal gelap atau terang mengikuti sistem", navLabel: "SAT / NAVIGASI", navLocal: "Vault lokal · Privat", navWorkspace: "Workspace", navMetrics: "Status", navVault: "Vault", navSecurity: "Keamanan",
    workspaceContextEyebrow: "WORKSPACE AMAN", workspaceContextTitle: "Pusat kendali authenticator", storageLabel: "Penyimpanan", storageValue: "Terenkripsi lokal", sessionLabel: "Sesi", sessionLocked: "Terkunci", sessionConnected: "Terhubung",
    workspaceEyebrow: "OPERASI VAULT", workspaceTitle: "Workspace authenticator", workspaceHelp: "Temukan akun, tambah entri, dan pantau keadaan vault dari satu tempat.",
    statusLabel: "Status vault", total: "Total", visible: "Terlihat", sync: "Sinkron", privacy: "Privasi", privacyValue: "Tersembunyi",
    newEntry: "ENTRI BARU", editEntry: "EDIT ENTRI", editorTitle: "Tambahkan authenticator", editorEditTitle: "Perbarui authenticator", close: "Tutup",
    label: "Label", issuer: "Issuer", account: "Account", secret: "Secret BASE32", digits: "Digits", period: "Period", algorithm: "Algorithm",
    qr: "QR OTP (PNG/JPG/GIF/WebP, maks. 1 MB)", qrChooseFile: "Pilih file QR terlebih dahulu.", qrTooLarge: "QR maksimal 1 MB.", save: "Simpan", scan: "Baca QR", vaultEyebrow: "VAULT TERENKRIPSI", vaultTitle: "Authenticator",
    refresh: "Muat ulang", loading: "Membuka daftar…", loadingHelp: "Vault tetap terenkripsi di disk.", empty: "Vault masih kosong", emptyHelp: "Tambahkan authenticator pertama untuk mulai.",
    ready: "Vault siap", readyHelp: "Kode tetap tersembunyi sampai Anda memilih Tampilkan.", locked: "Workspace terkunci", lockedHelp: "Hubungkan token akses untuk membuka daftar authenticator.", unauthorized: "Token ditolak", unauthorizedHelp: "Masukkan token akses yang benar.",
    offline: "Tidak terhubung", offlineHelp: "Periksa server SAT lalu muat ulang.", error: "Permintaan gagal", reveal: "Tampilkan", hide: "Sembunyikan", copy: "Salin", copied: "Kode disalin", connecting: "Menghubungkan…", codeProtected: "Kode terlindungi", codeVisible: "Kode aktif", entryCount: "{count} entri", shownCount: "{count} ditampilkan",
    revealEntry: "Tampilkan kode untuk {label}", hideEntry: "Sembunyikan kode untuk {label}", copyEntry: "Salin kode untuk {label}", editEntryAction: "Edit {label}", deleteEntryAction: "Hapus {label}", expires: "Kode kedaluwarsa",
    edit: "Edit", delete: "Hapus", destructive: "TINDAKAN DESTRUKTIF", deleteTitle: "Hapus authenticator?", deletePrompt: "Entri {label} akan dihapus dari vault terenkripsi.", cancel: "Batal",
    saved: "Authenticator disimpan", updated: "Authenticator diperbarui", deleted: "Authenticator dihapus", qrReady: "QR dibaca. Periksa data sebelum menyimpan.",
    honestEyebrow: "BATAS SISTEM", honestTitle: "Keamanan berhenti di perangkat ini", honestText: "SAT melindungi vault saat tersimpan. Perangkat yang sudah dikuasai pihak lain tetap dapat merekam layar atau input saat vault sedang digunakan."
  },
  en: {
    skip: "Skip to content", instrumentLabel: "SAT–02 · LOCAL SECURITY INSTRUMENT", argument: "Important codes stay local and appear only when needed.", accessEyebrow: "ACCESS REQUIRED", accessTitle: "Connect to the vault",
    accessHelp: "The token stays in this tab's memory and disappears when the page closes.", tokenLabel: "Access token", connect: "Connect", controls: "Vault controls",
    search: "Search accounts", add: "Add OTP", appearance: "Appearance", appearanceHelp: "Choose a Signal ground without changing vault data or security.", personalize: "SIGNAL PREFERENCE", active: "Active", language: "Language", localOnly: "Local only", vaultDisconnected: "Vault · Disconnected", showToken: "Show", hideToken: "Hide", systemAppearance: "Follow device appearance", systemAppearanceHelp: "Signal dark or light follows the system", navLabel: "SAT / NAVIGATION", navLocal: "Local vault · Private", navWorkspace: "Workspace", navMetrics: "Status", navVault: "Vault", navSecurity: "Security", workspaceContextEyebrow: "SECURE WORKSPACE", workspaceContextTitle: "Authenticator control center", storageLabel: "Storage", storageValue: "Encrypted locally", sessionLabel: "Session", sessionLocked: "Locked", sessionConnected: "Connected", workspaceEyebrow: "VAULT OPERATIONS", workspaceTitle: "Authenticator workspace", workspaceHelp: "Find accounts, add entries, and monitor vault state in one place.", statusLabel: "Vault status", total: "Total",
    visible: "Visible", sync: "Synced", privacy: "Privacy", privacyValue: "Hidden", newEntry: "NEW ENTRY", editEntry: "EDIT ENTRY", editorTitle: "Add authenticator",
    editorEditTitle: "Update authenticator", close: "Close", label: "Label", issuer: "Issuer", account: "Account", secret: "BASE32 secret", digits: "Digits",
    period: "Period", algorithm: "Algorithm", qr: "OTP QR (PNG/JPG/GIF/WebP, max 1 MB)", qrChooseFile: "Choose a QR file first.", qrTooLarge: "QR files must be 1 MB or smaller.", save: "Save", scan: "Read QR", vaultEyebrow: "ENCRYPTED VAULT",
    vaultTitle: "Authenticators", refresh: "Reload", loading: "Opening list…", loadingHelp: "The vault stays encrypted on disk.", empty: "The vault is empty",
    emptyHelp: "Add the first authenticator to begin.", ready: "Vault ready", readyHelp: "Codes stay hidden until you choose Reveal.", locked: "Workspace locked", lockedHelp: "Connect an access token to open the authenticator list.", unauthorized: "Token rejected",
    unauthorizedHelp: "Enter the correct access token.", offline: "Not connected", offlineHelp: "Check the SAT server and reload.", error: "Request failed", reveal: "Reveal",
    hide: "Hide", copy: "Copy", copied: "Code copied", connecting: "Connecting…", codeProtected: "Protected code", codeVisible: "Active code", entryCount: "{count} entries", shownCount: "{count} shown", revealEntry: "Reveal the code for {label}", hideEntry: "Hide the code for {label}", copyEntry: "Copy the code for {label}", editEntryAction: "Edit {label}", deleteEntryAction: "Delete {label}", expires: "Code expires", edit: "Edit", delete: "Delete", destructive: "DESTRUCTIVE ACTION", deleteTitle: "Delete authenticator?",
    deletePrompt: "The {label} entry will be removed from the encrypted vault.", cancel: "Cancel", saved: "Authenticator saved", updated: "Authenticator updated",
    deleted: "Authenticator deleted", qrReady: "QR read. Check the values before saving.", honestEyebrow: "SYSTEM LIMIT", honestTitle: "Security ends at this device",
    honestText: "SAT protects the vault at rest. A compromised device can still record the screen or input while the vault is in use."
  }
};

const elements = Object.fromEntries([
  "accessGate", "accessForm", "tokenInput", "tokenVisibilityButton", "connectButton", "searchInput", "addButton", "emptyAddButton", "themeButton", "themePanel", "themeChoices", "themeGrid", "closeThemePanel", "systemThemeButton", "languageSelect", "totalCount", "visibleCount", "syncTime", "sessionStatus", "vaultSummary",
  "editor", "editorMode", "editorTitle", "closeEditor", "entryForm", "currentLabel", "labelInput", "issuerInput", "accountInput", "secretInput", "digitsInput",
  "periodInput", "algorithmInput", "qrInput", "scanButton", "refreshButton", "statePanel", "stateTitle", "stateMessage", "otpGrid", "otpTemplate", "deleteDialog",
  "deleteDescription", "confirmDelete", "toast"
].map((id) => [id, document.getElementById(id)]));

const themes = [
  ["signal-dark", "Signal Dark", "instrument", "Gelap · Instrumen", "Dark · Instrument", "Panel rendah cahaya untuk operasi vault yang fokus.", "A low-light panel for focused vault operations."],
  ["signal-light", "Signal Light", "instrument", "Terang · Instrumen", "Light · Instrument", "Panel terang untuk kondisi siang dan ruang kerja cerah.", "A bright panel for daylight and bright workspaces."]
].map(([id, name, layout, categoryId, categoryEn, descriptionId, descriptionEn]) => ({ id, name, layout, category: { id: categoryId, en: categoryEn }, description: { id: descriptionId, en: descriptionEn } }));
const themeIds = new Set(themes.map(({ id }) => id));
let language = localStorage.getItem("sat-language") === "en" ? "en" : "id";
let theme = storedTheme();
let accessToken = "";
let entries = [];
let activeCodes = new Map();
let pendingDelete = "";
let toastTimer = 0;
let attemptedAccess = false;

function text(key, replacements = {}) {
  let value = copy[language][key] || key;
  Object.entries(replacements).forEach(([name, replacement]) => { value = value.replace(`{${name}}`, replacement); });
  return value;
}

function storedTheme() {
  const requested = new URLSearchParams(window.location.search).get("theme");
  if (requested && themeIds.has(requested)) return requested;
  const saved = localStorage.getItem("sat.theme");
  if (saved === "system" || themeIds.has(saved)) return saved;
  const legacy = localStorage.getItem("sat-theme");
  if (legacy === "light" || legacy === "dark") {
    const migrated = legacy === "light" ? "signal-light" : "signal-dark";
    localStorage.setItem("sat.theme", migrated);
    localStorage.removeItem("sat-theme");
    return migrated;
  }
  return "system";
}

function resolvedTheme() { return theme === "system" ? (window.matchMedia("(prefers-color-scheme: light)").matches ? "signal-light" : "signal-dark") : theme; }
function activeAppearance() { return themes.find((item) => item.id === resolvedTheme()) || themes[0]; }
function updateThemeChrome() {
  const color = resolvedTheme() === "signal-light" ? "#F4F7F6" : "#0D1315";
  document.querySelector('meta[name="theme-color"]')?.setAttribute("content", color);
}

function renderThemePicker() {
  elements.themeGrid.replaceChildren();
  themes.forEach((item, itemIndex) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "theme-card";
    button.dataset.themePreview = item.id;
    button.dataset.themeChoice = item.id;
    button.setAttribute("role", "radio");
    button.setAttribute("aria-checked", String(theme === item.id));
    button.setAttribute("aria-label", `${item.name}, ${item.category[language]}. ${item.description[language]}`);
    button.tabIndex = theme === item.id ? 0 : -1;
    const preview = document.createElement("span"); preview.className = "theme-card__preview";
    const previewNav = document.createElement("i"); previewNav.className = "theme-card__preview-nav"; previewNav.textContent = "SAT     ●";
    const previewTitle = document.createElement("em"); previewTitle.className = "theme-card__preview-title"; previewTitle.textContent = "SAT / AUTH";
    const previewVault = document.createElement("span"); previewVault.className = "theme-card__preview-vault";
    const previewStatus = document.createElement("small"); previewStatus.textContent = "• VAULT";
    const previewCode = document.createElement("b"); previewCode.textContent = "123 456";
    previewVault.append(previewStatus, previewCode);
    preview.append(previewNav, previewTitle, previewVault);
    const meta = document.createElement("span"); meta.className = "theme-card__meta";
    const heading = document.createElement("span"); heading.className = "theme-card__heading";
    const identity = document.createElement("span"); identity.className = "theme-card__identity";
    const number = document.createElement("span"); number.className = "theme-card__number"; number.textContent = String(itemIndex + 1).padStart(2, "0");
    const name = document.createElement("strong"); name.textContent = item.name;
    const selected = document.createElement("span"); selected.className = "theme-card__selected"; selected.textContent = text("active"); selected.hidden = theme !== item.id;
    const category = document.createElement("small"); category.className = "theme-card__category"; category.textContent = item.category[language];
    const description = document.createElement("small"); description.className = "theme-card__description"; description.textContent = item.description[language];
    identity.append(number, name);
    heading.append(identity, selected);
    meta.append(heading, category, description);
    button.append(preview, meta);
    button.addEventListener("click", () => setTheme(item.id));
    elements.themeGrid.append(button);
  });
  elements.systemThemeButton.setAttribute("aria-checked", String(theme === "system"));
  elements.systemThemeButton.tabIndex = theme === "system" ? 0 : -1;
}

function setTheme(nextTheme) {
  document.documentElement.dataset.themeChanging = "true";
  theme = nextTheme;
  localStorage.setItem("sat.theme", theme);
  document.documentElement.dataset.theme = resolvedTheme();
  document.documentElement.dataset.layout = activeAppearance().layout;
  document.documentElement.dataset.themePreference = theme;
  updateThemeChrome();
  renderThemePicker();
  if (elements.themePanel.open) window.requestAnimationFrame(() => elements.themePanel.querySelector('[role="radio"][aria-checked="true"]')?.focus());
  window.setTimeout(() => { delete document.documentElement.dataset.themeChanging; }, 180);
}

function openThemePanel(trigger) {
  elements.themePanel.dataset.invoker = trigger.id;
  if (!elements.themePanel.open) elements.themePanel.showModal();
  elements.themeButton.setAttribute("aria-expanded", "true");
  window.requestAnimationFrame(() => (elements.themePanel.querySelector('[role="radio"][aria-checked="true"]') || elements.closeThemePanel).focus());
}

function closeThemePanel() {
  const invoker = document.getElementById(elements.themePanel.dataset.invoker || "themeButton");
  if (elements.themePanel.open) elements.themePanel.close();
  elements.themeButton.setAttribute("aria-expanded", "false");
  invoker?.focus();
}

function setWorkspaceAvailability(available) {
  [elements.searchInput, elements.addButton, elements.emptyAddButton, elements.refreshButton].forEach((control) => { control.disabled = !available; });
  document.body.dataset.vaultState = available ? "connected" : "disconnected";
  elements.sessionStatus.textContent = text(available ? "sessionConnected" : "sessionLocked");
}

function applyPreferences() {
  document.documentElement.lang = language;
  document.documentElement.dataset.theme = resolvedTheme();
  document.documentElement.dataset.layout = activeAppearance().layout;
  document.documentElement.dataset.themePreference = theme;
  updateThemeChrome();
  elements.languageSelect.value = language;
  elements.themeChoices.setAttribute("aria-label", language === "id" ? "Pilihan tema" : "Theme choices");
  elements.closeThemePanel.setAttribute("aria-label", text("close"));
  document.querySelectorAll("[data-i18n]").forEach((node) => { node.textContent = text(node.dataset.i18n); });
  document.querySelectorAll("[data-i18n-aria]").forEach((node) => { node.setAttribute("aria-label", text(node.dataset.i18nAria)); });
  elements.sessionStatus.textContent = text(document.body.dataset.vaultState === "connected" ? "sessionConnected" : "sessionLocked");
  renderThemePicker();
  renderEntries();
}

const navigationLinks = [...document.querySelectorAll(".layout-nav a")];
function setCurrentNavigation(targetId) {
  navigationLinks.forEach((link) => {
    if (link.getAttribute("href") === `#${targetId}`) link.setAttribute("aria-current", "location");
    else link.removeAttribute("aria-current");
  });
}

navigationLinks.forEach((link) => {
  link.addEventListener("click", () => setCurrentNavigation(link.getAttribute("href").slice(1)));
});

if ("IntersectionObserver" in window) {
  const sectionObserver = new IntersectionObserver((records) => {
    const visible = records.filter((record) => record.isIntersecting).sort((first, second) => second.intersectionRatio - first.intersectionRatio)[0];
    if (visible) setCurrentNavigation(visible.target.id);
  }, { rootMargin: "-18% 0px -62%", threshold: [0.05, 0.35, 0.7] });
  ["controls", "metrics", "vault", "system-note"].map((id) => document.getElementById(id)).filter(Boolean).forEach((section) => sectionObserver.observe(section));
}
setCurrentNavigation("controls");

function showToast(message) {
  window.clearTimeout(toastTimer);
  elements.toast.textContent = message;
  elements.toast.hidden = false;
  toastTimer = window.setTimeout(() => { elements.toast.hidden = true; }, 3000);
}

function setState(state, title, message) {
  elements.statePanel.dataset.state = state;
  const index = elements.statePanel.querySelector(".state-panel__index");
  if (index) index.textContent = ({ loading: "··", locked: "01", unauthorized: "!", error: "!", empty: "00", ready: "OK" })[state] || "··";
  elements.stateTitle.textContent = title;
  elements.stateMessage.textContent = message;
  elements.statePanel.hidden = false;
  elements.emptyAddButton.hidden = state !== "empty";
}

async function api(path, options = {}) {
  const headers = { ...(options.headers || {}) };
  if (options.body) headers["Content-Type"] = "application/json";
  if (accessToken) headers["X-SAT-Token"] = accessToken;
  try {
    const response = await fetch(path, { ...options, headers });
    const data = await response.json().catch(() => ({}));
    if (response.status === 401) {
      setWorkspaceAvailability(false);
      entries = [];
      activeCodes.clear();
      elements.otpGrid.replaceChildren();
      updateCounts(0);
      elements.accessGate.hidden = false;
      document.body.dataset.vaultState = "disconnected";
      const rejected = attemptedAccess || Boolean(accessToken);
      if (rejected) {
        elements.tokenInput.setAttribute("aria-invalid", "true");
        elements.tokenInput.setAttribute("aria-describedby", "stateMessage");
      }
      setState(rejected ? "unauthorized" : "locked", text(rejected ? "unauthorized" : "locked"), text(rejected ? "unauthorizedHelp" : "lockedHelp"));
    }
    return { ok: response.ok, status: response.status, data };
  } catch (error) {
    setWorkspaceAvailability(false);
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
  elements.vaultSummary.textContent = `${text("entryCount", { count: entries.length })} · ${text("shownCount", { count: visible })}`;
}

function hideCode(label, card) {
  activeCodes.delete(label);
  const code = card.querySelector(".otp-card__code");
  code.value = "";
  code.textContent = "••• •••";
  card.querySelector(".otp-card__value").dataset.state = "hidden";
  card.querySelector(".otp-card__mode").textContent = text("codeProtected");
  const revealButton = card.querySelector(".reveal-button");
  revealButton.textContent = text("reveal");
  revealButton.setAttribute("aria-label", text("revealEntry", { label }));
  card.querySelector(".copy-button").disabled = true;
  const progress = card.querySelector("progress");
  progress.value = 0;
  progress.setAttribute("aria-valuetext", text("expires"));
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
  card.querySelector(".otp-card__mode").textContent = text("codeVisible");
  button.textContent = text("hide");
  button.setAttribute("aria-label", text("hideEntry", { label: entry.label }));
  card.querySelector(".copy-button").disabled = false;
  updateTimer(entry.label);
}

function updateTimer(label) {
  const active = activeCodes.get(label);
  if (!active) return;
  const progress = active.card.querySelector("progress");
  progress.max = active.period;
  progress.value = active.remaining;
  progress.setAttribute("aria-valuetext", `${text("expires")}: ${active.remaining}s`);
  active.card.querySelector(".otp-card__timer span").textContent = `${active.remaining}s`;
}

async function copyActiveCode(label, button) {
  const active = activeCodes.get(label);
  if (!active) return;
  try {
    await navigator.clipboard.writeText(active.code);
    showToast(text("copied"));
    button.textContent = text("copied");
    button.disabled = true;
    window.setTimeout(() => {
      if (document.body.contains(button) && activeCodes.has(label)) {
        button.textContent = text("copy");
        button.disabled = false;
      }
    }, 1400);
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
  visible.forEach((entry, index) => {
    const fragment = elements.otpTemplate.content.cloneNode(true);
    const card = fragment.querySelector(".otp-card");
    const article = card.querySelector("article");
    const labelHeading = card.querySelector(".otp-card__label");
    labelHeading.id = `otp-entry-${index}`;
    article.setAttribute("aria-labelledby", labelHeading.id);
    card.dataset.label = entry.label;
    const identity = (entry.issuer || entry.label || "SAT").trim().split(/\s+/).slice(0, 2).map((part) => Array.from(part)[0] || "").join("").toLocaleUpperCase(language);
    card.querySelector(".otp-card__mark").textContent = identity || "S";
    card.querySelector(".otp-card__issuer").textContent = entry.issuer || "—";
    labelHeading.textContent = entry.label;
    card.querySelector(".otp-card__account").textContent = entry.account || "—";
    card.querySelector(".otp-card__algorithm").textContent = `${entry.algo || "SHA1"} · ${entry.digits || 6}D`;
    card.querySelector(".otp-card__mode").textContent = text("codeProtected");
    const reveal = card.querySelector(".reveal-button");
    const copyButton = card.querySelector(".copy-button");
    const edit = card.querySelector(".edit-button");
    const remove = card.querySelector(".delete-button");
    const progress = card.querySelector("progress");
    [reveal, copyButton, edit, remove].forEach((button) => { button.textContent = text(button.dataset.i18n); });
    reveal.setAttribute("aria-label", text("revealEntry", { label: entry.label }));
    copyButton.setAttribute("aria-label", text("copyEntry", { label: entry.label }));
    edit.setAttribute("aria-label", text("editEntryAction", { label: entry.label }));
    remove.setAttribute("aria-label", text("deleteEntryAction", { label: entry.label }));
    progress.setAttribute("aria-label", `${text("expires")}: ${entry.label}`);
    progress.setAttribute("aria-valuetext", text("expires"));
    reveal.addEventListener("click", () => revealCode(entry, card));
    copyButton.addEventListener("click", () => copyActiveCode(entry.label, copyButton));
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
  document.body.dataset.vaultState = "connected";
  attemptedAccess = false;
  elements.tokenInput.removeAttribute("aria-invalid");
  elements.tokenInput.removeAttribute("aria-describedby");
  setWorkspaceAvailability(true);
  entries = result.data.entries || [];
  elements.syncTime.dateTime = new Date().toISOString();
  elements.syncTime.textContent = new Date().toLocaleTimeString(language);
  renderEntries();
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
    showToast(file ? text("qrTooLarge") : text("qrChooseFile"));
    return;
  }
  let encoded;
  try {
    encoded = await new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(String(reader.result).split(",").pop());
      reader.onerror = () => reject(new Error("file_read_failed"));
      reader.readAsDataURL(file);
    });
  } catch (error) {
    showToast(text("error"));
    return;
  }
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

elements.accessForm.addEventListener("submit", (event) => {
  event.preventDefault();
  attemptedAccess = true;
  elements.tokenInput.removeAttribute("aria-invalid");
  accessToken = elements.tokenInput.value;
  elements.tokenInput.value = "";
  elements.connectButton.disabled = true;
  elements.connectButton.setAttribute("aria-busy", "true");
  elements.connectButton.querySelector("span").textContent = text("connecting");
  loadEntries().finally(() => {
    elements.connectButton.disabled = false;
    elements.connectButton.removeAttribute("aria-busy");
    elements.connectButton.querySelector("span").textContent = text("connect");
  });
});
elements.tokenInput.addEventListener("input", () => { elements.tokenInput.removeAttribute("aria-invalid"); });
elements.searchInput.addEventListener("input", renderEntries);
elements.addButton.addEventListener("click", () => openEditor());
elements.emptyAddButton.addEventListener("click", () => openEditor());
elements.closeEditor.addEventListener("click", () => { elements.editor.hidden = true; elements.addButton.focus(); });
elements.entryForm.addEventListener("submit", submitEntry);
elements.scanButton.addEventListener("click", scanQr);
elements.refreshButton.addEventListener("click", loadEntries);
elements.themeButton.addEventListener("click", () => openThemePanel(elements.themeButton));
elements.closeThemePanel.addEventListener("click", closeThemePanel);
elements.systemThemeButton.addEventListener("click", () => setTheme("system"));
elements.themePanel.addEventListener("cancel", (event) => { event.preventDefault(); closeThemePanel(); });
elements.themePanel.addEventListener("close", () => { elements.themeButton.setAttribute("aria-expanded", "false"); });
elements.themePanel.addEventListener("click", (event) => {
  if (event.target !== elements.themePanel) return;
  const bounds = elements.themePanel.getBoundingClientRect();
  const inside = event.clientX >= bounds.left && event.clientX <= bounds.right && event.clientY >= bounds.top && event.clientY <= bounds.bottom;
  if (!inside) closeThemePanel();
});
elements.themePanel.addEventListener("keydown", (event) => {
  if (!['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'Home', 'End'].includes(event.key)) return;
  const choices = [...elements.themePanel.querySelectorAll('[role="radio"]')];
  if (!choices.length) return;
  event.preventDefault();
  const current = Math.max(0, choices.indexOf(document.activeElement));
  let next = current;
  if (event.key === "Home") next = 0;
  else if (event.key === "End") next = choices.length - 1;
  else next = (current + (event.key === "ArrowRight" || event.key === "ArrowDown" ? 1 : -1) + choices.length) % choices.length;
  choices[next].click();
});
elements.tokenVisibilityButton.addEventListener("click", () => {
  const visible = elements.tokenInput.type === "text";
  elements.tokenInput.type = visible ? "password" : "text";
  elements.tokenVisibilityButton.setAttribute("aria-pressed", String(!visible));
  elements.tokenVisibilityButton.textContent = text(visible ? "showToken" : "hideToken");
});
function changeLanguage(value) { language = value; localStorage.setItem("sat-language", language); applyPreferences(); }
elements.languageSelect.addEventListener("change", () => changeLanguage(elements.languageSelect.value));
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

window.matchMedia("(prefers-color-scheme: light)").addEventListener("change", () => { if (theme === "system") setTheme("system"); });
window.addEventListener("offline", () => {
  setWorkspaceAvailability(false);
  setState("error", text("offline"), text("offlineHelp"));
});
applyPreferences();
setWorkspaceAvailability(false);
window.requestAnimationFrame(() => document.documentElement.dataset.themeReady = "true");
loadEntries();
