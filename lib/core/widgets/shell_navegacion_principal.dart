import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/historial/presentation/providers/historial_provider.dart';
import '../../features/sensores/presentation/providers/estado_sensor_visual_provider.dart';
import '../../features/sensores/presentation/providers/sensor_suelo_provider.dart';

class ShellNavegacionPrincipal extends ConsumerWidget {
  const ShellNavegacionPrincipal({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (estadoMqtt, ultimaLecturaMqtt) = ref.watch(
      estadoConexionMqttProvider,
    );

    final ultimaLecturaUsb = ref.watch(fechaLecturaUsbActivaProvider);
    final ultimaLecturaHistorial = ref.watch(ultimaLecturaHistorialProvider);

    final estadoVisual = _resolverEstadoVisual(
      estadoMqtt: estadoMqtt,
      ultimaLecturaMqtt: ultimaLecturaMqtt,
      ultimaLecturaUsb: ultimaLecturaUsb,
      ultimaLecturaGuardada: ultimaLecturaHistorial?.fechaLectura,
    );

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: navigationShell),
          _BarraEstadoSensor(
            activo: estadoVisual.activo,
            ultimaLectura: estadoVisual.ultimaLectura,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science),
            label: 'Plan nutric.',
          ),
          NavigationDestination(
            icon: Icon(Icons.recommend_outlined),
            selectedIcon: Icon(Icons.recommend),
            label: 'Recom.',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  _EstadoVisualSensor _resolverEstadoVisual({
    required EstadoConexionMqtt estadoMqtt,
    required DateTime? ultimaLecturaMqtt,
    required DateTime? ultimaLecturaUsb,
    required DateTime? ultimaLecturaGuardada,
  }) {
    DateTime? ultimaMasReciente;

    void tomarSiEsMasReciente(DateTime? fecha) {
      if (fecha == null) return;

      if (ultimaMasReciente == null || fecha.isAfter(ultimaMasReciente!)) {
        ultimaMasReciente = fecha;
      }
    }

    // 1. Lectura MQTT en tiempo real.
    tomarSiEsMasReciente(ultimaLecturaMqtt);

    // 2. Promedio USB mostrado en pantalla principal.
    tomarSiEsMasReciente(ultimaLecturaUsb);

    // 3. Última lectura guardada en Hive/Firebase.
    // Esto permite mostrar "Sensor inactivo hace "tanto tiempo"" 
    tomarSiEsMasReciente(ultimaLecturaGuardada);

    if (ultimaMasReciente == null) {
      return const _EstadoVisualSensor(
        activo: false,
        ultimaLectura: null,
      );
    }

    final activo = lecturaEstaActiva(ultimaMasReciente!);

    return _EstadoVisualSensor(
      activo: activo,
      ultimaLectura: ultimaMasReciente,
    );
  }
}

class _EstadoVisualSensor {
  const _EstadoVisualSensor({
    required this.activo,
    required this.ultimaLectura,
  });

  final bool activo;
  final DateTime? ultimaLectura;
}

class _BarraEstadoSensor extends StatelessWidget {
  const _BarraEstadoSensor({
    required this.activo,
    required this.ultimaLectura,
  });

  final bool activo;
  final DateTime? ultimaLectura;

  @override
  Widget build(BuildContext context) {
    final color = activo ? Colors.green.shade700 : Colors.orange.shade700;
    final icono = activo ? Icons.sensors_rounded : Icons.sensors_off_rounded;
    final texto = _textoEstado();

    return Container(
      width: double.infinity,
      color: color.withOpacity(0.10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          Icon(icono, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _textoEstado() {
    if (activo) {
      return 'Sensor activo';
    }

    if (ultimaLectura == null) {
      return 'Sensor inactivo';
    }

    return 'Sensor inactivo ${tiempoRelativoLectura(ultimaLectura!)}';
  }
}
