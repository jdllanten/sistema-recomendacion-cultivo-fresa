class ProductoFertilizante {
  const ProductoFertilizante({
    required this.id,
    required this.nombre,
    required this.concentracionTexto,
    required this.precio,
    required this.n,
    required this.p2o5,
    required this.k2o,
    this.mgO = 0,
    this.ca = 0,
    this.b = 0,
    this.seleccionado = false,
  });

  final String id;


  final String nombre;

  //Concentración base. Ejemplo: 13-0-46.
  final String concentracionTexto;


  final double precio;

  //Concentraciones en porcentaje.
  final double n;
  final double p2o5;
  final double k2o;
  final double mgO;
  final double ca;
  final double b;

  final bool seleccionado;


  bool get esManual => id.startsWith('manual_');

 
  bool get esTemporal => id.startsWith('temporal_');

  
  bool get esAbonoSimple {
    final activos = <double>[n, p2o5, k2o].where((valor) => valor > 0).length;
    return activos <= 2;
  }


  String get composicionNpk => '${_numero(n)}-${_numero(p2o5)}-${_numero(k2o)}';

  ProductoFertilizante copyWith({
    String? id,
    String? nombre,
    String? concentracionTexto,
    double? precio,
    double? n,
    double? p2o5,
    double? k2o,
    double? mgO,
    double? ca,
    double? b,
    bool? seleccionado,
  }) {
    return ProductoFertilizante(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      concentracionTexto: concentracionTexto ?? this.concentracionTexto,
      precio: precio ?? this.precio,
      n: n ?? this.n,
      p2o5: p2o5 ?? this.p2o5,
      k2o: k2o ?? this.k2o,
      mgO: mgO ?? this.mgO,
      ca: ca ?? this.ca,
      b: b ?? this.b,
      seleccionado: seleccionado ?? this.seleccionado,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'concentracionTexto': concentracionTexto,
      'precio': precio,
      'n': n,
      'p2o5': p2o5,
      'k2o': k2o,
      'mgO': mgO,
      'ca': ca,
      'b': b,
      'seleccionado': seleccionado,
      'tipo': esTemporal ? 'temporal' : esManual ? 'guardada_usuario' : 'base',
    };
  }

  factory ProductoFertilizante.fromMap(Map<String, dynamic> map) {
    final n = _aDouble(map['n']);
    final p2o5 = _aDouble(map['p2o5']);
    final k2o = _aDouble(map['k2o']);

    final concentracion = (map['concentracionTexto'] ?? '')
        .toString()
        .trim()
        .replaceFirst(RegExp(r'^NPK\s+', caseSensitive: false), '');

    final nombre = (map['nombre'] ?? '')
        .toString()
        .trim()
        .replaceFirst(RegExp(r'^NPK\s+', caseSensitive: false), '');

    final concentracionFinal = concentracion.isNotEmpty
        ? concentracion
        : '${_numero(n)}-${_numero(p2o5)}-${_numero(k2o)}';

    final nombreFinal = nombre.isNotEmpty ? nombre : concentracionFinal;

    return ProductoFertilizante(
      id: (map['id'] ?? '').toString(),
      nombre: nombreFinal,
      concentracionTexto: concentracionFinal,
      precio: _aDouble(map['precio']),
      n: n,
      p2o5: p2o5,
      k2o: k2o,
      mgO: _aDouble(map['mgO']),
      ca: _aDouble(map['ca']),
      b: _aDouble(map['b']),
      seleccionado: map['seleccionado'] is bool
          ? map['seleccionado'] as bool
          : false,
    );
  }

  static double _aDouble(dynamic valor) {
    if (valor is num) return valor.toDouble();

    return double.tryParse(
          valor?.toString().trim().replaceAll(',', '.') ?? '',
        ) ??
        0;
  }

  static String _numero(double valor) {
    if (valor == valor.roundToDouble()) return valor.toStringAsFixed(0);
    return valor.toStringAsFixed(1);
  }
}
