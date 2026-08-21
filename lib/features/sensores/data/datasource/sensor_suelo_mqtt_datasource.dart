import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../../../core/constantes/configuracion_mqtt.dart';
import '../models/datos_sensor_suelo_model.dart';


class SensorSueloMqttDatasource {
  SensorSueloMqttDatasource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _subscription;

  bool _conectando = false;
  bool _conectado = false;
  bool _escuchando = false;

  final StreamController<DatosSensorSueloModel> _controller =
      StreamController<DatosSensorSueloModel>.broadcast();

  Stream<DatosSensorSueloModel> get lecturasStream => _controller.stream;

  Future<void> conectar() async {
    if (_conectado || _conectando) {
      return;
    }

    _conectando = true;

    final clienteIdUnico =
        '${ConfiguracionMqtt.clienteId}_${DateTime.now().millisecondsSinceEpoch}';

    final client = MqttServerClient(
      ConfiguracionMqtt.servidor,
      clienteIdUnico,
    );

    _client = client;

    client.port = ConfiguracionMqtt.puerto;
    client.secure = false;

    // Puede cambiarse a false cuando terminen las pruebas.
    client.logging(on: true);

    // MQTT 3.1.1.
    client.setProtocolV311();

    client.keepAlivePeriod = 20;
    client.connectTimeoutPeriod = 5000;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;

    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clienteIdUnico)
        .startClean();

    try {
      await client.connect();
    } catch (error) {
      _conectando = false;
      _conectado = false;

      client.disconnect();

      _agregarError(
        'No se pudo conectar al broker MQTT: $error',
      );

      return;
    }

    final estado = client.connectionStatus?.state;

    if (estado != MqttConnectionState.connected) {
      _conectando = false;
      _conectado = false;

      _agregarError(
        'No se logró conexión MQTT. Estado: $estado',
      );

      return;
    }

    _conectando = false;
    _conectado = true;

    _escucharMensajes(client);

