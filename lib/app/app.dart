import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/inicializador_notificaciones_fcm.dart';
import '../core/widgets/sincronizacion_inicial_firestore.dart';
import '../core/tema/app_theme.dart';
import '../features/historial/presentation/providers/historial_provider.dart';
import '../features/historial/presentation/providers/sincronizacion_firestore_provider.dart';
import 'rutas/app_router.dart';

//Configuración de la raíz de la aplicación

class FresaApp extends ConsumerWidget {
  const FresaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Activa la sincronización de lecturas MQTT hacia el historial.
    // Esto permite que las lecturas recibidas se acumulen mientras la app está abierta.
    ref.watch(sincronizarHistorialConSensorProvider);
    ref.watch(sincronizarLecturasFirestoreProvider);
    //ref.watch(sincronizarDesdeFirestoreAutomaticoProvider);
    
    return InicializadorNotificacionesFcm(
      child: SincronizacionInicialFirestore(
        child: MaterialApp.router(
          title: 'Fresa App',
          theme: AppTheme.temaClaro,
          routerConfig: router,
        ),
      ),
    );
  }
}
