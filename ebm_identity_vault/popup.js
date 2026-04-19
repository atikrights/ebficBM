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

// Utils
function showToast(message) {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.classList.add('show');
    setTimeout(() => { toast.classList.remove('show'); }, 3000);
}

function switchView(viewName) {
    Object.values(views).forEach(v => v.classList.remove('active-view'));
    views[viewName].classList.add('active-view');
}

// Float / PopOut functionality
document.getElementById('btn-popout').addEventListener('click', () => {
    chrome.windows.create({
        url: chrome.runtime.getURL("popup.html"),
        type: "popup",
        width: 400,
        height: 600
    });
});

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
    } catch(e) {
        showToast("Error saving vault");
    }
}

// Initialization Flow
document.addEventListener('DOMContentLoaded', async () => {
    // 1. Setup Password Visibility Toggles
    document.querySelectorAll('.eye-icon').forEach(icon => {
        icon.addEventListener('click', function() {
            const trg = document.getElementById(this.getAttribute('data-target'));
            if (trg.type === 'password') {
                trg.type = 'text';
                this.textContent = '🔒';
            } else {
                trg.type = 'password';
                this.textContent = '👁️';
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

    // Auto-focus logic check via background
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
            } catch(e) {
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
        listDiv.innerHTML = '<div style="color:var(--text-dim); text-align:center; padding: 20px; font-size:11px;">No credentials saved yet.</div>';
        return;
    }

    const lowerFilter = filterText.toLowerCase();

    vaultDataArray.forEach(acc => {
        if (lowerFilter && !acc.title.toLowerCase().includes(lowerFilter) && !acc.email.toLowerCase().includes(lowerFilter)) {
            return;
        }

        const card = document.createElement('div');
        card.className = 'account-card';
        card.innerHTML = `
            <div class="acc-info">
                <div class="acc-title">${escapeHtml(acc.title)}</div>
                <div class="acc-email">${escapeHtml(acc.email)}</div>
            </div>
            <div class="acc-actions">
                <button class="icon-btn trigger-magic-flight" title="Magic Flight Autofill" data-id="${acc.id}">🚀</button>
                <button class="icon-btn trigger-edit" title="Edit Data" data-id="${acc.id}">✏️</button>
            </div>
        `;
        listDiv.appendChild(card);
    });

    // Attach listeners
    document.querySelectorAll('.trigger-magic-flight').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const accId = e.currentTarget.getAttribute('data-id');
            const acc = vaultDataArray.find(a => a.id === accId);
            if(acc) doMagicFlight(acc);
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
    if(!unsafe) return '';
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
        if(acc) {
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

    if(!title) {
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
        const newId = 'acc_' + Date.now() + Math.random().toString().substr(2,5);
        vaultDataArray.push({ id: newId, title, email, pass1, pass2, pass3, created: Date.now() });
    }

    await saveVaultToStorage();
    showToast("Successfully Encrypted & Saved");
    
    switchView('list');
    renderAccountsList();
});

document.getElementById('btn-delete-account').addEventListener('click', async () => {
    if(!editingAccountId) return;
    
    if(confirm("Are you sure you want to delete this credential forever?")) {
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
    chrome.tabs.query({}, function(tabs) {
        if(!tabs || tabs.length === 0) {
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
                <div class="audit-header">
                    <span class="audit-status ${statusClass}">${entry.status || 'UNKNOWN'}</span>
                    <span class="audit-time">${time}</span>
                </div>
                <div class="audit-device">${deviceStr}</div>
                <div class="audit-meta">
                    <span class="audit-tag">${(entry.method || 'MANUAL').replace('_', ' ')}</span>
                    ${entry.vaultUsed ? '<span class="audit-tag vault-tag">VAULT SYNCED</span>' : ''}
                    ${(entry.attempts > 1) ? `<span class="audit-tag" style="background:rgba(239,68,68,0.15);color:#ef4444;">×${entry.attempts} ATTEMPTS</span>` : ''}
                </div>
            `;
            container.appendChild(el);
        });
    });
}
