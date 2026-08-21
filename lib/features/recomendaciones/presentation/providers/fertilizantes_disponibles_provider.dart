import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/producto_fertilizante.dart';

enum ModoCalculoFertilizante {
  personalizado,
  sugerido,
}

extension ModoCalculoFertilizanteTexto on ModoCalculoFertilizante {
  String get titulo {
    switch (this) {
      case ModoCalculoFertilizante.personalizado:
        return 'Personalizado';
      case ModoCalculoFertilizante.sugerido:
        return 'Sugerido';
    }
  }
}

final modoCalculoFertilizanteProvider =
    StateProvider<ModoCalculoFertilizante>((ref) {
  return ModoCalculoFertilizante.personalizado;
});

final productosFertilizantesProvider = StateNotifierProvider<
    ProductosFertilizantesNotifier, List<ProductoFertilizante>>((ref) {
  return ProductosFertilizantesNotifier(
    firestore: FirebaseFirestore.instance,
  );
});

final productosFertilizantesSeleccionadosProvider =
    Provider<List<ProductoFertilizante>>((ref) {
  return ref
      .watch(productosFertilizantesProvider)
      .where((producto) => producto.seleccionado)
      .toList(growable: false);
});

class ProductosFertilizantesNotifier
    extends StateNotifier<List<ProductoFertilizante>> {
  ProductosFertilizantesNotifier({
    required FirebaseFirestore firestore,
  })  : _firestore = firestore,
        super(const <ProductoFertilizante>[]) {
    _cargarComposicionesGuardadas();
  }

  final FirebaseFirestore _firestore;

  static const String _usuarioId = 'jdh2010';
  static const String _fincaId = 'finca_esperanza';

  // Se conserva el mismo nombre para no romper reglas ni datos anteriores.
  // Ahora contiene concentraciones creadas por el usuario, no productos base.
  static const String _nombreCaja = 'fertilizantes_manuales';
  static const String _nombreCajaPlanes = 'planes_nutricionales_guardados';

  late final Future<Box<dynamic>> _cajaFuture =
      Hive.openBox<dynamic>(_nombreCaja);

  late final Future<Box<dynamic>> _cajaPlanesFuture =
      Hive.openBox<dynamic>(_nombreCajaPlanes);

  CollectionReference<Map<String, dynamic>> get _coleccionRemota {
    return _firestore
        .collection('usuarios')
        .doc(_usuarioId)
        .collection('fincas')
        .doc(_fincaId)
        .collection('fertilizantes_manuales');
  }

  Future<void> _cargarComposicionesGuardadas() async {
    await _cargarDesdeHive();
    await _sincronizarDesdeFirestore();
  }

  Future<void> _cargarDesdeHive() async {
    try {
      final caja = await _cajaFuture;

      final guardadas = caja.values
          .whereType<Map>()
          .map(
            (valor) => ProductoFertilizante.fromMap(
              Map<String, dynamic>.from(valor),
            ),
          )
          .where((producto) => producto.esManual && _tieneConcentracion(producto))
          .map((producto) => _normalizarConcentracion(producto)
              .copyWith(seleccionado: false))
          .toList();

      state = _unicosPorId(guardadas);

      debugPrint(
        'Concentraciones cargadas desde Hive: ${guardadas.length}',
      );
    } catch (error, stackTrace) {
      debugPrint('Error cargando concentraciones desde Hive: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _sincronizarDesdeFirestore() async {
    try {
      final snapshot = await _coleccionRemota.get();

      final remotas = snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = (data['id'] ?? doc.id).toString();
            return ProductoFertilizante.fromMap(data);
          })
          .where((producto) => producto.esManual && _tieneConcentracion(producto))
          .map((producto) => _normalizarConcentracion(producto)
              .copyWith(seleccionado: false))
          .toList();

      if (remotas.isEmpty) return;

      final caja = await _cajaFuture;

      for (final producto in remotas) {
        await caja.put(producto.id, producto.toMap());
      }

      final actuales = state.where((producto) => producto.esManual).toList();
      final temporales = state.where((producto) => producto.esTemporal).toList();

      state = <ProductoFertilizante>[
        ..._unicosPorId(<ProductoFertilizante>[
          ...actuales,
          ...remotas,
        ]),
        ...temporales,
      ];

      debugPrint(
        'Concentraciones sincronizadas desde Firestore: ${remotas.length}',
      );
    } catch (error, stackTrace) {
      debugPrint('Error sincronizando concentraciones desde Firestore: $error');
      debugPrint('$stackTrace');
    }
  }

  void alternarSeleccion(String id) {
    state = state.map((producto) {
      if (producto.id != id) return producto;
      return producto.copyWith(seleccionado: !producto.seleccionado);
    }).toList();
  }

  void seleccionarTodos() {
    state = state
        .map((producto) => producto.copyWith(seleccionado: true))
        .toList();
  }

  void limpiarSeleccion() {
    state = state
        .map((producto) => producto.copyWith(seleccionado: false))
        .toList();
  }


  ProductoFertilizante usarComposicionTemporal({
    required double n,
    required double p2o5,
    required double k2o,
  }) {
    final composicion = _crearProductoDesdeConcentracion(
      id: 'temporal_${DateTime.now().microsecondsSinceEpoch}',
      n: n,
      p2o5: p2o5,
      k2o: k2o,
      seleccionado: true,
    );

    state = <ProductoFertilizante>[
      ...state,
      composicion,
    ];

    debugPrint('🧮 Concentración temporal usada: ${composicion.nombre}');

    return composicion;
  }

  Future<bool> guardarComposicionNpk({
    required double n,
    required double p2o5,
    required double k2o,
  }) async {
    if (!_validaConcentracion(n: n, p2o5: p2o5, k2o: k2o)) {
      return false;
    }

    final producto = _crearProductoDesdeConcentracion(
      id: 'manual_composicion_${DateTime.now().microsecondsSinceEpoch}',
      n: n,
      p2o5: p2o5,
      k2o: k2o,
      seleccionado: true,
    );

    state = <ProductoFertilizante>[
      ...state.where((item) => item.id != producto.id),
      producto,
    ];

    return _guardarManual(producto);
  }



  Future<bool> guardarTemporalesSeleccionados() async {
    final temporales = state
        .where((producto) => producto.esTemporal && producto.seleccionado)
        .toList(growable: false);

    if (temporales.isEmpty) return true;

    final nuevos = <ProductoFertilizante>[];
    var todoOk = true;

    for (final temporal in temporales) {
      final guardado = _crearProductoDesdeConcentracion(
        id: 'manual_composicion_${DateTime.now().microsecondsSinceEpoch}_${nuevos.length}',
        n: temporal.n,
        p2o5: temporal.p2o5,
        k2o: temporal.k2o,
        seleccionado: true,
      );

      nuevos.add(guardado);

      final ok = await _guardarManual(guardado);
      if (!ok) todoOk = false;
    }

    final idsTemporales = temporales.map((item) => item.id).toSet();

    state = <ProductoFertilizante>[
      ...state.where((item) => !idsTemporales.contains(item.id)),
      ...nuevos,
    ];

    return todoOk;
  }


  Future<bool> guardarResultadoPlan({
    required String loteId,
    required String loteNombre,
    required Map<String, dynamic> datos,
  }) async {
    final ahora = DateTime.now();
    final planId = 'plan_${ahora.microsecondsSinceEpoch}';

    final registroLocal = <String, dynamic>{
      ...datos,
      'id': planId,
      'usuarioId': _usuarioId,
      'fincaId': _fincaId,
      'loteId': loteId,
      'loteNombre': loteNombre,
      'fechaGuardadoIso': ahora.toIso8601String(),
    };

    var guardadoHive = false;
    var guardadoFirestore = false;

    try {
      final caja = await _cajaPlanesFuture;
      await caja.put(planId, registroLocal);
      guardadoHive = true;
      debugPrint('Plan nutricional guardado en Hive: $planId');
    } catch (error, stackTrace) {
      debugPrint('Error guardando plan nutricional en Hive: $error');
      debugPrint('$stackTrace');
    }

    try {
      await _firestore
          .collection('usuarios')
          .doc(_usuarioId)
          .collection('fincas')
          .doc(_fincaId)
          .collection('lotes')
          .doc(loteId)
          .collection('planes_nutricionales')
          .doc(planId)
          .set(
        {
          ...registroLocal,
          'fechaGuardado': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      guardadoFirestore = true;
      debugPrint('Plan nutricional guardado en Firestore: $planId');
    } catch (error, stackTrace) {
      debugPrint('Error guardando plan nutricional en Firestore: $error');
      debugPrint('$stackTrace');
    }

    // El plan puede quedar respaldado localmente en Hive, pero solo se
    // considera sincronizado cuando Firestore confirma el guardado.
    if (!guardadoFirestore && guardadoHive) {
      debugPrint(
        'Plan guardado solo en Hive; Firestore quedó pendiente.',
      );
    }

    return guardadoFirestore;
  }

  Future<bool> editarComposicionNpk({
    required String id,
    required double n,
    required double p2o5,
    required double k2o,
  }) async {
    if (!_validaConcentracion(n: n, p2o5: p2o5, k2o: k2o)) {
      return false;
    }

    final indice = state.indexWhere((producto) => producto.id == id);
    if (indice < 0) return false;

    final anterior = state[indice];
    final actualizado = _crearProductoDesdeConcentracion(
      id: anterior.id,
      n: n,
      p2o5: p2o5,
      k2o: k2o,
      seleccionado: anterior.seleccionado,
    );

    final copia = [...state];
    copia[indice] = actualizado;
    state = copia;

    if (actualizado.esTemporal) return true;

    return _guardarManual(actualizado);
  }

  Future<bool> agregarFertilizanteManual({
    required String nombre,
    required bool esAbonoSimple,
    required String formula,
    required double n,
    required double p2o5,
    required double k2o,
    required double mgO,
    required double ca,
    required double b,
    required double precio,
  }) {
    // Compatibilidad con llamadas antiguas.
    return guardarComposicionNpk(n: n, p2o5: p2o5, k2o: k2o);
  }

  Future<bool> editarFertilizanteManual({
    required String id,
    required String nombre,
    required bool esAbonoSimple,
    required String formula,
    required double n,
    required double p2o5,
    required double k2o,
    required double mgO,
    required double ca,
    required double b,
    required double precio,
  }) {
    // Compatibilidad con llamadas antiguas.
    return editarComposicionNpk(id: id, n: n, p2o5: p2o5, k2o: k2o);
  }

  Future<void> eliminarFertilizanteManual(String id) async {
    final productos = state.where((item) => item.id == id).toList();
    if (productos.isEmpty) return;

    final producto = productos.first;
    state = state.where((item) => item.id != id).toList();

    if (!producto.esTemporal) {
      await _eliminarManual(id);
    }
  }

  /// Ahora no restablece productos base; solo elimina concentraciones guardadas.
  Future<void> restablecerListaBase() async {
    state = state.where((producto) => producto.esTemporal).toList();

    try {
      final caja = await _cajaFuture;
      await caja.clear();
      debugPrint('Concentraciones guardadas eliminadas de Hive.');
    } catch (error, stackTrace) {
      debugPrint('Error limpiando concentraciones desde Hive: $error');
      debugPrint('$stackTrace');
    }

    try {
      final snapshot = await _coleccionRemota.get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('Concentraciones guardadas eliminadas de Firestore.');
    } catch (error, stackTrace) {
      debugPrint('Error limpiando concentraciones desde Firestore: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<bool> _guardarManual(ProductoFertilizante producto) async {
    final productoParaGuardar = _normalizarConcentracion(
      producto.copyWith(seleccionado: false),
    );

    var guardadoEnHive = false;
    var guardadoEnFirestore = false;

    try {
      final caja = await _cajaFuture;
      await caja.put(productoParaGuardar.id, productoParaGuardar.toMap());
      guardadoEnHive = true;

      debugPrint(
        'Concentración guardada en Hive: ${productoParaGuardar.nombre}',
      );
    } catch (error, stackTrace) {
      debugPrint('Error guardando concentración en Hive: $error');
      debugPrint('$stackTrace');
    }

    try {
      await _coleccionRemota.doc(productoParaGuardar.id).set({
        ...productoParaGuardar.toMap(),
        'usuarioId': _usuarioId,
        'fincaId': _fincaId,
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      guardadoEnFirestore = true;

      debugPrint(
        'Concentración guardada en Firestore: ${productoParaGuardar.nombre}',
      );
    } catch (error, stackTrace) {
      debugPrint('Error guardando concentración en Firestore: $error');
      debugPrint('$stackTrace');
    }


    if (!guardadoEnFirestore && guardadoEnHive) {
      debugPrint(
        'Concentración guardada solo en Hive; Firestore quedó pendiente.',
      );
    }

    return guardadoEnFirestore;
  }

  Future<void> _eliminarManual(String id) async {
    try {
      final caja = await _cajaFuture;
      await caja.delete(id);
      debugPrint('Concentración eliminada de Hive: $id');
    } catch (error, stackTrace) {
      debugPrint('Error eliminando concentración de Hive: $error');
      debugPrint('$stackTrace');
    }

    try {
      await _coleccionRemota.doc(id).delete();
      debugPrint('Concentración eliminada de Firestore: $id');
    } catch (error, stackTrace) {
      debugPrint('Error eliminando concentración de Firestore: $error');
      debugPrint('$stackTrace');
    }
  }

  static ProductoFertilizante _crearProductoDesdeConcentracion({
    required String id,
    required double n,
    required double p2o5,
    required double k2o,
    required bool seleccionado,
  }) {
    final concentracion = '${_numero(n)}-${_numero(p2o5)}-${_numero(k2o)}';

    return ProductoFertilizante(
      id: id,
      nombre: concentracion,
      concentracionTexto: concentracion,
      precio: 0,
      n: n,
      p2o5: p2o5,
      k2o: k2o,
      seleccionado: seleccionado,
    );
  }

  static ProductoFertilizante _normalizarConcentracion(
    ProductoFertilizante producto,
  ) {
    final concentracion =
        '${_numero(producto.n)}-${_numero(producto.p2o5)}-${_numero(producto.k2o)}';

    return producto.copyWith(
      nombre: concentracion,
      concentracionTexto: concentracion,
      mgO: 0,
      ca: 0,
      b: 0,
      precio: 0,
    );
  }

  static bool _tieneConcentracion(ProductoFertilizante producto) {
    return producto.n > 0 || producto.p2o5 > 0 || producto.k2o > 0;
  }

  static bool _validaConcentracion({
    required double n,
    required double p2o5,
    required double k2o,
  }) {
    if (n < 0 || p2o5 < 0 || k2o < 0) return false;
    if (n > 100 || p2o5 > 100 || k2o > 100) return false;
    return n > 0 || p2o5 > 0 || k2o > 0;
  }

  static List<ProductoFertilizante> _unicosPorId(
    List<ProductoFertilizante> productos,
  ) {
    final mapa = <String, ProductoFertilizante>{};

    for (final producto in productos) {
      mapa[producto.id] = producto;
    }

    return mapa.values.toList();
  }
}

String _numero(double valor) {
  if (valor == valor.roundToDouble()) return valor.toStringAsFixed(0);
  return valor.toStringAsFixed(1);
}
