import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/constantes/cajas_hive.dart';
import '../../domain/entities/lote_cultivo.dart';

final loteSeleccionadoIdProvider = StateProvider<String>((ref) {
  return 'lote_1';
});

final lotesCultivoProvider = StreamProvider<List<LoteCultivo>>((ref) async* {
  final controller = ref.read(lotesCultivoControllerProvider);

  //Carga inmediata desde Hive. Esto permite trabajar sin internet.
  yield await controller.obtenerLotesLocales();

  //Intenta sincronizar pendientes en segundo plano, sin bloquear la UI.
  unawaited(controller.sincronizarPendientes());

  //Escucha Firestore cuando exista internet. Si falla, conserva Hive.
  try {
    await for (final lotes in controller.escucharLotesRemotos()) {
      yield lotes;
    }
  } catch (error, stackTrace) {
    debugPrint('⚠️ No se pudo escuchar Firestore. Se conserva Hive: $error');
    debugPrint('$stackTrace');
    yield await controller.obtenerLotesLocales();
  }
});

final loteSeleccionadoProvider = Provider<LoteCultivo>((ref) {
  final loteId = ref.watch(loteSeleccionadoIdProvider);
  final lotesAsync = ref.watch(lotesCultivoProvider);

  final lotes =
      lotesAsync.valueOrNull ?? <LoteCultivo>[LoteCultivo.loteInicial()];

  return lotes.firstWhere(
    (lote) => lote.id == loteId,
    orElse: () => lotes.first,
  );
});

final lotesCultivoControllerProvider = Provider<LotesCultivoController>((ref) {
  return LotesCultivoController(
    firestore: FirebaseFirestore.instance,
  );
});