    client.subscribe(
      ConfiguracionMqtt.topicSensor,
      MqttQos.atLeastOnce,
    );
  }

  void _escucharMensajes(MqttServerClient client) {
    if (_escuchando) {
      return;
    }

    final updates = client.updates;

    if (updates == null) {
      _agregarError(
        'No se pudo iniciar la escucha de mensajes MQTT.',
      );
      return;
    }

    _escuchando = true;

    _subscription = updates.listen(
      (eventos) {
        for (final evento in eventos) {
          final mensaje = evento.payload as MqttPublishMessage;

          final payload = MqttPublishPayload.bytesToStringAsString(
            mensaje.payload.message,
          );

          
          unawaited(
            _procesarPayload(
              payload: payload,
              topic: evento.topic,
            ),
          );
        }
      },
      onError: (error) {
        _agregarError(
          'Error escuchando mensajes MQTT: $error',
        );
      },
    );
  }

  Future<void> _procesarPayload({
    required String payload,
    required String topic,
  }) async {
    try {
      final data = jsonDecode(payload);

      // Permite publicar UNA lectura:
      // { ... }
      if (data is Map) {
        await _procesarLectura(
          Map<String, dynamic>.from(data),
          topic,
        );
        return;
      }

      // También permite pegar un arreglo completo en MQTT Explorer:
      // [ { ... }, { ... }, { ... } ]
      if (data is List) {
        for (final item in data) {
          if (item is! Map) {
            _agregarError(
              'Uno de los elementos del arreglo MQTT no es un objeto JSON válido.',
            );
            continue;
          }

          await _procesarLectura(
            Map<String, dynamic>.from(item),
            topic,
          );
        }
        return;
      }

      _agregarError(
        'El mensaje MQTT debe ser un objeto JSON o una lista de objetos JSON.',
      );
    } catch (error) {
      _agregarError(
        'Error procesando mensaje MQTT: $error. Payload recibido: $payload',
      );
    }
  }

  Future<void> _procesarLectura(
    Map<String, dynamic> json,
    String topic,
  ) async {
    final loteIdJson = json['loteId']?.toString().trim();
    final loteIdTopic = _extraerLoteIdDelTopic(topic);

    final loteIdSolicitado = (loteIdJson != null && loteIdJson.isNotEmpty)
        ? loteIdJson
        : loteIdTopic;

    if (loteIdSolicitado == null || loteIdSolicitado.isEmpty) {
      throw Exception(
        'La lectura MQTT no contiene loteId y tampoco pudo obtenerse del topic.',
      );
    }

    final usuarioId = _texto(
      json['usuarioId'],
      porDefecto: 'jdh2010',
    );

    final fincaId = _texto(
      json['fincaId'],
      porDefecto: 'finca_esperanza',
    );

    final lectura = DatosSensorSueloModel.fromJson(json);

    final loteResuelto = await _resolverLote(
      usuarioId: usuarioId,
      fincaId: fincaId,
      loteIdSolicitado: loteIdSolicitado,
      nombreLoteJson: json['nombreLote']?.toString(),
    );

    await _guardarLecturaEnFirestore(
      json: json,
      lectura: lectura,
      usuarioId: usuarioId,
      fincaId: fincaId,
      loteIdReal: loteResuelto.id,
      nombreLote: loteResuelto.nombre,
      cultivo: loteResuelto.cultivo,
      etapa: loteResuelto.etapa,
    );

    if (!_controller.isClosed) {
      _controller.add(lectura);
    }
  }

  Future<_LoteMqttResuelto> _resolverLote({
    required String usuarioId,
    required String fincaId,
    required String loteIdSolicitado,
    String? nombreLoteJson,
  }) async {
    final lotesRef = _firestore
        .collection('usuarios')
        .doc(usuarioId)
        .collection('fincas')
        .doc(fincaId)
        .collection('lotes');

    // 1. Primero intenta el ID exacto.
    final exacto = await lotesRef.doc(loteIdSolicitado).get();

    if (exacto.exists) {
      final data = exacto.data() ?? <String, dynamic>{};

      return _LoteMqttResuelto(
        id: exacto.id,
        nombre: _texto(
          data['nombre'],
          porDefecto: _nombreVisibleDesdeId(exacto.id),
        ),
        cultivo: _texto(
          data['cultivo'],
          porDefecto: 'Fresa',
        ),
        etapa: _texto(
          data['etapa'],
          porDefecto: 'Fructificación',
        ),
      );
    }

    final candidatosNombre = <String>{
      if (nombreLoteJson != null && nombreLoteJson.trim().isNotEmpty)
        nombreLoteJson.trim(),
      _nombreVisibleDesdeId(loteIdSolicitado),
      _nombreVisibleDesdeId(loteIdSolicitado).toLowerCase(),
    };

    for (final nombre in candidatosNombre) {
      final consulta = await lotesRef
          .where('nombre', isEqualTo: nombre)
          .limit(1)
          .get();

      if (consulta.docs.isNotEmpty) {
        final doc = consulta.docs.first;
        final data = doc.data();

        return _LoteMqttResuelto(
          id: doc.id,
          nombre: _texto(
            data['nombre'],
            porDefecto: nombre,
          ),
          cultivo: _texto(
            data['cultivo'],
            porDefecto: 'Fresa',
          ),
          etapa: _texto(
            data['etapa'],
            porDefecto: 'Fructificación',
          ),
        );
      }
    }

    // No se crea automáticamente un lote nuevo.
    // Así evitamos documentos duplicados como "lote_2".
    throw Exception(
      'No existe un lote en Firestore que corresponda a "$loteIdSolicitado".',
    );
  }

  Future<void> _guardarLecturaEnFirestore({
    required Map<String, dynamic> json,
    required DatosSensorSueloModel lectura,
    required String usuarioId,
    required String fincaId,
    required String loteIdReal,
    required String nombreLote,
    required String cultivo,
    required String etapa,
  }) async {
    final fecha = lectura.fechaLectura;

    final sensorId = _texto(
      json['sensorId'],
      porDefecto: 'sensor_mqtt_01',
    );

    final origen = _texto(
      json['origen'],
      porDefecto: 'mqtt',
    );

    final esSimulada = json['esSimulada'] == true;

    // ID determinístico: si vuelves a publicar la misma lectura,
    // se actualiza el mismo documento y no se duplica.
    final fechaId = fecha
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-');

    final sensorIdSeguro = sensorId.replaceAll('/', '_');

    final docId = '${sensorIdSeguro}_$fechaId';

    final datosLectura = <String, dynamic>{
      'usuarioId': usuarioId,
      'fincaId': fincaId,
      'loteId': loteIdReal,
      'nombreLote': nombreLote,
      'sensorId': sensorId,
      'cultivo': cultivo,
      'etapa': etapa,
      'tipo': 'lectura_mqtt',
      'origen': origen,
      'fuente': 'mqtt',
      'esSimulada': esSimulada,
      'humedadSuelo': lectura.humedadSuelo,
      'temperaturaSuelo': lectura.temperaturaSuelo,
      'conductividadElectrica': lectura.conductividadElectrica,
      'phSuelo': lectura.phSuelo,
      'nitrogeno': lectura.nitrogeno,
      'fosforo': lectura.fosforo,
      'potasio': lectura.potasio,
      'fechaLectura': Timestamp.fromDate(fecha),
      'creadoEn': FieldValue.serverTimestamp(),
    };

    // Conserva numeroPrueba si viene en los datos simulados.
    if (json.containsKey('numeroPrueba')) {
      datosLectura['numeroPrueba'] = json['numeroPrueba'];
    }

    final lecturaRef = _firestore
        .collection('usuarios')
        .doc(usuarioId)
        .collection('fincas')
        .doc(fincaId)
        .collection('lotes')
        .doc(loteIdReal)
        .collection('lecturas')
        .doc(docId);

    await lecturaRef.set(
      datosLectura,
      SetOptions(merge: true),
    );
  }

  String? _extraerLoteIdDelTopic(String topic) {
    final partes = topic.split('/');

    // fresa_app / usuario / finca / lote / suelo
    if (partes.length >= 5) {
      final posibleLote = partes[3].trim();

      if (posibleLote.isNotEmpty && posibleLote != '+') {
        return posibleLote;
      }
    }

    return null;
  }

  String _nombreVisibleDesdeId(String loteId) {
    final match = RegExp(r'^lote_(\d+)').firstMatch(
      loteId.trim().toLowerCase(),
    );

    if (match != null) {
      return 'Lote ${match.group(1)}';
    }

    return loteId.replaceAll('_', ' ');
  }

  String _texto(
    dynamic value, {
    required String porDefecto,
  }) {
    final texto = value?.toString().trim() ?? '';
    return texto.isEmpty ? porDefecto : texto;
  }

  void _agregarError(String mensaje) {
    if (!_controller.isClosed) {
      _controller.addError(mensaje);
    }
  }

  void _onConnected() {
    _conectado = true;
    _conectando = false;
  }

  void _onSubscribed(String topic) {
    // Suscripción correcta.
  }

  void _onDisconnected() {
    _conectado = false;
    _conectando = false;
  }

  Future<void> desconectar() async {
    await _subscription?.cancel();
    _subscription = null;

    _client?.disconnect();

    _conectado = false;
    _conectando = false;
    _escuchando = false;

    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}

class _LoteMqttResuelto {
  const _LoteMqttResuelto({
    required this.id,
    required this.nombre,
    required this.cultivo,
    required this.etapa,
  });

  final String id;
  final String nombre;
  final String cultivo;
  final String etapa;
}
