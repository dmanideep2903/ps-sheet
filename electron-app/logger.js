// Comprehensive Logging System for Attendance App
// Tracks complete data flow: Source → Input → Database → Output → UI

const fs = require('fs');
const path = require('path');

class AppLogger {
  constructor() {
    this.logsDir = path.join(__dirname, 'logs');
    this.ensureLogDirectory();
    this.currentLogFile = this.getLogFilePath();
  }

  ensureLogDirectory() {
    if (!fs.existsSync(this.logsDir)) {
      fs.mkdirSync(this.logsDir, { recursive: true });
    }
    this.cleanOldLogs();
  }

  getLogFilePath() {
    const date = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    return path.join(this.logsDir, `app-logs-${date}.log`);
  }

  cleanOldLogs() {
    try {
      const files = fs.readdirSync(this.logsDir);
      const now = Date.now();
      const sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);

      files.forEach(file => {
        const filePath = path.join(this.logsDir, file);
        const stats = fs.statSync(filePath);
        if (stats.mtimeMs < sevenDaysAgo) {
          fs.unlinkSync(filePath);
          console.log(`🗑️ Deleted old log: ${file}`);
        }
      });
    } catch (error) {
      console.error('Error cleaning old logs:', error);
    }
  }

  formatTimestamp() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hour = String(now.getHours()).padStart(2, '0');
    const minute = String(now.getMinutes()).padStart(2, '0');
    const second = String(now.getSeconds()).padStart(2, '0');
    const ms = String(now.getMilliseconds()).padStart(3, '0');
    return `${year}-${month}-${day} ${hour}:${minute}:${second}.${ms}`;
  }

  writeLog(category, message, data = null) {
    const timestamp = this.formatTimestamp();
    let logEntry = `[${timestamp}] [${category}] ${message}`;
    
    if (data) {
      logEntry += `\n  Data: ${JSON.stringify(data, null, 2)}`;
    }
    
    logEntry += '\n' + '-'.repeat(100) + '\n';

    try {
      fs.appendFileSync(this.currentLogFile, logEntry);
    } catch (error) {
      console.error('Failed to write log:', error);
    }
  }

  // Log API Request
  logApiRequest(method, url, headers, body) {
    this.writeLog('API-REQUEST', `${method} ${url}`, {
      headers,
      body: body ? JSON.parse(body) : null
    });
  }

  // Log API Response
  logApiResponse(method, url, status, responseData) {
    this.writeLog('API-RESPONSE', `${method} ${url} → Status: ${status}`, {
      responseData
    });
  }

  // Log User Action
  logUserAction(action, component, details) {
    this.writeLog('USER-ACTION', `${action} in ${component}`, details);
  }

  // Log Timezone Conversion
  logTimezoneConversion(functionName, inputTime, outputTime, source) {
    this.writeLog('TIMEZONE-CONVERSION', `${functionName}`, {
      source,
      input: inputTime,
      output: outputTime,
      offset: '+5:30 hours (IST)'
    });
  }

  // Log Database Operation
  logDatabaseOperation(operation, table, data) {
    this.writeLog('DATABASE', `${operation} on ${table}`, data);
  }

  // Log UI Render
  logUIRender(component, dataDisplayed) {
    this.writeLog('UI-RENDER', `Rendering ${component}`, dataDisplayed);
  }

  // Log Error
  logError(context, error, additionalData = null) {
    this.writeLog('ERROR', `${context}: ${error.message}`, {
      stack: error.stack,
      ...additionalData
    });
  }
}

// Singleton instance
const logger = new AppLogger();

module.exports = logger;
