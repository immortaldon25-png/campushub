// CampusHub service worker: makes the site installable and usable offline.
const V = "campushub-v1";
const SHELL = ["./", "index.html", "config.js", "manifest.webmanifest", "icon-192.png", "icon-512.png", "apple-touch-icon.png"];
self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(V).then((c) => Promise.all(SHELL.map((u) => c.add(u).catch(() => {})))).then(() => self.skipWaiting()));
});
self.addEventListener("activate", (e) => {
  e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== V).map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", (e) => {
  const r = e.request, u = new URL(r.url);
  if (r.method !== "GET") return;
  const own = u.origin === location.origin;
  const cdn = /(cdn\.jsdelivr\.net|cdnjs\.cloudflare\.com|fonts\.googleapis\.com|fonts\.gstatic\.com)$/.test(u.hostname);
  if (!own && !cdn) return; // never cache Supabase or any API traffic
  if (own && (r.mode === "navigate" || /\/(index\.html|config\.js)$/.test(u.pathname))) {
    // Pages and settings: always try the network first so updates arrive.
    e.respondWith(fetch(r).then((res) => { const cp = res.clone(); caches.open(V).then((c) => c.put(r, cp)); return res; })
      .catch(() => caches.match(r).then((m) => m || caches.match("index.html"))));
    return;
  }
  e.respondWith(caches.match(r).then((m) => {
    const net = fetch(r).then((res) => {
      if (res && (res.ok || res.type === "opaque")) { const cp = res.clone(); caches.open(V).then((c) => c.put(r, cp)); }
      return res;
    }).catch(() => m);
    return m || net;
  }));
});
