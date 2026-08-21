import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/tema/app_colores.dart';

enum EtapaCalculoManual {
  desarrolloVegetativo,
  altaProduccion,
  mantenimiento,
}

extension EtapaCalculoManualX on EtapaCalculoManual {
  String get nombre {
    switch (this) {
      case EtapaCalculoManual.desarrolloVegetativo:
        return 'Desarrollo vegetativo';
      case EtapaCalculoManual.altaProduccion:
        return 'Alta producción';
      case EtapaCalculoManual.mantenimiento:
        return 'Mantenimiento';
    }
  }

  int get mesesCalculo {
    switch (this) {
      case EtapaCalculoManual.desarrolloVegetativo:
        return 5;
      case EtapaCalculoManual.altaProduccion:
        return 9;
      case EtapaCalculoManual.mantenimiento:
        return 9;
    }
  }

  double get porcentajeN {
    switch (this) {
      case EtapaCalculoManual.desarrolloVegetativo:
        return 0.30;
      case EtapaCalculoManual.altaProduccion:
        return 0.40;
      case EtapaCalculoManual.mantenimiento:
        return 0.30;
    }
  }

  double get porcentajeP {
    switch (this) {
      case EtapaCalculoManual.desarrolloVegetativo:
        return 0.20;
      case EtapaCalculoManual.altaProduccion:
        return 0.70;
      case EtapaCalculoManual.mantenimiento:
        return 0.10;
    }
  }

  double get porcentajeK {
    switch (this) {
      case EtapaCalculoManual.desarrolloVegetativo:
        return 0.10;
      case EtapaCalculoManual.altaProduccion:
        return 0.70;
      case EtapaCalculoManual.mantenimiento:
        return 0.20;
    }
  }
}

class CalculadoraNutricionalManualPage extends StatefulWidget {
  const CalculadoraNutricionalManualPage({super.key});

  @override
  State<CalculadoraNutricionalManualPage> createState() =>
      _CalculadoraNutricionalManualPageState();
}

