const { contextBridge, ipcRenderer } = require('electron');

// Minimal, safe API surface exposed to the web UI. The shared www app can feature-detect
// `window.oneworkDesktop` to light up native behaviour (e.g. OS notifications) when running on PC.
contextBridge.exposeInMainWorld('oneworkDesktop', {
  isDesktopApp: true,
  platform: process.platform,
  notify: (title, body) => ipcRenderer.invoke('onework:notify', title, body)
});
