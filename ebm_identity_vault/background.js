// ═══════════════════════════════════════════════════════════════════════════════
// EBM Identity Vault — Enterprise Background Service Worker
// Manifest V3 Compliant | AES-GCM 256 | Zero-Trust Architecture
// ═══════════════════════════════════════════════════════════════════════════════

// ─── State ───────────────────────────────────────────────────────────────────
let pendingVaultData = null; // Temporary credential buffer from Flutter

// ─── Install / Startup ───────────────────────────────────────────────────────
chrome.runtime.onInstalled.addListener(() => {
    console.log("[EBM Vault] Extension installed and background worker active.");
    chrome.storage.local.set({ ebm_vault_status: "INSTALLED", ebm_install_time: Date.now() });
});

// ─── Main Message Router ─────────────────────────────────────────────────────
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {

    // ── (1) Flutter → Extension: Temporarily buffer credentials ──
    if (message.action === "TEMP_SAVE_VAULT_DATA") {
        pendingVaultData = message.data;
        sendResponse({ status: "buffered" });

        // Show badge to notify user to open popup
        chrome.action.setBadgeText({ text: "NEW" });
        chrome.action.setBadgeBackgroundColor({ color: "#00FF88" });

        return true;
    }

    // ── (2) Popup → Background: Retrieve buffered data ──
    if (message.action === "GET_PENGING_SAVE") {
        sendResponse({ data: pendingVaultData });
        pendingVaultData = null; // Clear after retrieval

        // Clear badge
        chrome.action.setBadgeText({ text: "" });

        return true;
    }

    // ── (3) Popup → Background: Clear badge after viewing ──
    if (message.action === "CLEAR_BADGE") {
        chrome.action.setBadgeText({ text: "" });
        sendResponse({ status: "cleared" });
        return true;
    }

    // ── (4) Login Page → Background: Log access attempts locally ──
    if (message.action === "LOG_VAULT_ACCESS") {
        _logVaultAccess(message.data, sender);
        sendResponse({ status: "logged" });
        return true;
    }

    // ── (5) Popup → Background: Get audit log history ──
    if (message.action === "GET_AUDIT_LOG") {
        chrome.storage.local.get(["ebm_access_log"], (result) => {
            sendResponse({ log: result.ebm_access_log || [] });
        });
        return true; // Keep message channel open for async
    }

    // ── (6) Popup → Background: Clear audit log ──
    if (message.action === "CLEAR_AUDIT_LOG") {
        chrome.storage.local.set({ ebm_access_log: [] }, () => {
            sendResponse({ status: "cleared" });
        });
        return true;
    }

    // ── (7) Background: Signal VAULT_READY to active tab ──
    if (message.action === "SIGNAL_VAULT_TO_TAB") {
        chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
            if (tabs.length > 0) {
                chrome.tabs.sendMessage(tabs[0].id, {
                    type: "EBM_VAULT_READY",
                    enabled: true
                });
            }
        });
        sendResponse({ status: "signaled" });
        return true;
    }
});

// ─── Internal: Log Access Attempts ───────────────────────────────────────────
function _logVaultAccess(data, sender) {
    chrome.storage.local.get(["ebm_access_log"], (result) => {
        const log = result.ebm_access_log || [];

        const entry = {
            id: "ATT-" + Date.now(),
            status: data.status || "UNKNOWN",       // SUCCESS | FAILED | BLOCKED
            email: data.email || "N/A",
            method: data.method || "MANUAL",         // MANUAL | VAULT_AUTOFILL
            device: navigator.userAgent,
            tabUrl: sender.tab ? sender.tab.url : "Unknown",
            timestamp: new Date().toISOString(),
            attempts: data.attempts || 1,
            vaultUsed: data.vaultUsed || false,
        };

        log.unshift(entry); // Most recent first

        // Keep only last 200 entries
        const trimmed = log.slice(0, 200);
        chrome.storage.local.set({ ebm_access_log: trimmed });

        // Alert via badge if FAILED or BLOCKED
        if (entry.status === "FAILED" || entry.status === "BLOCKED") {
            chrome.action.setBadgeText({ text: "⚠" });
            chrome.action.setBadgeBackgroundColor({ color: "#FF4444" });
        }
    });
}
