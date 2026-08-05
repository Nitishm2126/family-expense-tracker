/**
 * FAMILY EXPENSE TRACKER — Google Apps Script Backend
 * ====================================================
 * Deploy this as a Web App:
 *   1. Open script.google.com, create a new project, paste this file in as Code.gs.
 *   2. Create a Google Sheet with tabs: Expenses, Income, Budget, Settings, Auth
 *      (see SHEET SCHEMA comments below for required columns).
 *   3. Deploy > New deployment > Web app.
 *        Execute as: Me
 *        Who has access: Anyone with the link
 *   4. Copy the /exec URL into lib/core/constants/api_config.dart -> ApiConfig.baseUrl
 *
 * SHEET SCHEMA
 * ------------
 * Expenses: id | member | category | description | amount | paymentMode | date | time | remarks | createdAt
 * Income:   id | receivedBy | source | description | amount | date | createdAt
 * Budget:   category | limit | month
 * Settings: key | value
 * Auth:     passwordHash   (single cell, B1 — SHA-256 hex of the shared family password)
 */

const SHEET_ID = 'REPLACE_WITH_YOUR_GOOGLE_SHEET_ID';

function doGet(e) {
  return handleRequest(e);
}

function doPost(e) {
  const body = e.postData ? JSON.parse(e.postData.contents) : {};
  return handleRequest(e, body);
}

function handleRequest(e, body) {
  const action = e.parameter.action;
  body = body || {};

  try {
    switch (action) {
      case 'login':
        return respond({ success: true, authenticated: verifyPassword(body.password) });
      case 'changePassword':
        return respond(changePassword(body.oldPassword, body.newPassword));

      case 'getExpenses':
        return respond({ success: true, data: getExpenses(e.parameter.from, e.parameter.to) });
      case 'addExpense':
        return respond({ success: true, data: addExpense(body) });
      case 'updateExpense':
        return respond({ success: updateExpense(body) });
      case 'deleteExpense':
        return respond({ success: deleteRow('Expenses', body.id) });

      case 'getIncomes':
        return respond({ success: true, data: getIncomes(e.parameter.from, e.parameter.to) });
      case 'addIncome':
        return respond({ success: true, data: addIncome(body) });
      case 'updateIncome':
        return respond({ success: updateIncome(body) });
      case 'deleteIncome':
        return respond({ success: deleteRow('Income', body.id) });

      case 'getDashboard':
        return respond({ success: true, data: getDashboard() });

      case 'getBudgets':
        return respond({ success: true, data: getBudgets(e.parameter.month) });
      case 'setBudget':
        return respond({ success: setBudget(body) });

      case 'getSettings':
        return respond({ success: true, data: getSettings() });
      case 'updateSettings':
        return respond({ success: updateSettings(body) });

      default:
        return respond({ success: false, message: 'Unknown action: ' + action });
    }
  } catch (err) {
    return respond({ success: false, message: err.message });
  }
}

function respond(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

function getSheet(name) {
  return SpreadsheetApp.openById(SHEET_ID).getSheetByName(name);
}

// ---------------- Auth ----------------

function verifyPassword(password) {
  const stored = getSheet('Auth').getRange('B1').getValue().toString();
  return sha256(password) === stored;
}

function changePassword(oldPassword, newPassword) {
  if (!verifyPassword(oldPassword)) {
    return { success: false, message: 'Current password is incorrect' };
  }
  getSheet('Auth').getRange('B1').setValue(sha256(newPassword));
  return { success: true };
}

function sha256(input) {
  const digest = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, input);
  return digest.map(b => (b < 0 ? b + 256 : b).toString(16).padStart(2, '0')).join('');
}

// ---------------- Expenses ----------------

const EXPENSE_HEADERS = ['id', 'member', 'category', 'description', 'amount', 'paymentMode', 'date', 'time', 'remarks', 'createdAt'];

function getExpenses(from, to) {
  const rows = sheetToObjects('Expenses', EXPENSE_HEADERS);
  if (!from && !to) return rows;
  return rows.filter(r => {
    const d = new Date(r.date);
    if (from && d < new Date(from)) return false;
    if (to && d > new Date(to)) return false;
    return true;
  });
}

function addExpense(body) {
  const row = EXPENSE_HEADERS.map(h => body[h] || '');
  getSheet('Expenses').appendRow(row);
  return body;
}

function updateExpense(body) {
  return updateRowById('Expenses', EXPENSE_HEADERS, body);
}

