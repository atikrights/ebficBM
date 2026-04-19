import 'dart:html' as html;
import 'dart:js_util' as js_util;

void setupVaultListener(Function(Map<String, dynamic> data, bool autoSubmit) onAutoFill, Function(bool) onConnectionChanged) {
  html.window.onMessage.listen((event) {
    var data = event.data;
    if (data == null) return;
    
    // Convert JS Object to Map safely if needed
    final mapData = js_util.dartify(data) as Map<dynamic, dynamic>?;
    if (mapData == null) return;

    if (mapData['type'] == 'EBM_VAULT_READY') {
      onConnectionChanged(true);
    } 
    else if (mapData['type'] == 'EBM_EXTENSION_AUTOFILL') {
      final payload = mapData['payload'];
      final bool autoSubmit = mapData['autoSubmit'] == true;
      
      final safePayload = <String, dynamic>{};
      if (payload != null && payload is Map) {
        safePayload['ebmEmail'] = payload['ebmEmail'] ?? '';
        safePayload['ebmPass1'] = payload['ebmPass1'] ?? '';
        safePayload['ebmPass2'] = payload['ebmPass2'] ?? '';
        safePayload['ebmPass3'] = payload['ebmPass3'] ?? '';
      }
      onAutoFill(safePayload, autoSubmit);
    }
  });
}

void triggerVaultSave(Map<String, String> credentials) {
  html.window.postMessage({
    'type': 'EBM_TRIGGER_SAVE',
    'payload': {
      'email': credentials['email'],
      'pass1': credentials['pass1'],
      'pass2': credentials['pass2'],
      'pass3': credentials['pass3'],
    }
  }, '*');
}

/// ✅ Sends login attempt result to the Extension Background for audit logging
void triggerAuditLog({
  required String status,   // SUCCESS | FAILED | BLOCKED
  required String email,
  required String method,   // MANUAL | VAULT_AUTOFILL
  required int attempts,
  required bool vaultUsed,
}) {
  html.window.postMessage({
    'type': 'EBM_AUDIT_LOG',
    'payload': {
      'status': status,
      'email': email,
      'method': method,
      'attempts': attempts,
      'vaultUsed': vaultUsed,
    }
  }, '*');
}
