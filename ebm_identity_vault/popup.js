// Core State
let currentCryptoKey = null;
let currentMasterKeyHash = null;
let vaultDataArray = []; // [{ id, title, email, pass1, pass2, pass3 }]
let editingAccountId = null; // null means adding a new one

// DOM Elements
const views = {
    setup: document.getElementById('view-setup'),
    login: document.getElementById('view-login'),
    list: document.getElementById('view-list'),
    edit: document.getElementById('view-edit'),
    audit: document.getElementById('view-audit')
};

// CSS class names used by new design
const VIEW_CLASS = 'view';
const ACTIVE_CLASS = 'active';

// Utils
function showToast(message) {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.classList.add('show');
    setTimeout(() => { toast.classList.remove('show'); }, 3000);
}

function switchView(viewName) {
    Object.values(views).forEach(v => {
        v.classList.remove('active-view');
        v.classList.remove(ACTIVE_CLASS);
    });
    views[viewName].classList.add('active-view');
    views[viewName].classList.add(ACTIVE_CLASS);
}

// Float / PopOut functionality — passes mode=float so we can detect detached window
document.getElementById('btn-popout').addEventListener('click', () => {
    chrome.windows.create({
        url: chrome.runtime.getURL("popup.html?mode=float"),
        type: "popup",
        width: 420,
        height: 660
    });
    window.close();
});

// Mac-style dot controls
document.querySelector('.dot.red').addEventListener('click', () => window.close());

// Crypto functions (AES-GCM 256)
const ENCRYPTION_SALT = "EBM_ENTERPRISE_VAULT_SALT";

async function deriveKey(password) {
    const enc = new TextEncoder();
    const keyMaterial = await window.crypto.subtle.importKey(
        "raw", enc.encode(password), { name: "PBKDF2" }, false, ["deriveBits", "deriveKey"]
    );
    return window.crypto.subtle.deriveKey(
        {
            name: "PBKDF2",
            salt: enc.encode(ENCRYPTION_SALT),
            iterations: 100000,
            hash: "SHA-256"
        },
        keyMaterial,
        { name: "AES-GCM", length: 256 },
        true,
        ["encrypt", "decrypt"]
    );
}