class LotesCultivoController {
  LotesCultivoController({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const String usuarioId = 'jdh2010';
  static const String fincaId = 'finca_esperanza';

  late final Future<Box<dynamic>> _cajaLotesFuture =
      Hive.openBox<dynamic>(CajasHive.lotesCultivo);

  CollectionReference<Map<String, dynamic>> get _lotesRef {
    return _firestore
        .collection('usuarios')
        .doc(usuarioId)
        .collection('fincas')
        .doc(fincaId)
        .collection('lotes');
  }

  DocumentReference<Map<String, dynamic>> get _usuarioRef {
    return _firestore.collection('usuarios').doc(usuarioId);
  }

  DocumentReference<Map<String, dynamic>> get _fincaRef {
    return _usuarioRef.collection('fincas').doc(fincaId);
  }

  Future<List<LoteCultivo>> obtenerLotesLocales() async {
    final caja = await _cajaLotesFuture;

    final lotes = <LoteCultivo>[];

    for (final item in caja.values) {
      if (item is! Map) continue;

      try {
        final lote = LoteCultivo.fromMap(Map<String, dynamic>.from(item));
        if (lote.activo) lotes.add(lote);
      } catch (_) {
        continue;
      }
    }

    if (lotes.isEmpty) {
      final inicial = LoteCultivo.loteInicial();
      await _guardarLoteLocal(inicial, pendienteSync: true);
      lotes.add(inicial);
    }

    lotes.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );

    return lotes;
  }

  Stream<List<LoteCultivo>> escucharLotesRemotos() {
    return _lotesRef.snapshots().asyncMap((snapshot) async {
      final lotes = snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = (data['id'] ?? doc.id).toString();
            data['sincronizado'] = true;
            data['pendienteSync'] = false;
            return LoteCultivo.fromMap(data);
          })
          .where((lote) => lote.activo)
          .toList();

      lotes.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

      for (final lote in lotes) {
        await _guardarLoteLocal(lote, pendienteSync: false);
      }

      if (lotes.isEmpty) {
        return await obtenerLotesLocales();
      }

      return lotes;
    });
  }

  /// Crea el lote localmente y retorna rápido.
  /// La subida a Firestore queda en segundo plano para que el modal no se quede
  /// esperando cuando hay mala señal o no hay internet.
  Future<LoteCultivo> crearLote({
    required String nombre,
    String cultivo = 'Fresa',
    String etapa = 'Fructificación',
    double areaM2 = 0,
    int numeroPlantas = 0,
    String observaciones = '',
  }) async {
    final nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      throw Exception('Escribe el nombre del lote.');
    }

    final idBase = _normalizarIdLote(nombreLimpio);
    final id = await _generarIdDisponibleLocal(idBase);

    final lote = LoteCultivo(
      id: id,
      nombre: nombreLimpio,
      cultivo: cultivo.trim().isEmpty ? 'Fresa' : _cultivoGeneral(cultivo),
      etapa: etapa.trim().isEmpty ? 'Fructificación' : etapa.trim(),
      activo: true,
      areaM2: areaM2,
      numeroPlantas: numeroPlantas,
      observaciones: observaciones.trim(),
      creadoEn: DateTime.now(),
      actualizadoEn: DateTime.now(),
      pendienteSync: true,
      sincronizado: false,
    );

    await _guardarLoteLocal(lote, pendienteSync: true);
    debugPrint('💾 Lote creado en Hive: ${lote.id}');

    unawaited(_subirLoteAFirestore(lote));

    return lote;
  }

  Future<void> actualizarLote({
    required String id,
    required String nombre,
    required String cultivo,
    required String etapa,
    required double areaM2,
    required int numeroPlantas,
    required String observaciones,
  }) async {
    final nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      throw Exception('Escribe el nombre del lote.');
    }

    final caja = await _cajaLotesFuture;
    final anteriorMap = caja.get(id);
    LoteCultivo? anterior;

    if (anteriorMap is Map) {
      anterior = LoteCultivo.fromMap(Map<String, dynamic>.from(anteriorMap));
    }

    final lote = LoteCultivo(
      id: id,
      nombre: nombreLimpio,
      cultivo: cultivo.trim().isEmpty ? 'Fresa' : _cultivoGeneral(cultivo),
      etapa: etapa.trim().isEmpty ? 'Fructificación' : etapa.trim(),
      activo: true,
      areaM2: areaM2,
      numeroPlantas: numeroPlantas,
      observaciones: observaciones.trim(),
      creadoEn: anterior?.creadoEn,
      actualizadoEn: DateTime.now(),
      pendienteSync: true,
      sincronizado: false,
    );

    await _guardarLoteLocal(lote, pendienteSync: true);
    debugPrint('💾 Lote actualizado en Hive: $id');

    unawaited(_subirLoteAFirestore(lote));
  }

  //Se deja como desactivación para conservar lecturas y muestreos históricos.
  Future<void> desactivarLote(String id) async {
    if (id == 'lote_1') {
      throw Exception('El lote principal no se puede eliminar.');
    }

    final caja = await _cajaLotesFuture;
    final anteriorMap = caja.get(id);

    if (anteriorMap is! Map) return;

    final anterior = LoteCultivo.fromMap(Map<String, dynamic>.from(anteriorMap));
    final lote = LoteCultivo(
      id: anterior.id,
      nombre: anterior.nombre,
      cultivo: anterior.cultivo,
      etapa: anterior.etapa,
      activo: false,
      areaM2: anterior.areaM2,
      numeroPlantas: anterior.numeroPlantas,
      observaciones: anterior.observaciones,
      creadoEn: anterior.creadoEn,
      actualizadoEn: DateTime.now(),
      pendienteSync: true,
      sincronizado: false,
    );

    await _guardarLoteLocal(lote, pendienteSync: true);
    debugPrint('💾 Lote desactivado en Hive: $id');

    unawaited(_subirLoteAFirestore(lote));
  }

  Future<void> sincronizarPendientes() async {
    try {
      final caja = await _cajaLotesFuture;

      for (final item in caja.values) {
        if (item is! Map) continue;

        final lote = LoteCultivo.fromMap(Map<String, dynamic>.from(item));
        if (!lote.pendienteSync) continue;

        await _subirLoteAFirestore(lote);
      }
    } catch (error, stackTrace) {
      debugPrint('⚠️ No se pudieron sincronizar lotes pendientes: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _guardarLoteLocal(
    LoteCultivo lote, {
    required bool pendienteSync,
  }) async {
    final caja = await _cajaLotesFuture;

    final map = lote.toMap();
    map['cultivo'] = _cultivoGeneral(map['cultivo']);
    map['pendienteSync'] = pendienteSync;
    map['sincronizado'] = !pendienteSync;

    await caja.put(lote.id, map);
  }

  Future<void> _subirLoteAFirestore(LoteCultivo lote) async {
    try {
      final batch = _firestore.batch();

      batch.set(
        _usuarioRef,
        {
          'id': usuarioId,
          'nombre': 'Usuario prueba',
          'actualizadoEn': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        _fincaRef,
        {
          'id': fincaId,
          'nombre': 'La Esperanza',
          'ubicacion': 'Cauca, Colombia',
          'actualizadoEn': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!lote.activo) {
        // Eliminación real del documento del lote en Firestore.
        // Las lecturas y muestreos locales se conservan en Hive.
        batch.delete(_lotesRef.doc(lote.id));
      } else {
        batch.set(
          _lotesRef.doc(lote.id),
          {
            'id': lote.id,
            'nombre': lote.nombre,
            'cultivo': _cultivoGeneral(lote.cultivo),
            'etapa': lote.etapa,
            'activo': true,
            'areaM2': lote.areaM2,
            'numeroPlantas': lote.numeroPlantas,
            'observaciones': lote.observaciones,
            'creadoEn': lote.creadoEn == null
                ? FieldValue.serverTimestamp()
                : Timestamp.fromDate(lote.creadoEn!),
            'actualizadoEn': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      final actualizado = lote.copyWith(
        pendienteSync: false,
        sincronizado: true,
        actualizadoEn: DateTime.now(),
      );
      await _guardarLoteLocal(actualizado, pendienteSync: false);

      debugPrint(
        lote.activo
            ? 'Lote sincronizado con Firestore: ${lote.id}'
            : 'Lote eliminado de Firestore: ${lote.id}',
      );
    } catch (error, stackTrace) {
      debugPrint('Lote pendiente por sincronizar (${lote.id}): $error');
      debugPrint('$stackTrace');
      await _guardarLoteLocal(
        lote.copyWith(pendienteSync: true, sincronizado: false),
        pendienteSync: true,
      );
    }
  }

  String _cultivoGeneral(dynamic valor) {
    final texto = (valor ?? '').toString().trim();
    if (texto.isEmpty) return 'Fresa';

    // Por ahora el sistema maneja el cultivo general.
    // Las variedades se pueden agregar más adelante en otro selector.
    if (texto.toLowerCase().contains('fresa')) return 'Fresa';

    return texto;
  }

  String _normalizarIdLote(String nombre) {
    final base = nombre
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return base.isEmpty ? 'lote' : base;
  }

  Future<String> _generarIdDisponibleLocal(String idBase) async {
    final caja = await _cajaLotesFuture;

    if (!caja.containsKey(idBase)) {
      return idBase;
    }

    for (var i = 2; i <= 999; i++) {
      final candidato = '${idBase}_$i';

      if (!caja.containsKey(candidato)) {
        return candidato;
      }
    }

    throw Exception('No se pudo generar un identificador disponible para el lote.');
  }
}
