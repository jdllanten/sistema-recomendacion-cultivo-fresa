import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constantes/configuracion_mqtt.dart';
import '../../../../core/tema/app_colores.dart';
import '../providers/sensor_suelo_provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/rutas/app_router.dart';

//Pantalla de prueba para validar recepción de datos por MQTT.
class MqttTestPage extends ConsumerWidget {
  const MqttTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecturaAsync = ref.watch(lecturaSensorStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba MQTT'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Conexión MQTT',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Esta pantalla permite validar si la app recibe datos del sensor por MQTT.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          const _MqttConfigCard(),

          const SizedBox(height: 16),

          lecturaAsync.when(
            loading: () => const _EstadoConexionCard(
              titulo: 'Esperando datos',
              descripcion:
                  'La app está esperando una lectura. Si usas mock, debe aparecer una lectura simulada.',
              icono: Icons.hourglass_top,
              color: Colors.orange,
            ),
            error: (error, stackTrace) => _EstadoConexionCard(
              titulo: 'Error de conexión',
              descripcion: error.toString(),
              icono: Icons.error_outline,
              color: AppColores.critico,
            ),
            data: (lectura) => Column(
              children: [
                const _EstadoConexionCard(
                  titulo: 'Lectura recibida',
                  descripcion:
                      'La app recibió e interpretó correctamente una lectura del sensor.',
                  icono: Icons.check_circle_outline,
                  color: AppColores.primario,
                ),
                const SizedBox(height: 16),
                _LecturaMqttCard(
                  titulo: 'Humedad del suelo',
                  valor: '${lectura.humedadSuelo.toStringAsFixed(1)} %',
                  icono: Icons.water_drop,
                ),
                const SizedBox(height: 12),
                _LecturaMqttCard(
                  titulo: 'Temperatura del suelo',
                  valor: '${lectura.temperaturaSuelo.toStringAsFixed(1)} °C',
                  icono: Icons.thermostat,
                ),
                const SizedBox(height: 12),
                _LecturaMqttCard(
                  titulo: 'pH del suelo',
                  valor: lectura.phSuelo.toStringAsFixed(1),
                  icono: Icons.science,
                ),
                const SizedBox(height: 12),
                _LecturaMqttCard(
                  titulo: 'Conductividad eléctrica',
                  valor:
                      '${lectura.conductividadElectrica.toStringAsFixed(1)} dS/m',
                  icono: Icons.bolt,
                ),
                const SizedBox(height: 12),
                _LecturaMqttCard(
                  titulo: 'Nitrógeno',
                  valor: '${lectura.nitrogeno.toStringAsFixed(1)} ppm',
                  icono: Icons.grass,
                ),
                const SizedBox(height: 12),
                _LecturaMqttCard(
                  titulo: 'Fósforo',
                  valor: '${lectura.fosforo.toStringAsFixed(1)} ppm',
                  icono: Icons.eco,
                ),
                const SizedBox(height: 12),
                _LecturaMqttCard(
                  titulo: 'Potasio',
                  valor: '${lectura.potasio.toStringAsFixed(1)} ppm',
                  icono: Icons.local_florist,
                ),
                const SizedBox(height: 16),
                const AccesoPlanNutricionalSensoresCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MqttConfigCard extends StatelessWidget {
  const _MqttConfigCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Configuración actual',
              style: TextStyle(
                color: AppColores.textoPrincipal,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12),
            _ConfigItem(
              titulo: 'Modo',
              valor: ConfiguracionMqtt.usarDatosMock
                  ? 'Datos simulados'
                  : 'MQTT real',
            ),
            SizedBox(height: 8),
            _ConfigItem(
              titulo: 'Servidor',
              valor: ConfiguracionMqtt.servidor,
            ),
            SizedBox(height: 8),
            _ConfigItem(
              titulo: 'Puerto',
              valor: '${ConfiguracionMqtt.puerto}',
            ),
            SizedBox(height: 8),
            _ConfigItem(
              titulo: 'Topic',
              valor: ConfiguracionMqtt.topicSensor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  const _ConfigItem({
    required this.titulo,
    required this.valor,
  });

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            titulo,
            style: const TextStyle(
              color: AppColores.textoSecundario,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
              color: AppColores.textoPrincipal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EstadoConexionCard extends StatelessWidget {
  const _EstadoConexionCard({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icono,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: AppColores.textoPrincipal,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      color: AppColores.textoSecundario,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LecturaMqttCard extends StatelessWidget {
  const _LecturaMqttCard({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  final String titulo;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColores.primariosuave,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icono,
                color: AppColores.primario,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  color: AppColores.textoSecundario,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              valor,
              style: const TextStyle(
                color: AppColores.textoPrincipal,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccesoPlanNutricionalSensoresCard extends StatelessWidget {
  const AccesoPlanNutricionalSensoresCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColores.primariosuave,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColores.primario.withOpacity(0.22),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          context.push(RutasApp.planNutricionalNpk);
        },
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                Icons.calculate_rounded,
                color: AppColores.primario,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan nutricional NPK',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColores.textoPrincipal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Usa las lecturas de nitrógeno, fósforo y potasio para estimar faltantes y fertilizantes sugeridos.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppColores.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColores.primario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}