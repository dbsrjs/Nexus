// Sync the shared web build (../www) into ./www so Capacitor can bundle it into the native apps.
// Single source of truth = the top-level www/. Run before every `cap sync`.
const fs = require('fs');
const path = require('path');

const src = path.join(__dirname, '..', 'www');
const dest = path.join(__dirname, 'www');

fs.rmSync(dest, { recursive: true, force: true });
fs.cpSync(src, dest, { recursive: true });
console.log('[copy-web] synced ../www -> ./www');
