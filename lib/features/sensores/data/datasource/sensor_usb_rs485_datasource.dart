import 'dart:async';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

import '../../domain/entities/datos_sensor_suelo.dart';
import '../../domain/services/calibracion_sensor_suelo_service.dart';

class SensorUsbRs485Datasource {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _subscription;

  static const int _slaveId = 0x01;
  static const int _baudRate = 4800;
  static const int _respuestaLectura7RegistrosBytes = 19;

  // Estabilización: una pulsación en "Leer datos" toma varias lecturas internas
  // sin cambiar la interfaz de la app.
  static const int _lecturasMinimasEstables = 3;
  static const int _intentosMaximosEstabilizacion = 7;
  static const Duration _esperaInicial = Duration(milliseconds: 1200);
  static const Duration _esperaEntreLecturas = Duration(milliseconds: 900);

  // Umbrales prácticos para decidir si las últimas 3 lecturas ya están estables.
  // NPK no se usa para decidir estabilidad porque suele fluctuar más; se promedia.
  static const double _umbralHumedad = 2.0; // %
  static const double _umbralTemperatura = 0.6; // °C
  static const double _umbralPh = 0.30;
  static const double _umbralEc = 0.12; // dS/m

  final CalibracionSensorSueloService _calibracion =
      const CalibracionSensorSueloService();