async function hashKey(password) {
    const enc = new TextEncoder();
    const hashBuffer = await window.crypto.subtle.digest('SHA-256', enc.encode(password));
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

async function encryptData(text, key) {
    const enc = new TextEncoder();
    const iv = window.crypto.getRandomValues(new Uint8Array(12));
    const encrypted = await window.crypto.subtle.encrypt(
        { name: "AES-GCM", iv: iv }, key, enc.encode(text)
    );

    // Combine iv and enc
    const buffer = new Uint8Array(iv.length + encrypted.byteLength);
    buffer.set(iv, 0);
    buffer.set(new Uint8Array(encrypted), iv.length);
    return btoa(String.fromCharCode.apply(null, buffer));
}

async function decryptData(encryptedBase64, key) {
    const buffer = new Uint8Array(atob(encryptedBase64).split('').map(c => c.charCodeAt(0)));
    const iv = buffer.slice(0, 12);
    const data = buffer.slice(12);

    const decrypted = await window.crypto.subtle.decrypt(
        { name: "AES-GCM", iv: iv }, key, data
    );
    const dec = new TextDecoder();
    return dec.decode(decrypted);
}

// Storage Helpers
function setStorage(key, value) {
    return new Promise(resolve => chrome.storage.local.set({ [key]: value }, resolve));
}

function getStorage(key) {
    return new Promise(resolve => chrome.storage.local.get([key], result => resolve(result[key])));
}

async function saveVaultToStorage() {
    try {
        const jsonStr = JSON.stringify(vaultDataArray);
        const encrypted = await encryptData(jsonStr, currentCryptoKey);
        await setStorage('ebm_vault_data', encrypted);
    } catch (e) {
        showToast("Error saving vault");
    }
}

// Initialization Flow
document.addEventListener('DOMContentLoaded', async () => {

    // ── Float / Detached Window Mode Detection ──
    const urlParams = new URLSearchParams(window.location.search);
    const isFloat = urlParams.get('mode') === 'float';

    if (isFloat) {
        // Activate all float-mode CSS rules instantly
        document.body.classList.add('float-mode');

        // Remove the embedded Mac titlebar (Chrome window already has its own)
        const titleBar = document.querySelector('.mock-title-bar');
        if (titleBar) titleBar.style.display = 'none';

        // Hide animated snake border — looks bad against Chrome window frame
        const snakeWire = document.querySelector('.snake-wire');
        if (snakeWire) snakeWire.style.display = 'none';

        // Make the outer glow ::after pseudo disappear by zeroing its blur
        document.body.style.setProperty('--primary-glow', 'transparent');

        // Remove outer padding so the app fills the Chrome popup window edge-to-edge
        document.body.style.padding = '0';
        document.body.style.width = '100vw';
        document.body.style.height = '100vh';

        // Remove border radius — it should look like a native desktop window
        const wrapper = document.querySelector('.app-wrapper');
        const content = document.querySelector('.app-content');
        if (wrapper) { wrapper.style.borderRadius = '0'; wrapper.style.width = '100%'; wrapper.style.height = '100%'; }
        if (content) { content.style.borderRadius = '0'; }

        // Hide PIN button (already floating)
        const pinBtn = document.getElementById('btn-popout');
        if (pinBtn) pinBtn.style.display = 'none';

        // Add a subtle top header for the float window with app name
        const floatBar = document.createElement('div');
        floatBar.id = 'float-title-bar';
        floatBar.style.cssText = `
            position: fixed; top: 0; left: 0; right: 0; height: 36px;
            background: rgba(10,13,20,0.95);
            backdrop-filter: blur(16px);
            border-bottom: 1px solid rgba(16,185,129,0.15);
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 16px; z-index: 9999;
            -webkit-app-region: drag;
        `;
        floatBar.innerHTML = `
            <div style="display:flex; align-items:center; gap:8px;">
                <span style="font-size:12px; filter:drop-shadow(0 0 4px rgba(16,185,129,0.5));">🛡️</span>
                <span style="font-size:12px; font-weight:700; color:#f8fafc; letter-spacing:0.5px; font-family:Inter,sans-serif;">EBM VAULT PRO</span>
            </div>
            <div style="display:flex; align-items:center; gap:6px;">
                <span style="font-size:9px; font-weight:600; color:#10b981; background:rgba(16,185,129,0.1); padding:2px 8px; border-radius:10px; border:1px solid rgba(16,185,129,0.2); letter-spacing:1px;">LIVE</span>
            </div>
        `;
        document.body.prepend(floatBar);

        // Shift main container down to account for float bar
        const mainContent = document.querySelector('.app-inner') || document.querySelector('.app-content');
        if (mainContent) mainContent.style.paddingTop = '36px';
    }

    // 1. Setup Password Visibility Toggles (SVG-compatible)
    const EYE_OPEN = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>`;
    const EYE_CLOSE = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>`;

    document.querySelectorAll('.eye-icon').forEach(icon => {
        icon.innerHTML = EYE_OPEN;
        icon.setAttribute('data-visible', 'false');
        icon.addEventListener('click', function () {
            const trg = document.getElementById(this.getAttribute('data-target'));
            if (!trg) return;
            const isVisible = this.getAttribute('data-visible') === 'true';
            if (!isVisible) {
                trg.type = 'text';
                this.innerHTML = EYE_CLOSE;
                this.setAttribute('data-visible', 'true');
            } else {
                trg.type = 'password';
                this.innerHTML = EYE_OPEN;
                this.setAttribute('data-visible', 'false');
            }
        });
    });

    // 2. Check existing setup
    const extHash = await getStorage('ebm_master_hash');
    if (extHash) {
        switchView('login');
    } else {
        switchView('setup');
    }
});

// Setup Flow
document.getElementById('btn-setup').addEventListener('click', async () => {
    const p1 = document.getElementById('setup-master-pwd').value;
    const p2 = document.getElementById('setup-master-pwd-confirm').value;

    if (!p1 || p1 !== p2) {
        showToast("Passwords do not match!");
        return;
    }

    try {
        currentMasterKeyHash = await hashKey(p1);
        await setStorage('ebm_master_hash', currentMasterKeyHash);

        currentCryptoKey = await deriveKey(p1);
        vaultDataArray = [];
        await saveVaultToStorage();

        showToast("Vault securely initialized!");
        renderAccountsList();
        switchView('list');
        checkTempDataFromApp();
    } catch (e) {
        showToast("Initialization failed");
    }
});

// Enter key support for setup
document.getElementById('setup-master-pwd-confirm').addEventListener('keyup', (e) => {
    if (e.key === 'Enter') document.getElementById('btn-setup').click();
});

// Login Flow
document.getElementById('btn-login').addEventListener('click', async () => {
    const pwd = document.getElementById('login-master-pwd').value;
    if (!pwd) return;

    try {
        const savedHash = await getStorage('ebm_master_hash');
        const typedHash = await hashKey(pwd);

        if (savedHash !== typedHash) {
            showToast("Access Denied: Invalid Key");
            return;
        }

        currentCryptoKey = await deriveKey(pwd);

        // Decrypt DB
        const encryptedDb = await getStorage('ebm_vault_data');
        if (encryptedDb) {
            try {
                const decStr = await decryptData(encryptedDb, currentCryptoKey);
                vaultDataArray = JSON.parse(decStr) || [];
            } catch (e) {
                // Backward compatibility for old single object format
                vaultDataArray = [];
            }
        }

        showToast("Vault Unlocked");
        renderAccountsList();
        switchView('list');
        checkTempDataFromApp();
    } catch (e) {
        showToast("Decryption Error");
    }
});

// Enter key support for login
document.getElementById('login-master-pwd').addEventListener('keyup', (e) => {
    if (e.key === 'Enter') document.getElementById('btn-login').click();
});

// ------------------------------
// LIST VIEW FUNCTIONALITY
// ------------------------------

function renderAccountsList(filterText = '') {
    const listDiv = document.getElementById('accounts-list');
    listDiv.innerHTML = '';

    if (!vaultDataArray || vaultDataArray.length === 0) {
        listDiv.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">
                    <svg width="24" height="24" fill="none" stroke="var(--primary)" stroke-width="1.6" viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                </div>
                <p>Your vault is empty.<br>Add credentials to get started.</p>
            </div>`;
        return;
    }

    const lowerFilter = filterText.toLowerCase();
    let count = 0;

    vaultDataArray.forEach(acc => {
        if (lowerFilter && !acc.title.toLowerCase().includes(lowerFilter) && !acc.email.toLowerCase().includes(lowerFilter)) {
            return;
        }
        count++;
        // Avatar = first letter of title
        const initial = (acc.title || '?').charAt(0).toUpperCase();

        const card = document.createElement('div');
        card.className = 'acc-card';
        card.innerHTML = `
            <div class="acc-avatar">${escapeHtml(initial)}</div>
            <div class="acc-info">
                <div class="acc-name">${escapeHtml(acc.title)}</div>
                <div class="acc-email">${escapeHtml(acc.email)}</div>
            </div>
            <div class="acc-actions">
                <button class="icon-btn trigger-magic-flight" title="Magic Flight Autofill" data-id="${acc.id}">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M22 2L11 13"/><path d="M22 2L15 22 11 13 2 9z"/></svg>
                </button>
                <button class="icon-btn trigger-edit" title="Edit" data-id="${acc.id}">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </button>
            </div>
        `;
        listDiv.appendChild(card);
    });

    if (count === 0) {
        listDiv.innerHTML = `<div class="empty-state"><p>No results found for "${escapeHtml(filterText)}"</p></div>`;
    }

    // Attach listeners
    document.querySelectorAll('.trigger-magic-flight').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const accId = e.currentTarget.getAttribute('data-id');
            const acc = vaultDataArray.find(a => a.id === accId);
            if (acc) doMagicFlight(acc);
        });
    });

    document.querySelectorAll('.trigger-edit').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const accId = e.currentTarget.getAttribute('data-id');
            openEditView(accId);
        });
    });
}

document.getElementById('search-input').addEventListener('input', (e) => {
    renderAccountsList(e.target.value);
});

document.getElementById('btn-add-account').addEventListener('click', () => {
    openEditView(null); // null means new
});

function escapeHtml(unsafe) {
    if (!unsafe) return '';
    return unsafe.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
}

// ------------------------------
// EDIT VIEW FUNCTIONALITY
// ------------------------------

function openEditView(accountId) {
    editingAccountId = accountId;

    const titleEl = document.getElementById('edit-title-text');
    const deleteBtn = document.getElementById('btn-delete-account');

    if (accountId) {
        titleEl.textContent = 'Edit Credential';
        deleteBtn.style.display = 'block';

        const acc = vaultDataArray.find(a => a.id === accountId);
        if (acc) {
            document.getElementById('edit-profile-name').value = acc.title || '';
            document.getElementById('edit-email').value = acc.email || '';
            document.getElementById('edit-pass1').value = acc.pass1 || '';
            document.getElementById('edit-pass2').value = acc.pass2 || '';
            document.getElementById('edit-pass3').value = acc.pass3 || '';
        }
    } else {
        titleEl.textContent = 'Add Credential';
        deleteBtn.style.display = 'none';

        // Clear fields
        document.getElementById('edit-profile-name').value = '';
        document.getElementById('edit-email').value = '';
        document.getElementById('edit-pass1').value = '';
        document.getElementById('edit-pass2').value = '';
        document.getElementById('edit-pass3').value = '';
    }

    switchView('edit');
}

document.getElementById('btn-back').addEventListener('click', () => {
    switchView('list');
    renderAccountsList();
});

document.getElementById('btn-save-account').addEventListener('click', async () => {
    const title = document.getElementById('edit-profile-name').value;
    const email = document.getElementById('edit-email').value;
    const pass1 = document.getElementById('edit-pass1').value;
    const pass2 = document.getElementById('edit-pass2').value;
    const pass3 = document.getElementById('edit-pass3').value;

    if (!title) {
        showToast("Profile name is required");
        return;
    }

    if (editingAccountId) {
        // Update existing
        const idx = vaultDataArray.findIndex(a => a.id === editingAccountId);
        if (idx !== -1) {
            vaultDataArray[idx] = { id: editingAccountId, title, email, pass1, pass2, pass3, updated: Date.now() };
        }
    } else {
        // Create new
        const newId = 'acc_' + Date.now() + Math.random().toString().substr(2, 5);
        vaultDataArray.push({ id: newId, title, email, pass1, pass2, pass3, created: Date.now() });
    }

    await saveVaultToStorage();
    showToast("Successfully Encrypted & Saved");

    switchView('list');
    renderAccountsList();
});

document.getElementById('btn-delete-account').addEventListener('click', async () => {
    if (!editingAccountId) return;

    if (confirm("Are you sure you want to delete this credential forever?")) {
        vaultDataArray = vaultDataArray.filter(a => a.id !== editingAccountId);
        await saveVaultToStorage();
        showToast("Credential erased");
        switchView('list');
        renderAccountsList();
    }
});


// ------------------------------
// MAGIC FLIGHT & FLUTTER INTEROP
// ------------------------------

async function checkTempDataFromApp() {
    chrome.runtime.sendMessage({ action: "GET_PENGING_SAVE" }, (response) => {
        if (response && response.data) {
            // New credentials received from Flutter Checkbox
            // Open Edit view and prefill them automatically!
            openEditView(null);
            document.getElementById('edit-profile-name').value = "Super Admin Portal"; // default suggest
            document.getElementById('edit-email').value = response.data.email || '';
            document.getElementById('edit-pass1').value = response.data.pass1 || '';
            document.getElementById('edit-pass2').value = response.data.pass2 || '';
            document.getElementById('edit-pass3').value = response.data.pass3 || '';

            showToast("Pending Flutter data imported!");
        }
    });
}

function doMagicFlight(acc) {
    // Search active tabs globally (critical if in "Float" detached window mode)
    chrome.tabs.query({}, function (tabs) {
        if (!tabs || tabs.length === 0) {
            showToast("No active browser tabs found");
            return;
        }

        // Find the tab running the EBM Portal (or fallback to the first active tab)
        let targetTab = tabs.find(t => t.url && (t.url.includes('login') || t.url.includes('auth') || t.url.includes('localhost') || t.url.includes('127.0.0.1')));

        // If not found, use whatever the user is currently at (useful for fixed popup mode)
        if (!targetTab) targetTab = tabs.find(t => t.active && !t.url.includes('extension'));

        if (!targetTab) {
            showToast("Cannot connect to page. Is EBM Portal open?");
            return;
        }

        chrome.tabs.sendMessage(targetTab.id, {
            type: "AUTOFILL_EBM_CREDS",
            data: {
                ebmEmail: acc.email,
                ebmPass1: acc.pass1,
                ebmPass2: acc.pass2,
                ebmPass3: acc.pass3
            }
        }, () => {
            if (chrome.runtime.lastError) {
                showToast("Cannot connect to page. Reload portal.");
            } else {
                showToast("Magic Flight Executed 🚀");
            }
        });
    });
}

// ══════════════════════════════════════════════════════════════════════════════
// AUDIT LOG SECTION
// ══════════════════════════════════════════════════════════════════════════════

// Open audit view
document.getElementById('btn-open-audit').addEventListener('click', () => {
    loadAuditLog();
    switchView('audit');
    // Clear any warning badge
    chrome.runtime.sendMessage({ action: "CLEAR_BADGE" });
});

// Go back from audit
document.getElementById('btn-back-audit').addEventListener('click', () => {
    switchView('list');
    renderAccountsList();
});

// Clear all audit logs
document.getElementById('btn-clear-audit').addEventListener('click', () => {
    if (confirm("Clear all access audit log entries?")) {
        chrome.runtime.sendMessage({ action: "CLEAR_AUDIT_LOG" }, () => {
            showToast("Audit log cleared.");
            loadAuditLog();
        });
    }
});

function loadAuditLog() {
    const container = document.getElementById('audit-list');
    container.innerHTML = '<div class="audit-empty">Loading...</div>';

    chrome.runtime.sendMessage({ action: "GET_AUDIT_LOG" }, (response) => {
        const log = response && response.log ? response.log : [];

        if (log.length === 0) {
            container.innerHTML = '<div class="audit-empty">🛡️ No access attempts recorded yet.</div>';
            return;
        }

        container.innerHTML = '';
        log.forEach(entry => {
            const statusClass = (entry.status || 'UNKNOWN').toLowerCase();
            const time = entry.timestamp
                ? new Date(entry.timestamp).toLocaleString()
                : 'Unknown time';

            // Truncate device string
            const deviceStr = entry.device
                ? entry.device.substring(0, 60) + (entry.device.length > 60 ? '...' : '')
                : 'Unknown';

            const el = document.createElement('div');
            el.className = `audit-entry status-${statusClass}`;
            el.innerHTML = `
                <div class="audit-head">
                    <span class="audit-badge ${statusClass}">${entry.status || 'UNKNOWN'}</span>
                    <span class="audit-time">${time}</span>
                </div>
                <div class="audit-device">${deviceStr}</div>
                <div class="audit-meta">
                    <span class="audit-tag">${(entry.method || 'MANUAL').replace('_', ' ')}</span>
                    ${entry.vaultUsed ? '<span class="audit-tag" style="background:rgba(16,185,129,.1);color:var(--primary);">VAULT SYNCED</span>' : ''}
                    ${(entry.attempts > 1) ? `<span class="audit-tag" style="background:rgba(239,68,68,.12);color:var(--danger);">×${entry.attempts} ATTEMPTS</span>` : ''}
                </div>
            `;
            container.appendChild(el);
        });
    });
}
