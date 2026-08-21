import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notificaciones/presentation/providers/fcm_provider.dart';

class InicializadorNotificacionesFcm extends ConsumerStatefulWidget {
  const InicializadorNotificacionesFcm({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<InicializadorNotificacionesFcm> createState() =>
      _InicializadorNotificacionesFcmState();
}

class _InicializadorNotificacionesFcmState
    extends ConsumerState<InicializadorNotificacionesFcm> {
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarFcm();
    });
  }

  Future<void> _inicializarFcm() async {
    if (_inicializado) return;

    _inicializado = true;

    try {
      final service = ref.read(fcmServiceProvider);
      await service.inicializar();
    } catch (e) {
      debugPrint('❌ Error inicializando FCM: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}