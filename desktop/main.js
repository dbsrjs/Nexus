const { app, BrowserWindow, Tray, Menu, Notification, ipcMain, shell, nativeImage } = require('electron');
const path = require('path');

let mainWindow = null;
let tray = null;

// The shared web UI lives in ../www during development and in resources/www when packaged.
function resolveWwwDir() {
  return app.isPackaged
    ? path.join(process.resourcesPath, 'www')
    : path.join(__dirname, '..', 'www');
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 960,
    minHeight: 640,
    title: 'ONE 워크스페이스',
    backgroundColor: '#F4F6F8',
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  mainWindow.loadFile(path.join(resolveWwwDir(), 'index.html'));

  // Open external (http/https) links in the system browser, never inside the app shell.
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (/^https?:\/\//.test(url)) { shell.openExternal(url); return { action: 'deny' }; }
    return { action: 'allow' };
  });

  mainWindow.on('closed', () => { mainWindow = null; });
}

function showMainWindow() {
  if (!mainWindow) { createWindow(); return; }
  if (mainWindow.isMinimized()) mainWindow.restore();
  mainWindow.show();
  mainWindow.focus();
}

function createTray() {
  // Tray icon is optional. Try the SVG-derived PNG if present; otherwise skip the tray gracefully.
  try {
    let image = nativeImage.createFromPath(path.join(resolveWwwDir(), 'icons', 'icon.png'));
    if (image.isEmpty()) return; // no valid raster icon -> skip tray (non-critical)
    tray = new Tray(image);
    tray.setToolTip('ONE 워크스페이스');
    tray.setContextMenu(Menu.buildFromTemplate([
      { label: '열기', click: showMainWindow },
      { type: 'separator' },
      { label: '종료', click: () => app.quit() }
    ]));
    tray.on('click', showMainWindow);
  } catch (e) {
    // ignore tray failures (icon/platform) — the app still works without it
  }
}

// Single-instance lock: a second launch focuses the existing window instead of opening a new one.
const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
} else {
  app.on('second-instance', showMainWindow);

  app.whenReady().then(() => {
    createWindow();
    createTray();
    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
  });
}

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

// Native notification bridge (renderer calls window.oneworkDesktop.notify(title, body) via preload).
ipcMain.handle('onework:notify', (_event, title, body) => {
  if (!Notification.isSupported()) return false;
  new Notification({ title: String(title || 'ONE 워크스페이스'), body: String(body || '') }).show();
  return true;
});
