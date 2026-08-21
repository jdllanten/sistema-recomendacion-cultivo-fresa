import 'package:flutter/material.dart';

import '../../../../core/tema/app_colores.dart';

class AcercaSistemaPage extends StatelessWidget {
  const AcercaSistemaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca del sistema'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Fresa App',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColores.textoPrincipal,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Sistema móvil para monitoreo y apoyo a la toma de decisiones en cultivos de fresa.',
            style: TextStyle(
              color: AppColores.textoSecundario,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 18),

          _InfoSistemaCard(
            icono: Icons.agriculture,
            titulo: 'Propósito',
            contenido:
                'La aplicación busca transformar lecturas técnicas del suelo en información visual, comprensible y accionable para el agricultor. Su objetivo es apoyar decisiones relacionadas con riego, pH, conductividad eléctrica y nutrientes NPK.',
          ),

          SizedBox(height: 14),

          _InfoSistemaCard(
            icono: Icons.sensors,
            titulo: 'Hardware utilizado',
            contenido:
                'El sistema se plantea con un sensor de suelo RS485 Modbus 7 en 1, una ESP32 y un convertidor TTL a RS485. El sensor mide humedad, temperatura, EC, pH, nitrógeno, fósforo y potasio.',
          ),

          SizedBox(height: 14),

          _InfoSistemaCard(
            icono: Icons.wifi_tethering,
            titulo: 'Comunicación MQTT',
            contenido:
                'MQTT se usa como canal de comunicación en tiempo real entre la ESP32 y la app. La ESP32 publica un JSON con las lecturas del sensor y la aplicación se suscribe al topic configurado para actualizar Dashboard, NPK, Recomendaciones e Historial.',
          ),

          SizedBox(height: 14),

          _InfoSistemaCard(
            icono: Icons.storage,
            titulo: 'Almacenamiento local',
            contenido:
                'Las lecturas recibidas pueden guardarse localmente con Hive CE. Esto permite conservar el historial y las gráficas aunque la app se cierre o exista conectividad intermitente en la finca.',
          ),

          SizedBox(height: 14),

          _InfoSistemaCard(
            icono: Icons.cloud_sync,
            titulo: 'Firebase como fase futura',
            contenido:
                'Firebase se plantea como complemento para respaldo en la nube, sincronización entre dispositivos, gestión de usuarios, fincas e historial consolidado. No reemplaza MQTT: MQTT se usa para tiempo real y Firebase para persistencia/sincronización.',
          ),

          SizedBox(height: 14),

          _InfoSistemaCard(
            icono: Icons.offline_bolt,
            titulo: 'Contexto rural',
            contenido:
                'En zonas rurales puede haber fallos de internet. Por eso se recomienda una arquitectura con MQTT para tiempo real, almacenamiento local para tolerancia a desconexiones y Firebase para sincronización cuando la red esté disponible.',
          ),

          SizedBox(height: 14),

          _InfoSistemaCard(
            icono: Icons.psychology_alt_outlined,
            titulo: 'Relación con HCI',
            contenido:
                'La interfaz usa colores semánticos, tarjetas, gráficas y mensajes breves para reducir la carga cognitiva. En lugar de mostrar solo números, presenta estados, rangos y recomendaciones accionables.',
          ),

          SizedBox(height: 22),

          Text(
            'Arquitectura propuesta',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColores.textoPrincipal,
            ),
          ),

          SizedBox(height: 12),

          _ArquitecturaCard(),
        ],
      ),
    );
  }
}

class _InfoSistemaCard extends StatelessWidget {
  const _InfoSistemaCard({
    required this.icono,
    required this.titulo,
    required this.contenido,
  });

  final IconData icono;
  final String titulo;
  final String contenido;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
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
                    contenido,
                    style: const TextStyle(
                      color: AppColores.textoSecundario,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
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

class _ArquitecturaCard extends StatelessWidget {
  const _ArquitecturaCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: const [
            _PasoArquitectura(
              numero: '1',
              titulo: 'Sensor RS485 7 en 1',
              descripcion: 'Mide humedad, temperatura, EC, pH y NPK.',
            ),
            _SeparadorArquitectura(),
            _PasoArquitectura(
              numero: '2',
              titulo: 'ESP32',
              descripcion: 'Lee el sensor por Modbus y publica datos.',
            ),
            _SeparadorArquitectura(),
            _PasoArquitectura(
              numero: '3',
              titulo: 'MQTT',
              descripcion: 'Transporta lecturas en tiempo real.',
            ),
            _SeparadorArquitectura(),
            _PasoArquitectura(
              numero: '4',
              titulo: 'Flutter',
              descripcion: 'Muestra datos, gráficas y recomendaciones.',
            ),
            _SeparadorArquitectura(),
            _PasoArquitectura(
              numero: '5',
              titulo: 'Hive local',
              descripcion: 'Guarda historial offline en el celular.',
            ),
            _SeparadorArquitectura(),
            _PasoArquitectura(
              numero: '6',
              titulo: 'Firebase futuro',
              descripcion: 'Sincroniza y respalda datos en la nube.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PasoArquitectura extends StatelessWidget {
  const _PasoArquitectura({
    required this.numero,
    required this.titulo,
    required this.descripcion,
  });

  final String numero;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColores.primario,
          child: Text(
            numero,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
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
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descripcion,
                style: const TextStyle(
                  color: AppColores.textoSecundario,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeparadorArquitectura extends StatelessWidget {
  const _SeparadorArquitectura();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 18, top: 8, bottom: 8),
      height: 24,
      width: 2,
      color: AppColores.borde,
      alignment: Alignment.centerLeft,
    );
  }
}