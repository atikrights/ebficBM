// This script runs in the context of the web page

// 1. Show extension presence marker ONLY on login page dynamically (SPA Friendly)
let statusDiv = null;

function updateVaultIndicator() {
    const isLoginPage = window.location.href.includes("login") || window.location.href.includes("sp-login") || window.location.href.includes("auth");
    
    if (isLoginPage) {
        if (!statusDiv) {
            statusDiv = document.createElement('div');
            statusDiv.id = 'ebm_extension_indicator';
            statusDiv.style.position = 'fixed';
            statusDiv.style.bottom = '20px';
            statusDiv.style.right = '20px';
            statusDiv.style.width = '18px';
            statusDiv.style.height = '18px';
            statusDiv.style.borderRadius = '50%';
            statusDiv.style.backgroundColor = '#00ff88';
            statusDiv.style.boxShadow = '0 0 15px rgba(0, 255, 136, 0.6), inset 0 0 5px rgba(255,255,255,0.5)';
            statusDiv.style.zIndex = '99999999';
            statusDiv.style.border = '2px solid rgba(0,0,0,0.5)';
            statusDiv.title = 'EBM Secure Vault Connected';
            document.body.appendChild(statusDiv);
        }
        statusDiv.style.display = 'block';
    } else {
        if (statusDiv) {
            statusDiv.style.display = 'none';
        }
    }
}
// Check every 500ms since Flutter is a Single Page Application
setInterval(updateVaultIndicator, 500);
updateVaultIndicator();

// Send a secure message to the frontend (Flutter) that the Vault is connected
setTimeout(() => {
    window.postMessage({ type: "EBM_VAULT_READY", enabled: true }, "*");
}, 500);

// 2. Listen to website explicitly sending credentials to save when Login happens
window.addEventListener("message", (event) => {
    // SECURITY LEVEL MAX: Ensure the message is strictly from our own trusted window & origin
    if (event.source !== window || event.origin !== window.location.origin) {
        return;
    }

    // Explicit domain verification
    const trustedOrigins = [
        "https://com.ebfic.store", 
        "https://ebm.ebfic.store",
        "https://ebfic.store"
    ];
    if (!trustedOrigins.includes(event.origin) && !event.origin.startsWith("http://localhost:")) {
        console.warn("EBM Identity Vault: Blocked unauthorized vault access from", event.origin);
        return;
    }

    if (event.data.type === "EBM_TRIGGER_SAVE") {
        const confirmSave = confirm("SECURITY ALERT: Do you authorize EBM Identity Vault to encrypt and save this active session?");
        if (confirmSave) {
            chrome.runtime.sendMessage({ 
                action: "TEMP_SAVE_VAULT_DATA", 
                data: event.data.payload 
            }, (res) => {
                alert("Vault Buffer Secured! Click the Extension Icon at the top to permanently list and lock the new keys.");
            });
        }
    }

    // ── Audit Log: Forward login attempt event to background worker ──
    if (event.data.type === "EBM_AUDIT_LOG") {
        chrome.runtime.sendMessage({
            action: "LOG_VAULT_ACCESS",
            data: event.data.payload
        });
    }
});

// 3. User clicked Magic Flight in POPUP UI. Inject right into the flutter code!
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.type === "AUTOFILL_EBM_CREDS") {
        window.postMessage({
            type: "EBM_EXTENSION_AUTOFILL",
            payload: request.data,
            autoSubmit: true
        }, "*");
        sendResponse({status: "success"});
    }
});
