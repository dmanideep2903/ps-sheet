const { app, BrowserWindow, dialog, ipcMain } = require('electron');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const http = require('http');
const os = require('os');

const isDev = !app.isPackaged;

// Load app configuration
let appConfig = null;
try {
  const configPath = path.join(__dirname, 'appConfig.json');
  if (fs.existsSync(configPath)) {
    appConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    console.log('📋 App config loaded:', appConfig);
  }
} catch (error) {
  console.error('Failed to load appConfig.json:', error);
}

// IPC Handlers for renderer process
ipcMain.handle('get-app-config', () => {
  return appConfig || { companyId: 'default', apiBaseUrl: 'http://localhost:5001' };
});

ipcMain.handle('get-app-version', () => {
  return app.getVersion();
});

ipcMain.handle('get-network-info', async () => {
  try {
    const networkInterfaces = os.networkInterfaces();
    let gatewayIp = '';
    let routerMac = '';
    
    // Get default gateway and MAC (simplified - you may need more robust logic)
    for (const [name, interfaces] of Object.entries(networkInterfaces)) {
      for (const iface of interfaces) {
        if (!iface.internal && iface.family === 'IPv4') {
          gatewayIp = iface.address.split('.').slice(0, 3).join('.') + '.1'; // Assume .1 is gateway
          routerMac = iface.mac || '';
          break;
        }
      }
      if (gatewayIp) break;
    }
    
    return { gatewayIp, routerMac };
  } catch (error) {
    console.error('Failed to get network info:', error);
    return { gatewayIp: '', routerMac: '' };
  }
});

// Resolve backend path depending on whether the app is packaged
function getBackendCandidates() {
  const candidates = [];

  // Dev mode: backend is next to main.js (during development)
  candidates.push(path.join(__dirname, 'backend', 'backend.bin'));
  candidates.push(path.join(__dirname, 'backend', 'backend.exe'));

  // When packaged, defer adding resource-based candidates until runtime
  // because process.resourcesPath and app.isPackaged are meaningful then.
  return [...new Set(candidates)];
}
const HEALTH_URL = 'http://127.0.0.1:5001/health';

let backendProc = null;

function startBackend() {
  // Build candidates fresh at runtime so we pick up packaging/runtime paths
  let candidates = getBackendCandidates();
  if (app.isPackaged) {
    const r = process.resourcesPath;
    // Common locations used by electron-builder when asar is enabled/unpacked
    candidates.push(path.join(r, 'app', 'backend', 'backend.exe'));
    candidates.push(path.join(r, 'app', 'backend', 'backend.bin'));
    candidates.push(path.join(r, 'app.asar.unpacked', 'backend', 'backend.exe'));
    candidates.push(path.join(r, 'app.asar.unpacked', 'backend', 'backend.bin'));
    candidates.push(path.join(r, 'backend', 'backend.exe'));
    candidates.push(path.join(r, 'backend', 'backend.bin'));
  }

  candidates = [...new Set(candidates)];

  console.log('Attempting to spawn backend. Candidates:');
  const triedLines = [];
  let found = null;
  // Prefer unpacked locations and explicitly avoid trying to spawn files
  // that live inside an asar archive (e.g. paths containing 'app.asar\...')
  const preferred = candidates.filter(p => {
    const lower = p.toLowerCase();
    // allow app.asar.unpacked but disallow any other app.asar path
    if (lower.includes('app.asar.unpacked')) return true;
    if (lower.includes('app.asar')) return false;
    return true;
  });

  for (const p of preferred) {
    try {
      if (fs.existsSync(p)) {
        const st = fs.statSync(p);
        triedLines.push(`  - ${p} (exists, ${st.size} bytes)`);
        if (!found) found = p;
      } else {
        triedLines.push(`  - ${p} (missing)`);
      }
    } catch (e) {
      triedLines.push(`  - ${p} (error checking: ${e.message})`);
    }
    console.log(triedLines[triedLines.length - 1]);
  }

  const backendExe = found || preferred[0] || candidates[0];

  if (!found) {
    const msg = `Backend executable not found. Tried these locations:\n\n${triedLines.join('\n')}\n\nPlease reinstall the app or run the unpacked app with the backend present.`;
    console.error(msg);
    try {
      dialog.showErrorBox('Backend not found', msg);
    } catch (e) {}
    app.quit();
    return;
  }

  // Before spawning, make sure the path is not pointing into an asar archive
  if (backendExe.toLowerCase().includes('app.asar') && !backendExe.toLowerCase().includes('app.asar.unpacked')) {
    const msg = `Refusing to spawn backend from inside asar archive: ${backendExe}`;
    console.error(msg);
    try { dialog.showErrorBox('Backend launch failed', msg); } catch (e) {}
    app.quit();
    return;
  }

  backendProc = spawn(backendExe, [], {
    cwd: path.dirname(backendExe),
    stdio: ['ignore', 'pipe', 'pipe']
  });

  backendProc.on('error', err => {
    const msg = `Failed to start backend executable (${backendExe}): ${err.message}`;
    console.error(msg);
    try { dialog.showErrorBox('Backend launch failed', msg); } catch (e) {}
    app.quit();
  });

  backendProc.stdout.on('data', d => console.log(`[BACKEND] ${d.toString()}`));
  backendProc.stderr.on('data', d => console.error(`[BACKEND ERR] ${d.toString()}`));
  backendProc.on('exit', code => console.log(`Backend exited with code ${code}`));
}

