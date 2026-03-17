import 'dart:async';
import 'package:flutter/material.dart';
import '../models/form_mode.dart';
import '../models/lock_status.dart';


mixin FormEditingMixin<T extends StatefulWidget> on State<T> {
  FormMode mode = FormMode.view;
  Timer? lockRefreshTimer;
  bool hasLock = false;

  // Información del bloqueo (si otro usuario lo tiene)
  String? lockedBy;
  DateTime? lockedAt;

  bool get isLockedByAnotherUser =>
      lockedBy != null && !hasLock;

  // Métodos que cada formulario debe implementar
  String get entityName;
  int? get recordId;
  String get sessionId;        
  Future<LockResult> acquireLock();
  Future<void> releaseLock();
  Future<void> refreshLock();
  Future<void> saveChanges();
  Future<LockStatus> fetchLockStatus(); // ⭐ nuevo

  // -----------------------------------------
  // START EDITING
  // -----------------------------------------
  Future<void> startEditing() async {
    print("entro a star editing en mixing");
    final result = await acquireLock();

    if (!result.success) {
      hasLock = false;

      // Guardar info del bloqueo
      lockedBy = result.lockedBy;
      lockedAt = result.lockedAt;

    //  print("🔒 startEditing → NO se adquirió lock (hasLock=false)");

      // Mostrar popup compacto
      if (lockedBy != null) {
        showLockedPopup(lockedBy!, lockedAt);
      }

      return;
    }

    // Lock adquirido correctamente
    hasLock = true;
    lockedBy = null;
    lockedAt = null;

  //  print("🔓 startEditing → Lock adquirido correctamente (hasLock=true)");

    setState(() {
      mode = FormMode.edit;
    });

    _startRefreshTimer();
  }

  // -----------------------------------------
  // CANCEL EDITING
  // -----------------------------------------
  Future<void> cancelEditing() async {
   //  print("MIXIN: cancelEditing() llamado");

    if (hasLock) {
   //       print("MIXIN: tiene lock, llamando releaseLock()");

      await releaseLock();
  //     print("MIXIN: releaseLock() terminó");

      hasLock = false;
    }

    lockRefreshTimer?.cancel();

    setState(() {
      mode = FormMode.view;
    });
  }

  // -----------------------------------------
  // SAVE
  // -----------------------------------------
  Future<void> save() async {
    await saveChanges();

    if (hasLock) {
      await releaseLock();
      hasLock = false;
    }

    lockRefreshTimer?.cancel();

    setState(() {
      mode = FormMode.view;
    });
  }

  // -----------------------------------------
  // REFRESH TIMER
  // -----------------------------------------
  void _startRefreshTimer() {
    lockRefreshTimer?.cancel();

    lockRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => refreshLock(),
    );
  }

  @override
  void dispose() {
   // print(">>> MIXIN: dispose() llamado");
    lockRefreshTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // ⭐ CHECK EXISTING LOCK (nuevo)
  // ============================================================
  Future<void> checkExistingLock() async {
    try {
      final status = await fetchLockStatus();

      if (status.locked && status.sessionId != sessionId) {
        lockedBy = status.lockedBy;
        lockedAt = status.lockedAt;
        hasLock = false;

     //   print("🔒 Registro YA estaba bloqueado por $lockedBy");

        setState(() {});
      }
    } catch (e) {
   //   print("⚠ Error consultando lock: $e");
    }
  }

  // ============================================================
  // ⭐ BANNER SUPERIOR
  // ============================================================
  Widget buildLockBanner() {
  if (!isLockedByAnotherUser) return const SizedBox.shrink();

  final elapsed = lockedAt != null
      ? formatElapsed(DateTime.now().difference(lockedAt!))
      : "";

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.red.shade100,
      border: Border(
        bottom: BorderSide(color: Colors.red.shade300, width: 0.5),
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.lock, color: Colors.red.shade700, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            "Bloqueado por $lockedBy — $elapsed",
            style: TextStyle(
              color: Colors.red.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

  // ============================================================
  // ⭐ POPUP COMPACTO
  // ============================================================
  void showLockedPopup(String user, DateTime? lockedAt) {
    final elapsed = lockedAt != null
        ? formatElapsed(DateTime.now().difference(lockedAt))
        : "";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.lock, color: Colors.red, size: 26),
            SizedBox(width: 10),
            Text("Registro bloqueado"),
          ],
        ),
        content: Text(
          "Este registro está siendo editado por:\n"
          "• $user\n"
          "${lockedAt != null ? "• Desde $elapsed" : ""}",
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ⭐ FORMATEADOR DE TIEMPO
  // ============================================================
  String formatElapsed(Duration d) {
    if (d.inMinutes < 1) return "hace unos segundos";
    if (d.inMinutes < 60) return "hace ${d.inMinutes} min";
    if (d.inHours < 24) return "hace ${d.inHours} h";
    return "hace ${d.inDays} días";
  }
}

// ============================================================
// ⭐ LockResult (vive en este archivo)
// ============================================================
class LockResult {
  final bool success;
  final bool conflict;
  final String? lockedBy;
  final DateTime? lockedAt;

  LockResult({
    required this.success,
    required this.conflict,
    this.lockedBy,
    this.lockedAt,
  });
}
/*
// ============================================================
// ⭐ LockStatus (vive en este archivo)
// ============================================================
class LockStatus {
  final bool locked;
  final String? lockedBy;
  final DateTime? lockedAt;
  final String? sessionId;

  LockStatus({
    required this.locked,
    this.lockedBy,
    this.lockedAt,
    this.sessionId,
  });
   String get currentSessionId => ""; 
}
*/
/*
  factory LockStatus.fromJson(Map<String, dynamic> json) {
    return LockStatus(
      locked: json["locked"] ?? false,
      lockedBy: json["lockedBy"],
      lockedAt: json["lockedAt"] != null
          ? DateTime.parse(json["lockedAt"])
          : null,
      sessionId: json["sessionId"],
    );
  }

  // Si querés agregar esto luego:
  //String get currentSessionId => ""; // lo llenás desde tu API client
}
*/