const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  getAppVersion: () => ipcRenderer.invoke('get-app-version'),
  getAppConfig: () => ipcRenderer.invoke('get-app-config'),
  getNetworkInfo: () => ipcRenderer.invoke('get-network-info')
});