  Future<DatosSensorSuelo> leerSensor() async {
    UsbPort? port;

    try {
      final devices = await UsbSerial.listDevices();

      if (devices.isEmpty) {
        throw Exception(
          'No se encontró adaptador USB-RS485. Conecta el adaptador con OTG.',
        );
      }

      final device = devices.first;
      port = await device.create();

      if (port == null) {
        throw Exception('No se pudo crear el puerto USB.');
      }

      _port = port;

      final opened = await port.open();

      if (!opened) {
        throw Exception(
          'No se pudo abrir el puerto USB. Revisa el permiso OTG del celular.',
        );
      }

      await port.setPortParameters(
        _baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      await port.setDTR(true);
      await port.setRTS(true);

      // Da un pequeño tiempo al adaptador/puerto antes de iniciar la serie.
      await Future<void>.delayed(_esperaInicial);

      final lecturasValidas = <DatosSensorSuelo>[];
      Object? ultimoError;

      for (var intento = 0;
          intento < _intentosMaximosEstabilizacion;
          intento++) {
        try {
          final respuesta = await _enviarYLeer(
            port,
            _crearTramaLectura7Registros(),
          );

          final lectura = _parsearRespuestaSensor(respuesta);
          lecturasValidas.add(lectura);

          if (lecturasValidas.length >= _lecturasMinimasEstables) {
            final ultimas = lecturasValidas
                .sublist(lecturasValidas.length - _lecturasMinimasEstables);

            if (_estanEstables(ultimas)) {
              return _promediarLecturas(ultimas);
            }
          }
        } catch (e) {
          // Un fallo aislado (ruido, CRC, timeout) no aborta toda la lectura.
          ultimoError = e;
        }

        if (intento < _intentosMaximosEstabilizacion - 1) {
          await Future<void>.delayed(_esperaEntreLecturas);
        }
      }


      if (lecturasValidas.length >= _lecturasMinimasEstables) {
        final ultimas = lecturasValidas
            .sublist(lecturasValidas.length - _lecturasMinimasEstables);

        return _promediarLecturas(ultimas);
      }

      if (lecturasValidas.isNotEmpty) {
        throw Exception(
          'Se recibieron datos, pero no se lograron '
          '$_lecturasMinimasEstables lecturas válidas consecutivas. '
          'Mantén el sensor quieto y vuelve a intentar.',
        );
      }

      if (ultimoError != null) {
        throw Exception(
          ultimoError.toString().replaceFirst('Exception: ', ''),
        );
      }

      throw Exception(
        'No se pudo obtener una lectura válida del sensor.',
      );
    } finally {
      await cerrar();
    }
  }

  /// Lectura de respaldo: realiza una única consulta Modbus y devuelve
  /// inmediatamente el resultado validado y calibrado.
  ///
  /// No guarda la lectura en historial ni participa en el promedio del lote.
  Future<DatosSensorSuelo> leerSensorInmediato() async {
    UsbPort? port;

    try {
      final devices = await UsbSerial.listDevices();

      if (devices.isEmpty) {
        throw Exception(
          'No se encontró adaptador USB-RS485. Conecta el adaptador con OTG.',
        );
      }

      final device = devices.first;
      port = await device.create();

      if (port == null) {
        throw Exception('No se pudo crear el puerto USB.');
      }

      _port = port;

      final opened = await port.open();

      if (!opened) {
        throw Exception(
          'No se pudo abrir el puerto USB. Revisa el permiso OTG del celular.',
        );
      }

      await port.setPortParameters(
        _baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      await port.setDTR(true);
      await port.setRTS(true);

      // Solo una espera corta para que el puerto quede listo.
      await Future<void>.delayed(const Duration(milliseconds: 350));

      final respuesta = await _enviarYLeer(
        port,
        _crearTramaLectura7Registros(),
      );

      // Usa el mismo parseo, CRC y calibración de pH de la lectura normal.
      return _parsearRespuestaSensor(respuesta);
    } finally {
      await cerrar();
    }
  }

  bool _estanEstables(List<DatosSensorSuelo> lecturas) {
    if (lecturas.length < _lecturasMinimasEstables) return false;

    double rango(Iterable<double> valores) {
      final lista = valores.toList(growable: false);
      final minimo = lista.reduce((a, b) => a < b ? a : b);
      final maximo = lista.reduce((a, b) => a > b ? a : b);
      return maximo - minimo;
    }

    final humedadOk =
        rango(lecturas.map((e) => e.humedadSuelo)) <= _umbralHumedad;
    final temperaturaOk =
        rango(lecturas.map((e) => e.temperaturaSuelo)) <= _umbralTemperatura;
    final phOk =
        rango(lecturas.map((e) => e.phSuelo)) <= _umbralPh;
    final ecOk =
        rango(lecturas.map((e) => e.conductividadElectrica)) <= _umbralEc;

    return humedadOk && temperaturaOk && phOk && ecOk;
  }

  DatosSensorSuelo _promediarLecturas(List<DatosSensorSuelo> lecturas) {
    final total = lecturas.length.toDouble();

    double promedio(Iterable<double> valores) {
      return valores.fold<double>(0, (suma, valor) => suma + valor) / total;
    }

    return DatosSensorSuelo(
      humedadSuelo: promedio(lecturas.map((e) => e.humedadSuelo)),
      temperaturaSuelo: promedio(lecturas.map((e) => e.temperaturaSuelo)),
      conductividadElectrica:
          promedio(lecturas.map((e) => e.conductividadElectrica)),
      phSuelo: promedio(lecturas.map((e) => e.phSuelo)),
      nitrogeno: promedio(lecturas.map((e) => e.nitrogeno)),
      fosforo: promedio(lecturas.map((e) => e.fosforo)),
      potasio: promedio(lecturas.map((e) => e.potasio)),
      fechaLectura: DateTime.now(),
    );
  }

  Future<Uint8List> _enviarYLeer(
    UsbPort port,
    Uint8List trama,
  ) async {
    await _subscription?.cancel();
    _subscription = null;

    final completer = Completer<Uint8List>();
    final buffer = <int>[];

    _subscription = port.inputStream?.listen(
      (data) {
        buffer.addAll(data);

        if (buffer.length >= _respuestaLectura7RegistrosBytes &&
            !completer.isCompleted) {
          completer.complete(
            Uint8List.fromList(
              buffer.take(_respuestaLectura7RegistrosBytes).toList(),
            ),
          );
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      cancelOnError: true,
    );

    try {
      await port.write(trama);

      return await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          throw Exception(
            'El sensor no respondió por RS485. '
            'Revisa alimentación, GND común y cables A/B.',
          );
        },
      );
    } finally {
      await _subscription?.cancel();
      _subscription = null;
    }
  }

  Uint8List _crearTramaLectura7Registros() {
    final tramaSinCrc = <int>[
      _slaveId, // Dirección del sensor.
      0x03, // Función: Read Holding Registers.
      0x00,
      0x00, // Registro inicial: 0x0000.
      0x00,
      0x07, // Cantidad: 7 registros.
    ];

    final crc = _crc16Modbus(tramaSinCrc);

    return Uint8List.fromList([
      ...tramaSinCrc,
      crc & 0xFF, // CRC Lo.
      (crc >> 8) & 0xFF, // CRC Hi.
    ]);
  }

  DatosSensorSuelo _parsearRespuestaSensor(Uint8List data) {
    if (data.length < _respuestaLectura7RegistrosBytes) {
      throw Exception('Respuesta incompleta del sensor.');
    }

    if (data[0] != _slaveId) {
      throw Exception(
        'La respuesta no viene del sensor ID 1. Revisa el ID Modbus del sensor.',
      );
    }

    if (data[1] != 0x03) {
      throw Exception('Función Modbus incorrecta en la respuesta.');
    }

    if (data[2] != 0x0E) {
      throw Exception(
        'Cantidad de bytes incorrecta. Se esperaban 14 bytes de datos.',
      );
    }

    final crcRecibido = data[data.length - 2] | (data[data.length - 1] << 8);
    final crcCalculado = _crc16Modbus(data.sublist(0, data.length - 2));

    if (crcRecibido != crcCalculado) {
      throw Exception(
        'CRC inválido. Puede haber ruido eléctrico o cables A/B invertidos.',
      );
    }

    final humedadRaw = _registroUint16(data, 0);
    final temperaturaRaw = _registroInt16(data, 1);
    final ecRaw = _registroUint16(data, 2);
    final phRaw = _registroUint16(data, 3);
    final nRaw = _registroUint16(data, 4);
    final pRaw = _registroUint16(data, 5);
    final kRaw = _registroUint16(data, 6);

    final humedad = humedadRaw / 10.0;
    final temperatura = temperaturaRaw / 10.0;
    final ec = ecRaw / 1000.0;
    final phSensor = phRaw / 10.0;
    final phCorregido = _calibracion.calibrarPh(phSensor);

    return DatosSensorSuelo(
      humedadSuelo: humedad,
      temperaturaSuelo: temperatura,
      conductividadElectrica: ec,
      phSuelo: phCorregido,
      nitrogeno: nRaw.toDouble(),
      fosforo: pRaw.toDouble(),
      potasio: kRaw.toDouble(),
      fechaLectura: DateTime.now(),
    );
  }

  int _registroUint16(Uint8List data, int index) {
    final pos = 3 + index * 2;
    return (data[pos] << 8) | data[pos + 1];
  }

  int _registroInt16(Uint8List data, int index) {
    final value = _registroUint16(data, index);

    if ((value & 0x8000) != 0) {
      return value - 0x10000;
    }

    return value;
  }

  int _crc16Modbus(List<int> bytes) {
    var crc = 0xFFFF;

    for (final byte in bytes) {
      crc ^= byte;

      for (var i = 0; i < 8; i++) {
        final lsb = crc & 0x0001;
        crc >>= 1;

        if (lsb != 0) {
          crc ^= 0xA001;
        }
      }
    }

    return crc & 0xFFFF;
  }

  Future<void> cerrar() async {
    await _subscription?.cancel();
    _subscription = null;

    await _port?.close();
    _port = null;
  }
}
