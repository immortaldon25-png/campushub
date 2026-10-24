// Copies the web app into www/ and swaps CDN scripts for local copies so the app opens without internet.
const fs = require("fs"), path = require("path");
const out = "www", vendor = path.join(out, "vendor");
fs.mkdirSync(vendor, { recursive: true });
const copy = (from, to) => { if (!fs.existsSync(from)) throw new Error("Missing " + from); fs.copyFileSync(from, to); };
copy("config.js", path.join(out, "config.js"));
copy("node_modules/gsap/dist/gsap.min.js", path.join(vendor, "gsap.min.js"));
copy("node_modules/@supabase/supabase-js/dist/umd/supabase.js", path.join(vendor, "supabase.js"));
["manifest.webmanifest", "icon-192.png", "icon-512.png", "apple-touch-icon.png"].forEach((f) => { if (fs.existsSync(f)) fs.copyFileSync(f, path.join(out, f)); });
let html = fs.readFileSync("index.html", "utf8");
html = html.replace(/<script src="https:\/\/cdn\.jsdelivr\.net\/npm\/@supabase[^"]*"><\/script>/, '<script src="vendor/supabase.js"></script>')
           .replace(/<script src="https:\/\/cdnjs\.cloudflare\.com\/ajax\/libs\/gsap[^"]*"><\/script>/, '<script src="vendor/gsap.min.js"></script>');
if (html.includes("cdn.jsdelivr.net") || html.includes("cdnjs.cloudflare.com")) throw new Error("A CDN script tag was not replaced");
fs.writeFileSync(path.join(out, "index.html"), html);
console.log("www/ ready");