class _CalculadoraNutricionalManualPageState
    extends State<CalculadoraNutricionalManualPage> {
  final _areaController = TextEditingController(text: '1000');
  final _plantasController = TextEditingController(text: '6000');
  final _pesoSueloController = TextEditingController(text: '2400000');
  final _mesesController = TextEditingController(text: '9');

  final _nSensorController = TextEditingController();
  final _pSensorController = TextEditingController();
  final _kSensorController = TextEditingController();

  final _nFertController = TextEditingController();
  final _pFertController = TextEditingController();
  final _kFertController = TextEditingController();

  final _exploracionNController = TextEditingController(text: '0.80');
  final _exploracionPController = TextEditingController(text: '0.40');
  final _exploracionKController = TextEditingController(text: '0.60');

  final _aplicacionNController = TextEditingController(text: '0.80');
  final _aplicacionPController = TextEditingController(text: '0.80');
  final _aplicacionKController = TextEditingController(text: '0.90');

  EtapaCalculoManual _etapa = EtapaCalculoManual.altaProduccion;
  _ResultadoSimulacion? _resultado;

  @override
  void dispose() {
    _areaController.dispose();
    _plantasController.dispose();
    _pesoSueloController.dispose();
    _mesesController.dispose();

    _nSensorController.dispose();
    _pSensorController.dispose();
    _kSensorController.dispose();

    _nFertController.dispose();
    _pFertController.dispose();
    _kFertController.dispose();

    _exploracionNController.dispose();
    _exploracionPController.dispose();
    _exploracionKController.dispose();

    _aplicacionNController.dispose();
    _aplicacionPController.dispose();
    _aplicacionKController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _encabezado(),
            const SizedBox(height: 16),

            _SeccionSimulacion(
              icono: Icons.grass_rounded,
              titulo: 'Datos NPK del sensor',
              subtitulo:
                  'Digite los valores de N, P y K obtenidos en la lectura del suelo.',
              child: Column(
                children: [
                  _filaTresCampos(
                    _CampoManual(
                      controller: _nSensorController,
                      titulo: 'N',
                      subtitulo: 'mg/kg',
                    ),
                    _CampoManual(
                      controller: _pSensorController,
                      titulo: 'P',
                      subtitulo: 'mg/kg',
                    ),
                    _CampoManual(
                      controller: _kSensorController,
                      titulo: 'K',
                      subtitulo: 'mg/kg',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _SeccionSimulacion(
              icono: Icons.science_rounded,
              titulo: 'Concentración del fertilizante',
              subtitulo: 'Digite la concentración del fertilizante.',
              child: Column(
                children: [
                  _filaTresCampos(
                    _CampoManual(
                      controller: _nFertController,
                      titulo: 'N',
                      subtitulo: '%',
                      limitePorcentaje: true,
                    ),
                    _CampoManual(
                      controller: _pFertController,
                      titulo: 'P₂O₅',
                      subtitulo: '%',
                      limitePorcentaje: true,
                    ),
                    _CampoManual(
                      controller: _kFertController,
                      titulo: 'K₂O',
                      subtitulo: '%',
                      limitePorcentaje: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ConcentracionVistaPrevia(
                    n: _double(_nFertController.text) ?? 0,
                    p: _double(_pFertController.text) ?? 0,
                    k: _double(_kFertController.text) ?? 0,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _SeccionSimulacion(
              icono: Icons.tune_rounded,
              titulo: 'Datos para la simulación',
              subtitulo:
                  'Define etapa, área y número de plantas del lote.',
              child: Column(
                children: [
                  DropdownButtonFormField<EtapaCalculoManual>(
                    value: _etapa,
                    decoration: _decoracionCampo(
                      label: 'Etapa del cultivo',
                      icono: Icons.local_florist_rounded,
                    ),
                    items: EtapaCalculoManual.values
                        .map(
                          (etapa) => DropdownMenuItem(
                            value: etapa,
                            child: Text(etapa.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      if (valor == null) return;

                      setState(() {
                        _etapa = valor;
                        _mesesController.text =
                            valor.mesesCalculo.toString();
                        _resultado = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _CampoAncho(
                          controller: _areaController,
                          label: 'Área lote',
                          suffix: 'm²',
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _CampoAncho(
                          controller: _plantasController,
                          label: 'Plantas',
                          suffix: '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _ExpansionTecnica(
              titulo: 'Parámetros técnicos',
              subtitulo:
                  'Valores avanzados utilizados para la estimación.',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CampoAncho(
                        controller: _pesoSueloController,
                        label: 'Peso suelo',
                        suffix: 'kg/ha',
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _CampoAncho(
                        controller: _mesesController,
                        label: 'Meses',
                        suffix: '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _SubtituloTecnico('Eficiencia de exploración'),
                const SizedBox(height: 8),
                _filaTresCampos(
                  _CampoManual(
                    controller: _exploracionNController,
                    titulo: 'N',
                    subtitulo: '0–1',
                  ),
                  _CampoManual(
                    controller: _exploracionPController,
                    titulo: 'P',
                    subtitulo: '0–1',
                  ),
                  _CampoManual(
                    controller: _exploracionKController,
                    titulo: 'K',
                    subtitulo: '0–1',
                  ),
                ),
                const SizedBox(height: 12),
                const _SubtituloTecnico('Eficiencia de aplicación'),
                const SizedBox(height: 8),
                _filaTresCampos(
                  _CampoManual(
                    controller: _aplicacionNController,
                    titulo: 'N',
                    subtitulo: '0–1',
                  ),
                  _CampoManual(
                    controller: _aplicacionPController,
                    titulo: 'P',
                    subtitulo: '0–1',
                  ),
                  _CampoManual(
                    controller: _aplicacionKController,
                    titulo: 'K',
                    subtitulo: '0–1',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _calcular,
                icon: const Icon(Icons.calculate_rounded),
                label: const Text(
                  'Simular cálculo nutricional',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColores.primario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            if (_resultado != null) ...[
              const SizedBox(height: 16),
              _ResultadoSimulacionCard(resultado: _resultado!),
            ],

            const SizedBox(height: 12),
            const _NotaSimulacion(),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 4),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColores.primariosuave,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.calculate_rounded,
            color: AppColores.primario,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simulación nutricional',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColores.textoPrincipal,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Prueba manual con NPK del sensor y concentración',
                style: TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w600,
                  color: AppColores.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filaTresCampos(
    Widget primero,
    Widget segundo,
    Widget tercero,
  ) {
    return Row(
      children: [
        Expanded(child: primero),
        const SizedBox(width: 8),
        Expanded(child: segundo),
        const SizedBox(width: 8),
        Expanded(child: tercero),
      ],
    );
  }

  void _calcular() {
    FocusScope.of(context).unfocus();

    final areaM2 = _double(_areaController.text);
    final plantas = _int(_plantasController.text);
    final pesoSuelo = _double(_pesoSueloController.text);
    final meses = _int(_mesesController.text);

    final nSensor = _double(_nSensorController.text);
    final pSensor = _double(_pSensorController.text);
    final kSensor = _double(_kSensorController.text);

    final nFert = _double(_nFertController.text) ?? 0;
    final pFert = _double(_pFertController.text) ?? 0;
    final kFert = _double(_kFertController.text) ?? 0;

    final expN = _double(_exploracionNController.text);
    final expP = _double(_exploracionPController.text);
    final expK = _double(_exploracionKController.text);

    final aplN = _double(_aplicacionNController.text);
    final aplP = _double(_aplicacionPController.text);
    final aplK = _double(_aplicacionKController.text);

    if (areaM2 == null ||
        areaM2 <= 0 ||
        plantas == null ||
        plantas <= 0 ||
        pesoSuelo == null ||
        pesoSuelo <= 0 ||
        meses == null ||
        meses <= 0 ||
        nSensor == null ||
        nSensor < 0 ||
        pSensor == null ||
        pSensor < 0 ||
        kSensor == null ||
        kSensor < 0 ||
        !_eficienciaValida(expN) ||
        !_eficienciaValida(expP) ||
        !_eficienciaValida(expK) ||
        !_eficienciaValida(aplN) ||
        !_eficienciaValida(aplP) ||
        !_eficienciaValida(aplK)) {
      _mensaje(
        'Revisa los datos del sensor, del lote y los parámetros técnicos.',
      );
      return;
    }

    if ((nFert <= 0 && pFert <= 0 && kFert <= 0) ||
        nFert < 0 ||
        pFert < 0 ||
        kFert < 0 ||
        nFert > 100 ||
        pFert > 100 ||
        kFert > 100) {
      _mensaje(
        'Digite una concentración válida del fertilizante entre 0 y 100 %.',
      );
      return;
    }

    final areaHa = areaM2 / 10000;

    final necesidadN = _calcularNecesidadMensual(
      valorMgKg: nSensor,
      pesoSueloKgHa: pesoSuelo,
      requerimientoTotalKgHa: 250,
      eficienciaExploracion: expN!,
      eficienciaAplicacion: aplN!,
      factorConversion: 1,
      porcentajeEtapa: _etapa.porcentajeN,
      areaHa: areaHa,
      meses: meses,
    );

    final necesidadP = _calcularNecesidadMensual(
      valorMgKg: pSensor,
      pesoSueloKgHa: pesoSuelo,
      requerimientoTotalKgHa: 70,
      eficienciaExploracion: expP!,
      eficienciaAplicacion: aplP!,
      factorConversion: 2.29,
      porcentajeEtapa: _etapa.porcentajeP,
      areaHa: areaHa,
      meses: meses,
    );

    final necesidadK = _calcularNecesidadMensual(
      valorMgKg: kSensor,
      pesoSueloKgHa: pesoSuelo,
      requerimientoTotalKgHa: 300,
      eficienciaExploracion: expK!,
      eficienciaAplicacion: aplK!,
      factorConversion: 1.2,
      porcentajeEtapa: _etapa.porcentajeK,
      areaHa: areaHa,
      meses: meses,
    );

    final dosisPosibles = <double>[];

    if (necesidadN > 0.001 && nFert > 0) {
      dosisPosibles.add(necesidadN / (nFert / 100));
    }

    if (necesidadP > 0.001 && pFert > 0) {
      dosisPosibles.add(necesidadP / (pFert / 100));
    }

    if (necesidadK > 0.001 && kFert > 0) {
      dosisPosibles.add(necesidadK / (kFert / 100));
    }

    final dosisKgMes =
        dosisPosibles.isEmpty ? 0.0 : dosisPosibles.reduce(math.max);

    final aporteN = dosisKgMes * nFert / 100;
    final aporteP = dosisKgMes * pFert / 100;
    final aporteK = dosisKgMes * kFert / 100;

    final double faltanteN = math.max(0.0, necesidadN - aporteN);
final double faltanteP = math.max(0.0, necesidadP - aporteP);
final double faltanteK = math.max(0.0, necesidadK - aporteK);

final double excesoN = math.max(0.0, aporteN - necesidadN);
final double excesoP = math.max(0.0, aporteP - necesidadP);
final double excesoK = math.max(0.0, aporteK - necesidadK);

    setState(() {
      _resultado = _ResultadoSimulacion(
        etapa: _etapa.nombre,
        plantas: plantas,
        nSensor: nSensor,
        pSensor: pSensor,
        kSensor: kSensor,
        nFert: nFert,
        pFert: pFert,
        kFert: kFert,
        necesidadN: necesidadN,
        necesidadP: necesidadP,
        necesidadK: necesidadK,
        dosisKgMes: dosisKgMes,
        gramosPlantaMes:
            plantas > 0 ? dosisKgMes * 1000 / plantas : 0,
        aporteN: aporteN,
        aporteP: aporteP,
        aporteK: aporteK,
        faltanteN: faltanteN,
        faltanteP: faltanteP,
        faltanteK: faltanteK,
        excesoN: excesoN,
        excesoP: excesoP,
        excesoK: excesoK,
      );
    });
  }

  double _calcularNecesidadMensual({
    required double valorMgKg,
    required double pesoSueloKgHa,
    required double requerimientoTotalKgHa,
    required double eficienciaExploracion,
    required double eficienciaAplicacion,
    required double factorConversion,
    required double porcentajeEtapa,
    required double areaHa,
    required int meses,
  }) {
    final kgHaSuelo = valorMgKg * pesoSueloKgHa / 1000000;
    final disponibleReal = kgHaSuelo * eficienciaExploracion;
    final faltanteKgHa =
        math.max(0, requerimientoTotalKgHa - disponibleReal);
    final faltanteAjustado = faltanteKgHa * (2 - eficienciaAplicacion);
    final formaComercial = faltanteAjustado * factorConversion;
    final faltanteLote = formaComercial * areaHa;
    final faltanteEtapa = faltanteLote * porcentajeEtapa;

    return meses > 0 ? faltanteEtapa / meses : 0;
  }

  bool _eficienciaValida(double? valor) {
    return valor != null && valor > 0 && valor <= 1;
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }
}

class _ResultadoSimulacion {
  const _ResultadoSimulacion({
    required this.etapa,
    required this.plantas,
    required this.nSensor,
    required this.pSensor,
    required this.kSensor,
    required this.nFert,
    required this.pFert,
    required this.kFert,
    required this.necesidadN,
    required this.necesidadP,
    required this.necesidadK,
    required this.dosisKgMes,
    required this.gramosPlantaMes,
    required this.aporteN,
    required this.aporteP,
    required this.aporteK,
    required this.faltanteN,
    required this.faltanteP,
    required this.faltanteK,
    required this.excesoN,
    required this.excesoP,
    required this.excesoK,
  });

  final String etapa;
  final int plantas;

  final double nSensor;
  final double pSensor;
  final double kSensor;

  final double nFert;
  final double pFert;
  final double kFert;

  final double necesidadN;
  final double necesidadP;
  final double necesidadK;

  final double dosisKgMes;
  final double gramosPlantaMes;

  final double aporteN;
  final double aporteP;
  final double aporteK;

  final double faltanteN;
  final double faltanteP;
  final double faltanteK;

  final double excesoN;
  final double excesoP;
  final double excesoK;
}

class _ResultadoSimulacionCard extends StatelessWidget {
  const _ResultadoSimulacionCard({
    required this.resultado,
  });

  final _ResultadoSimulacion resultado;

  @override
  Widget build(BuildContext context) {
    final hayFaltante = resultado.faltanteN > 0.001 ||
        resultado.faltanteP > 0.001 ||
        resultado.faltanteK > 0.001;

    final hayExceso = resultado.excesoN > 0.001 ||
        resultado.excesoP > 0.001 ||
        resultado.excesoK > 0.001;

    return _SeccionSimulacion(
      icono: Icons.analytics_rounded,
      titulo: 'Resultado de la simulación',
      subtitulo: '${resultado.etapa} · ${resultado.plantas} plantas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BloqueResultado(
            titulo: 'NPK ingresado del sensor',
            valores: [
              _ValorResultado('N', resultado.nSensor, 'mg/kg'),
              _ValorResultado('P', resultado.pSensor, 'mg/kg'),
              _ValorResultado('K', resultado.kSensor, 'mg/kg'),
            ],
          ),
          const SizedBox(height: 10),
          _BloqueResultado(
            titulo: 'Faltante estimado',
            valores: [
              _ValorResultado('N', resultado.necesidadN, 'kg/mes'),
              _ValorResultado('P₂O₅', resultado.necesidadP, 'kg/mes'),
              _ValorResultado('K₂O', resultado.necesidadK, 'kg/mes'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColores.primariosuave,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: AppColores.primario.withOpacity(0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Concentración simulada',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_numero(resultado.nFert)}-${_numero(resultado.pFert)}-${_numero(resultado.kFert)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColores.primario,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DatoDestacado(
                        titulo: 'Dosis',
                        valor: '${_numero(resultado.dosisKgMes)} kg/mes',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DatoDestacado(
                        titulo: 'Por planta',
                        valor:
                            '${_numero(resultado.gramosPlantaMes)} g/mes',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _BloqueResultado(
            titulo: 'Aporte del fertilizante',
            valores: [
              _ValorResultado('N', resultado.aporteN, 'kg'),
              _ValorResultado('P₂O₅', resultado.aporteP, 'kg'),
              _ValorResultado('K₂O', resultado.aporteK, 'kg'),
            ],
          ),
          const SizedBox(height: 10),
          _BloqueResultado(
            titulo: 'Balance después de aplicar',
            valores: [
              _ValorResultado(
                'N',
                hayFaltante
                    ? resultado.faltanteN
                    : resultado.excesoN,
                resultado.faltanteN > 0.001 ? 'faltante' : 'exceso',
              ),
              _ValorResultado(
                'P₂O₅',
                resultado.faltanteP > 0.001
                    ? resultado.faltanteP
                    : resultado.excesoP,
                resultado.faltanteP > 0.001 ? 'faltante' : 'exceso',
              ),
              _ValorResultado(
                'K₂O',
                resultado.faltanteK > 0.001
                    ? resultado.faltanteK
                    : resultado.excesoK,
                resultado.faltanteK > 0.001 ? 'faltante' : 'exceso',
              ),
            ],
          ),
          if (hayExceso) ...[
            const SizedBox(height: 10),
            _MensajeResultado(
              icono: Icons.info_outline_rounded,
              texto:
                  'La concentración cubre el requerimiento calculado, pero genera excedente en uno o más nutrientes.',
              color: AppColores.advertencia,
            ),
          ] else if (!hayFaltante) ...[
            const SizedBox(height: 10),
            const _MensajeResultado(
              icono: Icons.check_circle_outline_rounded,
              texto:
                  'La concentración cubre el requerimiento estimado sin faltantes relevantes.',
              color: AppColores.primario,
            ),
          ] else ...[
            const SizedBox(height: 10),
            const _MensajeResultado(
              icono: Icons.info_outline_rounded,
              texto:
                  'La concentración no aporta todos los nutrientes faltantes. Puedes probar otra concentración.',
              color: AppColores.advertencia,
            ),
          ],
        ],
      ),
    );
  }
}

class _SeccionSimulacion extends StatelessWidget {
  const _SeccionSimulacion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.child,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColores.primariosuave,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icono,
                  color: AppColores.primario,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppColores.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 11.2,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: AppColores.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _CampoManual extends StatelessWidget {
  const _CampoManual({
    required this.controller,
    required this.titulo,
    required this.subtitulo,
    this.limitePorcentaje = false,
  });

  final TextEditingController controller;
  final String titulo;
  final String subtitulo;
  final bool limitePorcentaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 7),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            onChanged: (_) {
              // La vista previa de concentración se actualiza al recalcular;
              // no afecta la lógica de la simulación.
            },
            decoration: const InputDecoration(
              isDense: true,
              hintText: '0',
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColores.primario,
            ),
          ),
          Text(
            subtitulo,
            style: const TextStyle(
              fontSize: 9.8,
              fontWeight: FontWeight.w700,
              color: AppColores.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoAncho extends StatelessWidget {
  const _CampoAncho({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: _decoracionCampo(
        label: label,
        suffix: suffix,
      ),
    );
  }
}

class _ConcentracionVistaPrevia extends StatelessWidget {
  const _ConcentracionVistaPrevia({
    required this.n,
    required this.p,
    required this.k,
  });

  final double n;
  final double p;
  final double k;

  @override
  Widget build(BuildContext context) {
    if (n <= 0 && p <= 0 && k <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColores.primariosuave.withOpacity(0.55),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        'Concentración: ${_numero(n)}-${_numero(p)}-${_numero(k)}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12.2,
          fontWeight: FontWeight.w900,
          color: AppColores.primario,
        ),
      ),
    );
  }
}

class _ExpansionTecnica extends StatelessWidget {
  const _ExpansionTecnica({
    required this.titulo,
    required this.subtitulo,
    required this.children,
  });

  final String titulo;
  final String subtitulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColores.borde),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColores.primariosuave,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.settings_outlined,
            color: AppColores.primario,
            size: 19,
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: AppColores.textoPrincipal,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: const TextStyle(
            fontSize: 10.8,
            color: AppColores.textoSecundario,
          ),
        ),
        children: children,
      ),
    );
  }
}

class _SubtituloTecnico extends StatelessWidget {
  const _SubtituloTecnico(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: AppColores.textoPrincipal,
        ),
      ),
    );
  }
}

class _BloqueResultado extends StatelessWidget {
  const _BloqueResultado({
    required this.titulo,
    required this.valores,
  });

  final String titulo;
  final List<_ValorResultado> valores;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < valores.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        valores[i].nombre,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColores.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _numero(valores[i].valor),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColores.textoPrincipal,
                        ),
                      ),
                      Text(
                        valores[i].unidad,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColores.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i != valores.length - 1)
                  const SizedBox(width: 5),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ValorResultado {
  const _ValorResultado(this.nombre, this.valor, this.unidad);

  final String nombre;
  final double valor;
  final String unidad;
}

class _DatoDestacado extends StatelessWidget {
  const _DatoDestacado({
    required this.titulo,
    required this.valor,
  });

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppColores.primario.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 13.2,
              fontWeight: FontWeight.w900,
              color: AppColores.primario,
            ),
          ),
        ],
      ),
    );
  }
}

class _MensajeResultado extends StatelessWidget {
  const _MensajeResultado({
    required this.icono,
    required this.texto,
    required this.color,
  });

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 11.2,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColores.textoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotaSimulacion extends StatelessWidget {
  const _NotaSimulacion();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColores.advertenciasuave.withOpacity(0.55),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColores.advertencia.withOpacity(0.16),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColores.advertencia,
            size: 19,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esta herramienta es una simulación manual. No modifica el plan '
              'nutricional principal ni guarda estos valores en la base de datos.',
              style: TextStyle(
                fontSize: 10.8,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColores.textoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _decoracionCampo({
  required String label,
  IconData? icono,
  String? suffix,
}) {
  return InputDecoration(
    labelText: label,
    suffixText: suffix == null || suffix.isEmpty ? null : suffix,
    prefixIcon: icono == null ? null : Icon(icono, size: 19),
    filled: true,
    fillColor: AppColores.fondo,
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColores.borde),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColores.borde),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 12,
    ),
  );
}

double? _double(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  return double.tryParse(limpio);
}

int? _int(String texto) {
  final valor = _double(texto);
  return valor?.round();
}

String _numero(double valor) {
  if (!valor.isFinite) return '0';

  if (valor.abs() < 0.005) return '0';

  if (valor == valor.roundToDouble()) {
    return valor.toStringAsFixed(0);
  }

  if (valor.abs() >= 100) {
    return valor.toStringAsFixed(1);
  }

  return valor.toStringAsFixed(2);
}
