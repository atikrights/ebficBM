// EBM Identity Vault Enterprise Background Service
// Uses Manifest V3 background service workers

let pendingVaultData = null; // Holds credentials temporary passed from Flutter until vault unlocks

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    
    // Flutter says: "Save this key". We hold it in memory until popup opens
    if (message.action === "TEMP_SAVE_VAULT_DATA") {
        pendingVaultData = message.data;
        sendResponse({ status: "buffered" });
        return true;
    }
    
    // Popup asks: "Any pending data from Flutter?"
    if (message.action === "GET_PENGING_SAVE") {
        sendResponse({ data: pendingVaultData });
        pendingVaultData = null; // Clear it out so it doesn't prompt again
        return true;
    }

});
