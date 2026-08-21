import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../historial/domain/entities/lectura_historial.dart';
import '../../../historial/presentation/providers/historial_provider.dart';
import '../../../../app/rutas/app_router.dart';
import '../../../../core/constantes/rangos_agronomicos.dart';
import '../../../../core/tema/app_colores.dart';
import '../../../../core/utilidades/calculador_estado_sensor.dart';
import '../../../../core/widgets/tarjeta_sensor.dart';
import '../../../recomendaciones/domain/entities/recomendacion.dart';
import '../../../recomendaciones/presentation/providers/recomendaciones_provider.dart';
import '../../../sensores/domain/entities/datos_sensor_suelo.dart';
import '../../../sensores/presentation/providers/sensor_suelo_provider.dart';

// Pantalla principal de la app.
// Muestra un resumen rápido del estado del cultivo.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecturaAsync = ref.watch(lecturaSensorStreamProvider);
    final ultimaLecturaHive = ref.watch(ultimaLecturaHistorialProvider);
    final recomendacionesAsync = ref.watch(recomendacionesAsyncProvider);

    final recomendaciones = recomendacionesAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <Recomendacion>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: lecturaAsync.when(
        data: (lectura) {
          return _DashboardContenido(
            lectura: lectura,
            recomendaciones: recomendaciones,
            usandoLecturaLocal: false,
          );
        },
        loading: () {
          if (ultimaLecturaHive != null) {
            return _DashboardContenido(
              lectura: _convertirHistorialADatosSensor(ultimaLecturaHive),
              recomendaciones: recomendaciones,
              usandoLecturaLocal: true,
            );
          }

          return const _DashboardLoading();
        },
        error: (error, stackTrace) {
          if (ultimaLecturaHive != null) {
            return _DashboardContenido(
              lectura: _convertirHistorialADatosSensor(ultimaLecturaHive),
              recomendaciones: recomendaciones,
              usandoLecturaLocal: true,
            );
          }

          return _DashboardError(
            mensaje: error.toString(),
          );
        },
      ),
    );
  }

  DatosSensorSuelo _convertirHistorialADatosSensor(
    LecturaHistorial lectura,
  ) {
    return DatosSensorSuelo(
      humedadSuelo: lectura.humedad,
      temperaturaSuelo: lectura.temperatura,
      conductividadElectrica: lectura.ec,
      phSuelo: lectura.ph,
      nitrogeno: lectura.nitrogeno,
      fosforo: lectura.fosforo,
      potasio: lectura.potasio,
      fechaLectura: lectura.fechaLectura,
    );
  }
}

class _DashboardContenido extends StatelessWidget {
  const _DashboardContenido({
    required this.lectura,
    required this.recomendaciones,
    required this.usandoLecturaLocal,
  });

  final DatosSensorSuelo lectura;
  final List<Recomendacion> recomendaciones;
  final bool usandoLecturaLocal;

