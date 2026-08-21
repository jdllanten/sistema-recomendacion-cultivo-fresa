import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/lectura_historial.dart';

class HistorialRemotoDatasource {
  HistorialRemotoDatasource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _usuarioId = 'jdh2010';
  static const String _fincaId = 'finca_esperanza';
  static const String _loteId = 'lote_1';
  static const String _sensorId = 'sensor_rs485_7en1_01';

  CollectionReference<Map<String, dynamic>> get _lecturasRef {
    return _firestore
        .collection('usuarios')
        .doc(_usuarioId)
        .collection('fincas')
        .doc(_fincaId)
        .collection('lotes')
        .doc(_loteId)
        .collection('lecturas');
  }

  DocumentReference<Map<String, dynamic>> get _usuarioRef {
    return _firestore.collection('usuarios').doc(_usuarioId);
  }

  DocumentReference<Map<String, dynamic>> get _fincaRef {
    return _usuarioRef.collection('fincas').doc(_fincaId);
  }

  DocumentReference<Map<String, dynamic>> get _loteRef {
    return _fincaRef.collection('lotes').doc(_loteId);
  }

  Future<void> guardarLectura(LecturaHistorial lectura) async {
    final docId = _generarIdLectura(lectura.fechaLectura);

    final lecturaRef = _lecturasRef.doc(docId);

    final batch = _firestore.batch();

    batch.set(
      _usuarioRef,
      {
        'id': _usuarioId,
        'nombre': 'Usuario prueba',
        'actualizadoEn': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _fincaRef,
      {
        'id': _fincaId,
        'nombre': 'La Esperanza',
        'ubicacion': 'Cauca, Colombia',
        'actualizadoEn': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _loteRef,
      {
        'id': _loteId,
        'nombre': 'Lote 1',
        'cultivo': 'Fresa Albión',
        'etapa': 'Fructificación',
        'actualizadoEn': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      lecturaRef,
      {
        'id': docId,
        'usuarioId': _usuarioId,
        'fincaId': _fincaId,
        'loteId': _loteId,
        'sensorId': _sensorId,

        'cultivo': 'Fresa Albión',
        'etapa': 'Fructificación',
        'origen': 'flutter_mqtt',
        'fuente': 'mqtt',

        'fechaLectura': Timestamp.fromDate(lectura.fechaLectura),
        'fechaLecturaIso': lectura.fechaLectura.toIso8601String(),
        'fechaLecturaMs': lectura.fechaLectura.millisecondsSinceEpoch,
        'actualizadoEn': FieldValue.serverTimestamp(),

        'humedadSuelo': lectura.humedad,
        'temperaturaSuelo': lectura.temperatura,
        'conductividadElectrica': lectura.ec,
        'phSuelo': lectura.ph,
        'nitrogeno': lectura.nitrogeno,
        'fosforo': lectura.fosforo,
        'potasio': lectura.potasio,

        'esLecturaValida': _esLecturaValida(lectura),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    debugPrint('Lectura subida a Firestore: $docId');
  }

  Future<List<LecturaHistorial>> obtenerLecturasRecientes({
    int limite = 1000,
  }) async {
    debugPrint('Descargando lecturas desde Firestore SIN orderBy');
    debugPrint(
      'Ruta: usuarios/$_usuarioId/fincas/$_fincaId/lotes/$_loteId/lecturas',
    );

    final snapshot = await _lecturasRef.limit(limite).get();

    debugPrint(
      'Documentos encontrados en Firestore: ${snapshot.docs.length}',
    );

    final lecturas = <LecturaHistorial>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();

        final lectura = _mapToLecturaHistorial(data);

        lecturas.add(lectura);

        debugPrint('DOC ID: ${doc.id}');
        debugPrint('Fecha: ${lectura.fechaLectura}');
        debugPrint('Humedad: ${lectura.humedad}');
        debugPrint('Temperatura: ${lectura.temperatura}');
      } catch (e) {
        debugPrint('No se pudo convertir documento ${doc.id}: $e');
      }
    }

    lecturas.sort(
      (a, b) => b.fechaLectura.compareTo(a.fechaLectura),
    );

    debugPrint('Lecturas convertidas correctamente: ${lecturas.length}');

    return lecturas;
  }

  Future<List<LecturaHistorial>> obtenerLecturasDespuesDe(
    DateTime fecha, {
    int limite = 1000,
  }) async {
    debugPrint('Buscando lecturas después de: $fecha');
    debugPrint('Consulta segura SIN where/orderBy remoto');

    final snapshot = await _lecturasRef.limit(limite).get();

    final lecturas = <LecturaHistorial>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();

        final lectura = _mapToLecturaHistorial(data);

        if (lectura.fechaLectura.isAfter(fecha)) {
          lecturas.add(lectura);
        }
      } catch (e) {
        debugPrint('No se pudo convertir documento ${doc.id}: $e');
      }
    }

    lecturas.sort(
      (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
    );

    debugPrint(
      '📥 Lecturas nuevas encontradas en Firestore: ${lecturas.length}',
    );

    return lecturas;
  }

  LecturaHistorial _mapToLecturaHistorial(Map<String, dynamic> data) {
    return LecturaHistorial(
      fechaLectura: _obtenerFechaLectura(data),
      humedad: _toDouble(data['humedadSuelo']),
      temperatura: _toDouble(data['temperaturaSuelo']),
      ec: _toDouble(data['conductividadElectrica']),
      ph: _toDouble(data['phSuelo']),
      nitrogeno: _toDouble(data['nitrogeno']),
      fosforo: _toDouble(data['fosforo']),
      potasio: _toDouble(data['potasio']),
    );
  }

  DateTime _obtenerFechaLectura(Map<String, dynamic> data) {
    final fechaMs = data['fechaLecturaMs'];

    if (fechaMs is int) {
      return DateTime.fromMillisecondsSinceEpoch(fechaMs);
    }

    if (fechaMs is num) {
      return DateTime.fromMillisecondsSinceEpoch(fechaMs.toInt());
    }

    final fechaLectura = data['fechaLectura'];

    if (fechaLectura is Timestamp) {
      return fechaLectura.toDate();
    }

    if (fechaLectura is DateTime) {
      return fechaLectura;
    }

    if (fechaLectura is String) {
      final fechaParseada = DateTime.tryParse(fechaLectura);

      if (fechaParseada != null) {
        return fechaParseada;
      }
    }

    final fechaIso = data['fechaLecturaIso'];

    if (fechaIso is String) {
      final fechaParseada = DateTime.tryParse(fechaIso);

      if (fechaParseada != null) {
        return fechaParseada;
      }
    }

    debugPrint(
      'Documento sin fecha válida. Se usará DateTime.now(). Data: $data',
    );

    return DateTime.now();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  bool _esLecturaValida(LecturaHistorial lectura) {
    if (lectura.humedad <= 0) return false;
    if (lectura.ec <= 0) return false;
    if (lectura.ph <= 0) return false;
    if (lectura.nitrogeno <= 0) return false;
    if (lectura.fosforo <= 0) return false;
    if (lectura.potasio <= 0) return false;

    return true;
  }

  String _generarIdLectura(DateTime fecha) {
    final fechaUtc = fecha.toUtc();

    final year = fechaUtc.year.toString().padLeft(4, '0');
    final month = fechaUtc.month.toString().padLeft(2, '0');
    final day = fechaUtc.day.toString().padLeft(2, '0');

    final hour = fechaUtc.hour.toString().padLeft(2, '0');
    final minute = fechaUtc.minute.toString().padLeft(2, '0');
    final second = fechaUtc.second.toString().padLeft(2, '0');

    return '${_sensorId}_${year}-${month}-${day}_${hour}-${minute}-${second}';
  }
}