function waitForHealth(retries = 60, delay = 300) {
  return new Promise((resolve, reject) => {
    let attempts = 0;
    const tryReq = () => {
      http.get(HEALTH_URL, res => {
        if (res.statusCode === 200) return resolve();
        next();
      }).on('error', next);
    };
    const next = () => {
      attempts++;
      if (attempts > retries) return reject(new Error('Backend did not respond in time'));
      setTimeout(tryReq, delay);
    };
    tryReq();
  });
}

function isBackendRunning(timeout = 800) {
  return new Promise((resolve) => {
    const req = http.get(HEALTH_URL, res => {
      resolve(res.statusCode === 200);
      try { req.destroy(); } catch (e) {}
    });
    req.on('error', () => resolve(false));
    // simple timeout
    req.setTimeout(timeout, () => {
      try { req.destroy(); } catch (e) {}
      resolve(false);
    });
  });
}

async function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 800,
    title: 'PS Sheet',
    icon: path.join(__dirname, 'build', 'logo512.png'),
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      cache: false  // Disable cache to force fresh load
    }
  });

  // Remove menu completely
  win.setMenu(null);

  // Clear ALL cache and storage before loading
  await win.webContents.session.clearCache();
  await win.webContents.session.clearStorageData({
    storages: ['appcache', 'cookies', 'filesystem', 'indexdb', 'localstorage', 'shadercache', 'websql', 'serviceworkers', 'cachestorage']
  });
  
  // Clear HTTP cache
  await win.webContents.session.clearHostResolverCache();
  
  // Disable cache for all requests
  win.webContents.session.webRequest.onBeforeSendHeaders((details, callback) => {
    details.requestHeaders['Cache-Control'] = 'no-cache, no-store, must-revalidate';
    details.requestHeaders['Pragma'] = 'no-cache';
    details.requestHeaders['Expires'] = '0';
    callback({ requestHeaders: details.requestHeaders });
  });
  
  // Load and force hard reload
  await win.loadFile(path.join(__dirname, 'build', 'index.html'));
  
  // Force hard reload after initial load
  win.webContents.once('did-finish-load', () => {
    win.webContents.reloadIgnoringCache();
  });
}

app.whenReady().then(async () => {
  try {
    // Check if using remote backend
    if (appConfig && appConfig.useRemoteBackend) {
      console.log('🌐 Using remote backend:', appConfig.apiBaseUrl);
      console.log('⚠️  Skipping local backend spawn');
      createWindow();
      return;
    }
    
    // Using local backend
    const running = await isBackendRunning(500);
    if (running) {
      console.log('Detected existing backend responding on health endpoint; will reuse it.');
      // still wait a short while to ensure it's stable
      await waitForHealth(20, 200);
    } else {
      startBackend();
      await waitForHealth(80, 250);
    }
    createWindow();
  } catch (err) {
    console.error('Failed to start or connect to backend:', err);
    app.quit();
  }
});

app.on('before-quit', () => {
  if (backendProc && !backendProc.killed) backendProc.kill();
});