  @override
  Widget build(BuildContext context) {
    final sensoresConAlerta = _sensoresConAlerta(
      humedad: lectura.humedadSuelo,
      temperatura: lectura.temperaturaSuelo,
      ph: lectura.phSuelo,
      ec: lectura.conductividadElectrica,
      nitrogeno: lectura.nitrogeno,
      fosforo: lectura.fosforo,
      potasio: lectura.potasio,
    );

    return ListView(
  padding: const EdgeInsets.all(16),
  children: [
    const Text(
      'Resumen del cultivo',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    const SizedBox(height: 6),

    Text(
      'Última lectura: ${lectura.fechaLectura.hour}:${lectura.fechaLectura.minute.toString().padLeft(2, '0')}',
      style: Theme.of(context).textTheme.bodyMedium,
    ),

    if (usandoLecturaLocal) ...[
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColores.primariosuave,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColores.primario.withOpacity(0.20),
          ),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.storage_rounded,
              color: AppColores.primario,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mostrando la última lectura guardada en Hive mientras se esperan datos MQTT en vivo.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColores.textoPrincipal,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    ],

    const SizedBox(height: 16),

    if (recomendaciones.isNotEmpty || sensoresConAlerta.isNotEmpty)
  _TarjetaResumenRecomendaciones(
    totalRecomendaciones: recomendaciones.isNotEmpty
        ? recomendaciones.length
        : sensoresConAlerta.length,
    sensoresConAlerta: sensoresConAlerta,
  )
else
  const _TarjetaSinAlertas(),

    TarjetaSensor(
      titulo: 'Humedad del suelo',
      valor: lectura.humedadSuelo,
      unidad: '%',
      estado: calcularEstadoSensor(
        valor: lectura.humedadSuelo,
        rangoIdealMinimo: RangosAgronomicos.humedadSuelo.minimo,
        rangoIdealMaximo: RangosAgronomicos.humedadSuelo.maximo,
      ),
      valorMinimo: 0,
      valorMaximo: 100,
      rangoIdealMinimo: RangosAgronomicos.humedadSuelo.minimo,
      rangoIdealMaximo: RangosAgronomicos.humedadSuelo.maximo,
      icono: Icons.water_drop,
      mensajeEstado: lectura.humedadSuelo <
              RangosAgronomicos.humedadSuelo.minimo
          ? 'Se recomienda revisar el riego'
          : lectura.humedadSuelo > RangosAgronomicos.humedadSuelo.maximo
              ? 'Evitar riego y revisar drenaje'
              : 'Humedad adecuada',
    ),

    const SizedBox(height: 14),

    TarjetaSensor(
      titulo: 'Temperatura del suelo',
      valor: lectura.temperaturaSuelo,
      unidad: '°C',
      estado: calcularEstadoSensor(
        valor: lectura.temperaturaSuelo,
        rangoIdealMinimo: RangosAgronomicos.temperaturaSuelo.minimo,
        rangoIdealMaximo: RangosAgronomicos.temperaturaSuelo.maximo,
      ),
      valorMinimo: 0,
      valorMaximo: 40,
      rangoIdealMinimo: RangosAgronomicos.temperaturaSuelo.minimo,
      rangoIdealMaximo: RangosAgronomicos.temperaturaSuelo.maximo,
      icono: Icons.thermostat,
      mensajeEstado: lectura.temperaturaSuelo <
              RangosAgronomicos.temperaturaSuelo.minimo
          ? 'Temperatura baja para el cultivo'
          : lectura.temperaturaSuelo >
                  RangosAgronomicos.temperaturaSuelo.maximo
              ? 'Temperatura elevada'
              : 'Condición térmica adecuada',
    ),

    const SizedBox(height: 14),

    TarjetaSensor(
      titulo: 'pH del suelo',
      valor: lectura.phSuelo,
      unidad: '',
      estado: calcularEstadoSensor(
        valor: lectura.phSuelo,
        rangoIdealMinimo: RangosAgronomicos.phSuelo.minimo,
        rangoIdealMaximo: RangosAgronomicos.phSuelo.maximo,
      ),
      valorMinimo: 0,
      valorMaximo: 14,
      rangoIdealMinimo: RangosAgronomicos.phSuelo.minimo,
      rangoIdealMaximo: RangosAgronomicos.phSuelo.maximo,
      icono: Icons.science,
      mensajeEstado: lectura.phSuelo < RangosAgronomicos.phSuelo.minimo
          ? 'Revisar acidez del suelo'
          : lectura.phSuelo > RangosAgronomicos.phSuelo.maximo
              ? 'Revisar alcalinidad del suelo'
              : 'pH adecuado',
    ),

    const SizedBox(height: 14),

    TarjetaSensor(
      titulo: 'Conductividad eléctrica',
      valor: lectura.conductividadElectrica,
      unidad: 'dS/m',
      estado: calcularEstadoSensor(
        valor: lectura.conductividadElectrica,
        rangoIdealMinimo: RangosAgronomicos.conductividadElectrica.minimo,
        rangoIdealMaximo: RangosAgronomicos.conductividadElectrica.maximo,
      ),
      valorMinimo: 0,
      valorMaximo: 5,
      rangoIdealMinimo: RangosAgronomicos.conductividadElectrica.minimo,
      rangoIdealMaximo: RangosAgronomicos.conductividadElectrica.maximo,
      icono: Icons.bolt,
      mensajeEstado: lectura.conductividadElectrica <
              RangosAgronomicos.conductividadElectrica.minimo
          ? 'Baja disponibilidad de nutrientes'
          : lectura.conductividadElectrica >
                  RangosAgronomicos.conductividadElectrica.maximo
              ? 'Posible exceso de sales'
              : 'Nivel de sales adecuado',
    ),
  ],
);
  }

  List<String> _sensoresConAlerta({
    required double humedad,
    required double temperatura,
    required double ph,
    required double ec,
    required double nitrogeno,
    required double fosforo,
    required double potasio,
  }) {
    final sensores = <String>[];

    if (humedad < RangosAgronomicos.humedadSuelo.minimo ||
        humedad > RangosAgronomicos.humedadSuelo.maximo) {
      sensores.add('humedad');
    }

    if (temperatura < RangosAgronomicos.temperaturaSuelo.minimo ||
        temperatura > RangosAgronomicos.temperaturaSuelo.maximo) {
      sensores.add('temperatura');
    }

    if (ph < RangosAgronomicos.phSuelo.minimo ||
        ph > RangosAgronomicos.phSuelo.maximo) {
      sensores.add('pH');
    }

    if (ec < RangosAgronomicos.conductividadElectrica.minimo ||
        ec > RangosAgronomicos.conductividadElectrica.maximo) {
      sensores.add('EC');
    }

    if (nitrogeno < RangosAgronomicos.nitrogenoFructificacion.minimo) {
      sensores.add('nitrógeno');
    }

    if (fosforo < RangosAgronomicos.fosforoFructificacion.minimo) {
      sensores.add('fósforo');
    }

    if (potasio < RangosAgronomicos.potasioFructificacion.minimo) {
      sensores.add('potasio');
    }

    return sensores;
  }
}

class _TarjetaResumenRecomendaciones extends StatelessWidget {
  const _TarjetaResumenRecomendaciones({
    required this.totalRecomendaciones,
    required this.sensoresConAlerta,
  });

  final int totalRecomendaciones;
  final List<String> sensoresConAlerta;

  @override
  Widget build(BuildContext context) {
    final textoSensores = sensoresConAlerta.isEmpty
        ? 'No se detectan variables fuera de rango.'
        : 'Revisar: ${_formatearLista(sensoresConAlerta)}.';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        context.go(RutasApp.recomendaciones);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    totalRecomendaciones == 1
                        ? '1 recomendación pendiente'
                        : '$totalRecomendaciones recomendaciones pendientes',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    textoSensores,
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ver acciones recomendadas →',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 15,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearLista(List<String> items) {
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} y ${items[1]}';

    final primeros = items.sublist(0, items.length - 1).join(', ');
    final ultimo = items.last;

    return '$primeros y $ultimo';
  }
}

class _TarjetaSinAlertas extends StatelessWidget {
  const _TarjetaSinAlertas();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColores.primariosuave,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColores.borde,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColores.primario,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Todas las variables principales están dentro de rangos aceptables.',
              style: TextStyle(
                color: AppColores.textoPrincipal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({
    required this.mensaje,
  });

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColores.critico,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mensaje,
                    style: const TextStyle(
                      color: AppColores.textoPrincipal,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}