// ---------------- Income ----------------

const INCOME_HEADERS = ['id', 'receivedBy', 'source', 'description', 'amount', 'date', 'createdAt'];

function getIncomes(from, to) {
  const rows = sheetToObjects('Income', INCOME_HEADERS);
  if (!from && !to) return rows;
  return rows.filter(r => {
    const d = new Date(r.date);
    if (from && d < new Date(from)) return false;
    if (to && d > new Date(to)) return false;
    return true;
  });
}

function addIncome(body) {
  const row = INCOME_HEADERS.map(h => body[h] || '');
  getSheet('Income').appendRow(row);
  return body;
}

function updateIncome(body) {
  return updateRowById('Income', INCOME_HEADERS, body);
}

// ---------------- Dashboard ----------------

function getDashboard() {
  const expenses = sheetToObjects('Expenses', EXPENSE_HEADERS);
  const incomes = sheetToObjects('Income', INCOME_HEADERS);

  const totalIncome = incomes.reduce((s, i) => s + Number(i.amount), 0);
  const totalExpense = expenses.reduce((s, e) => s + Number(e.amount), 0);

  const now = new Date();
  const todayStr = Utilities.formatDate(now, Session.getScriptTimeZone(), 'yyyy-MM-dd');

  let todayExpense = 0;
  let monthExpense = 0;
  const categoryBreakdown = {};

  expenses.forEach(e => {
    const d = new Date(e.date);
    const amount = Number(e.amount);
    if (Utilities.formatDate(d, Session.getScriptTimeZone(), 'yyyy-MM-dd') === todayStr) {
      todayExpense += amount;
    }
    if (d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth()) {
      monthExpense += amount;
      categoryBreakdown[e.category] = (categoryBreakdown[e.category] || 0) + amount;
    }
  });

  const recentExpenses = expenses
    .sort((a, b) => new Date(b.date) - new Date(a.date))
    .slice(0, 5);

  return {
    totalIncome,
    totalExpense,
    balance: totalIncome - totalExpense,
    todayExpense,
    monthExpense,
    categoryBreakdown,
    recentExpenses,
  };
}

// ---------------- Budget ----------------

function getBudgets(month) {
  const rows = sheetToObjects('Budget', ['category', 'limit', 'month']);
  return month ? rows.filter(r => r.month === month) : rows;
}

function setBudget(body) {
  const sheet = getSheet('Budget');
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === body.category && data[i][2] === body.month) {
      sheet.getRange(i + 1, 2).setValue(body.limit);
      return true;
    }
  }
  sheet.appendRow([body.category, body.limit, body.month]);
  return true;
}

// ---------------- Settings ----------------

function getSettings() {
  const rows = sheetToObjects('Settings', ['key', 'value']);
  const result = {};
  rows.forEach(r => { result[r.key] = r.value; });
  return result;
}

function updateSettings(body) {
  const sheet = getSheet('Settings');
  const data = sheet.getDataRange().getValues();
  Object.keys(body).forEach(key => {
    let found = false;
    for (let i = 1; i < data.length; i++) {
      if (data[i][0] === key) {
        sheet.getRange(i + 1, 2).setValue(body[key]);
        found = true;
        break;
      }
    }
    if (!found) sheet.appendRow([key, body[key]]);
  });
  return true;
}

// ---------------- Shared helpers ----------------

function sheetToObjects(sheetName, headers) {
  const sheet = getSheet(sheetName);
  const data = sheet.getDataRange().getValues();
  const rows = [];
  for (let i = 1; i < data.length; i++) {
    if (!data[i][0]) continue;
    const obj = {};
    headers.forEach((h, idx) => { obj[h] = data[i][idx]; });
    rows.push(obj);
  }
  return rows;
}

function updateRowById(sheetName, headers, body) {
  const sheet = getSheet(sheetName);
  const data = sheet.getDataRange().getValues();
  const idCol = headers.indexOf('id');
  for (let i = 1; i < data.length; i++) {
    if (data[i][idCol] === body.id) {
      const row = headers.map(h => (body[h] !== undefined ? body[h] : data[i][headers.indexOf(h)]));
      sheet.getRange(i + 1, 1, 1, headers.length).setValues([row]);
      return true;
    }
  }
  return false;
}

function deleteRow(sheetName, id) {
  const sheet = getSheet(sheetName);
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === id) {
      sheet.deleteRow(i + 1);
      return true;
    }
  }
  return false;
}
