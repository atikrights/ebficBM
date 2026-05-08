# Enterprise Password Manager Development Blueprint

## Overview
Transforming a simple save-box extension into a high-level password manager (like 1Password/Bitwarden) with advanced data structures and a multi-view UI.

## Phase 1: Data Structure Modification
- **New Format:** Array of Objects `[{ "id": "1", "title": "Super Admin 01", "email": "admin1@ebm.com", "keys": ["a", "b", "c"] }]`
- **Security:** AES-GCM 256 encryption for the entire array in `chrome.storage.local`.

## Phase 2: UI & UX Architecture
1. **Unlock Page:** Master password entry with premium glass-morphism. Auto-lock after 5 mins idle.
2. **Account List Page:**
   - Search bar for quick access.
   - List of cards with "Magic Flight/Login" (auto-fill) and "Edit" icon.
   - Large "+ Add New Account" button at bottom.
3. **Edit/Modify Page:** 
   - Fields: Profile Name, Email, Key Alpha, Beta, Gamma.
   - Actions: Update Account (Blue glow) and Delete Account (Red danger).

## Phase 3: Flutter Integration
- **Multiple Injection:** specific account data via `window.postMessage`.
- **Auto-Save Logic:** Intelligent checking for existing emails to update or add new records.