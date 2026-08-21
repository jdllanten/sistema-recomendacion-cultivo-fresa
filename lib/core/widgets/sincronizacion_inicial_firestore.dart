import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/historial/presentation/providers/historial_provider.dart';

import '../../features/historial/presentation/providers/sincronizacion_firestore_provider.dart';

class SincronizacionInicialFirestore extends ConsumerStatefulWidget {
  const SincronizacionInicialFirestore({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<SincronizacionInicialFirestore> createState() =>
      _SincronizacionInicialFirestoreState();
}

class _SincronizacionInicialFirestoreState
    extends ConsumerState<SincronizacionInicialFirestore> {
  bool _yaSincronizo = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sincronizarDesdeFirestore();
    });
  }

  Future<void> _sincronizarDesdeFirestore() async {
    if (_yaSincronizo) return;

    _yaSincronizo = true;

    final sincronizar = ref.read(
      sincronizarHistorialDesdeFirestoreUsecaseProvider,
    );

    ref.read(sincronizandoDesdeFirestoreProvider.notifier).state = true;
    ref.read(errorDescargaFirestoreProvider.notifier).state = null;

    try {
      final total = await sincronizar();

ref.read(historialSesionProvider.notifier).recargar();

ref.read(ultimaDescargaFirestoreProvider.notifier).state = DateTime.now();

      debugPrint(
        'Sincronización inicial desde Firestore completada: $total lecturas',
      );
    } catch (e) {
      ref.read(errorDescargaFirestoreProvider.notifier).state = e.toString();

      debugPrint(
        'Error en sincronización inicial desde Firestore: $e',
      );
    } finally {
      ref.read(sincronizandoDesdeFirestoreProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}