void setupVaultListener(Function(Map<String, dynamic> data, bool autoSubmit) onAutoFill, Function(bool) onConnectionChanged) {}
void triggerVaultSave(Map<String, String> credentials) {}
void triggerAuditLog({required String status, required String email, required String method, required int attempts, required bool vaultUsed}) {}
