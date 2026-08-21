import '../../../../core/constantes/rangos_agronomicos.dart';
import '../../../historial/domain/entities/lectura_historial.dart';
import '../../../sensores/domain/entities/datos_sensor_suelo.dart';
import '../entities/recomendacion.dart';

class GeneradorRecomendaciones {
  const GeneradorRecomendaciones();

  List<Recomendacion> generar(
    DatosSensorSuelo lectura, {
    List<LecturaHistorial> historial = const [],
  }) {
    final recomendaciones = <Recomendacion>[];

    final lecturaNoRepresentativa =
        lectura.humedadSuelo <= 1 &&
        lectura.conductividadElectrica <= 0.01 &&
        lectura.nitrogeno <= 1 &&
        lectura.fosforo <= 1 &&
        lectura.potasio <= 1;

    if (lecturaNoRepresentativa) {
      return const [
        Recomendacion(
          titulo: 'Verificar instalación del sensor',
          descripcion:
              'La humedad, la conductividad eléctrica y los nutrientes aparecen en cero. El sensor podría estar fuera del suelo o sin contacto suficiente.',
          prioridad: 1,
          tipo: TipoRecomendacion.general,
          variable: 'Sensor de suelo',
          valorActual: 'Humedad, EC y NPK en cero',
          rangoIdeal: 'Lectura válida con sensor insertado en suelo',
          accionSugerida:
              'Inserte el sensor correctamente en el suelo, asegure buen contacto y espere una nueva lectura antes de tomar decisiones agronómicas.',
          explicacion:
              'Cuando varias variables del suelo aparecen en cero al mismo tiempo, la lectura puede no representar una condición real del cultivo sino una prueba o instalación incompleta.',
        ),
      ];
    }

    _evaluarHumedad(lectura, recomendaciones);
    _evaluarTemperatura(lectura, recomendaciones);
    _evaluarPh(lectura, recomendaciones);
    _evaluarConductividad(lectura, recomendaciones);
    _evaluarNutrientes(lectura, recomendaciones);

    _evaluarCombinaciones(lectura, recomendaciones);
    _evaluarTendencias(historial, recomendaciones);

    recomendaciones.sort((a, b) => a.prioridad.compareTo(b.prioridad));
    return recomendaciones;
  }


  void _evaluarHumedad(
    DatosSensorSuelo lectura,
    List<Recomendacion> recomendaciones,
  ) {
    final humedad = lectura.humedadSuelo;
    final min = RangosAgronomicos.humedadSuelo.minimo;
    final max = RangosAgronomicos.humedadSuelo.maximo;

    if (humedad < min) {
      recomendaciones.add(
        Recomendacion(
          titulo: humedad < 35 ? 'Humedad crítica baja' : 'Humedad baja',
          descripcion:
              'El suelo presenta baja humedad. Esto puede afectar el desarrollo del cultivo de fresa.',
          prioridad: humedad < 35 ? 1 : 2,
          tipo: TipoRecomendacion.riego,
          variable: 'Humedad del suelo',
          valorActual: '${humedad.toStringAsFixed(1)} %',
          rangoIdeal: '${min.toStringAsFixed(0)}–${max.toStringAsFixed(0)} %',
          accionSugerida:
              'Revise el sistema de riego y considere aumentar la frecuencia de riego.',
          explicacion:
              'La humedad se compara con el rango recomendado para el cultivo. Valores por debajo del rango indican posible déficit hídrico.',
        ),
      );
    }

    if (humedad > max) {
      recomendaciones.add(
        Recomendacion(
          titulo: humedad > 75
              ? 'Exceso crítico de humedad'
              : 'Exceso de humedad',
          descripcion:
              'El suelo tiene humedad por encima del rango recomendado. Puede aumentar el riesgo de problemas radiculares.',
          prioridad: humedad > 75 ? 1 : 2,
          tipo: TipoRecomendacion.riego,
          variable: 'Humedad del suelo',
          valorActual: '${humedad.toStringAsFixed(1)} %',
          rangoIdeal: '${min.toStringAsFixed(0)}–${max.toStringAsFixed(0)} %',
          accionSugerida:
              'Disminuya temporalmente el riego y revise el drenaje del suelo.',
          explicacion:
              'La humedad alta de forma sostenida puede afectar la aireación del suelo y favorecer enfermedades.',
        ),
      );
    }
  }


  void _evaluarTemperatura(
    DatosSensorSuelo lectura,
    List<Recomendacion> recomendaciones,
  ) {
    final temperatura = lectura.temperaturaSuelo;
    const diaIdeal = '15–18 °C de día';
    const nocheIdeal = '8–10 °C de noche';
    final minOperativo = RangosAgronomicos.temperaturaSuelo.minimo;
    final maxOperativo = RangosAgronomicos.temperaturaSuelo.maximo;

    if (temperatura < 8) {
      recomendaciones.add(
        Recomendacion(
          titulo: 'Temperatura crítica baja',
          descripcion:
              'La temperatura del suelo está muy baja para el cultivo de fresa.',
          prioridad: 1,
          tipo: TipoRecomendacion.temperatura,
          variable: 'Temperatura del suelo',
          valorActual: '${temperatura.toStringAsFixed(1)} °C',
          rangoIdeal: '$diaIdeal / $nocheIdeal',
          accionSugerida:
              'Monitoree el lote, evite riegos excesivos en horas frías y revise si se requiere protección del cultivo.',
          explicacion:
              'El asesor indicó rangos ideales de 15–18 °C durante el día y 8–10 °C durante la noche. Valores inferiores a 8 °C pueden reducir la actividad radicular y afectar el desarrollo.',
        ),
      );
      return;
    }

    if (temperatura >= 8 && temperatura <= 10) {
      return;
    }

    if (temperatura > 10 && temperatura < minOperativo) {
      recomendaciones.add(
        Recomendacion(
          titulo: 'Temperatura baja del suelo',
          descripcion:
              'La temperatura está por debajo del rango diurno ideal para fresa.',
          prioridad: 2,
          tipo: TipoRecomendacion.temperatura,
          variable: 'Temperatura del suelo',
          valorActual: '${temperatura.toStringAsFixed(1)} °C',
          rangoIdeal: '$diaIdeal / $nocheIdeal',
          accionSugerida:
              'Compare la lectura con la hora del día. Si ocurre durante el día, revise condiciones del lote y evite riegos innecesarios en horas frías.',
          explicacion:
              'Temperaturas bajas pueden disminuir la actividad radicular. Si la lectura corresponde a la noche, puede ser normal; si corresponde al día, requiere seguimiento.',
        ),
      );
      return;
    }

    if (temperatura >= minOperativo && temperatura <= maxOperativo) {
      return;
    }

    if (temperatura > maxOperativo && temperatura <= 30) {
      recomendaciones.add(
        Recomendacion(
          titulo: 'Temperatura alta del suelo',
          descripcion:
              'La temperatura del suelo está por encima del rango operativo recomendado.',
          prioridad: 2,
          tipo: TipoRecomendacion.temperatura,
          variable: 'Temperatura del suelo',
          valorActual: '${temperatura.toStringAsFixed(1)} °C',
          rangoIdeal: '$diaIdeal / $nocheIdeal',
          accionSugerida:
              'Revise humedad, cobertura, acolchado o sombreo para reducir estrés térmico.',
          explicacion:
              'Temperaturas altas aumentan evaporación y pueden intensificar el estrés hídrico del cultivo.',
        ),
      );
      return;
    }

    recomendaciones.add(
      Recomendacion(
        titulo: 'Temperatura crítica alta',
        descripcion:
            'La temperatura del suelo está muy alta y puede generar estrés en el cultivo.',
        prioridad: 1,
        tipo: TipoRecomendacion.temperatura,
        variable: 'Temperatura del suelo',
        valorActual: '${temperatura.toStringAsFixed(1)} °C',
        rangoIdeal: '$diaIdeal / $nocheIdeal',
        accionSugerida:
            'Priorice revisión de riego, humedad, cobertura y condiciones de ventilación o sombreo.',
        explicacion:
            'Temperaturas superiores a 30 °C pueden aumentar el estrés del cultivo y reducir la eficiencia en absorción de agua y nutrientes.',
      ),
    );
  }


  void _evaluarPh(
    DatosSensorSuelo lectura,
    List<Recomendacion> recomendaciones,
  ) {
    final ph = lectura.phSuelo;
    final min = RangosAgronomicos.phSuelo.minimo;
    final max = RangosAgronomicos.phSuelo.maximo;

    if (ph <= 0) {
      recomendaciones.add(
        Recomendacion(
          titulo: 'Lectura inválida de pH',
          descripcion:
              'El pH aparece en cero o con un valor no válido. Esto puede indicar una lectura no representativa.',
          prioridad: 2,
          tipo: TipoRecomendacion.general,
          variable: 'pH del suelo',
          valorActual: ph.toStringAsFixed(1),
          rangoIdeal: '${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)}',
          accionSugerida:
              'Verifique que el sensor esté correctamente insertado y espere una nueva lectura.',
          explicacion:
              'El pH del suelo no debería interpretarse como cero en una lectura agronómica válida.',
        ),
      );
      return;
    }

    if (ph < min) {
      recomendaciones.add(
        Recomendacion(
          titulo: ph < 5.3 ? 'pH críticamente ácido' : 'pH bajo',
          descripcion:
              'El suelo presenta acidez por debajo del rango recomendado para fresa.',
          prioridad: ph < 5.3 ? 1 : 2,
          tipo: TipoRecomendacion.ph,
          variable: 'pH del suelo',
          valorActual: ph.toStringAsFixed(1),
          rangoIdeal: '${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)}',
          accionSugerida:
              'Evalúe una corrección de acidez con acompañamiento técnico.',
          explicacion:
              'El pH influye en la disponibilidad de nutrientes. Un pH bajo puede limitar la absorción de algunos elementos.',
        ),
      );
    }

    if (ph > max) {
      recomendaciones.add(
        Recomendacion(
          titulo: ph > 7.0 ? 'pH críticamente alto' : 'pH alto',
          descripcion:
              'El pH está por encima del rango recomendado y puede afectar la disponibilidad de nutrientes.',
          prioridad: ph > 7.0 ? 1 : 2,
          tipo: TipoRecomendacion.ph,
          variable: 'pH del suelo',
          valorActual: ph.toStringAsFixed(1),
          rangoIdeal: '${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)}',
          accionSugerida:
              'Revise el manejo del suelo y consulte una corrección con asesor agronómico.',
          explicacion:
              'Valores altos de pH pueden reducir la disponibilidad de algunos nutrientes esenciales.',
        ),
      );
    }
  }


  void _evaluarConductividad(
    DatosSensorSuelo lectura,
    List<Recomendacion> recomendaciones,
  ) {
    final ec = RangosAgronomicos.normalizarEcADsM(
      lectura.conductividadElectrica,
    );
    final min = RangosAgronomicos.conductividadElectrica.minimo;
    final max = RangosAgronomicos.conductividadElectrica.maximo;
    final limite = RangosAgronomicos.conductividadMaximaRecomendada;

    if (ec < 0) {
      recomendaciones.add(
        Recomendacion(
          titulo: 'Lectura inválida de conductividad',
          descripcion:
              'La conductividad eléctrica no debería tener valores negativos. Puede existir un error de lectura, conversión o envío por MQTT.',
          prioridad: 1,
          tipo: TipoRecomendacion.general,
          variable: 'Conductividad eléctrica',
          valorActual: '${ec.toStringAsFixed(2)} dS/m',
          rangoIdeal: '${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)} dS/m; no superar ${limite.toStringAsFixed(1)} dS/m',
          accionSugerida:
              'Revise la conversión del dato, el JSON enviado por MQTT y la lectura Modbus antes de tomar decisiones agronómicas.',
          explicacion:
              'La conductividad eléctrica representa concentración de sales disueltas y no puede ser negativa. Por eso el sistema la marca como lectura inválida de alta prioridad.',
        ),
      );
      return;
    }

    if (ec == 0) {
      recomendaciones.add(
        Recomendacion(
          titulo: 'Conductividad en cero',
          descripcion:
              'La conductividad eléctrica aparece en cero. Esto puede indicar que el sensor no tiene suficiente contacto con el suelo o que la lectura no es representativa.',
          prioridad: 2,
          tipo: TipoRecomendacion.general,
          variable: 'Conductividad eléctrica',
          valorActual: '${ec.toStringAsFixed(2)} dS/m',
          rangoIdeal: '${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)} dS/m',
          accionSugerida:
              'Verifique que el sensor esté correctamente insertado en suelo húmedo y espere una nueva lectura antes de interpretar la EC.',
          explicacion:
              'Una EC igual a cero puede ocurrir durante pruebas, con el sensor fuera del suelo o en un medio sin contacto suficiente.',
        ),
      );
      return;
    }

    if (ec > 0 && ec < min) {
      recomendaciones.add(
        Recomendacion(
          titulo: 'Conductividad baja',
          descripcion:
              'La conductividad eléctrica está por debajo del rango normal indicado para fresa.',
          prioridad: 2,
          tipo: TipoRecomendacion.fertilizacion,
          variable: 'Conductividad eléctrica',
          valorActual: '${ec.toStringAsFixed(2)} dS/m',
          rangoIdeal: '${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)} dS/m',
          accionSugerida:
              'Revise el plan nutricional, el estado de NPK y la tendencia antes de aumentar fertilización.',
          explicacion:
              'Una EC baja puede indicar baja concentración de sales o nutrientes en la solución del suelo, pero debe interpretarse junto con NPK y humedad.',
        ),
      );
      return;
    }

    if (ec >= min && ec <= max) {
      return;
    }

    if (ec > max && ec <= limite) {
      recomendaciones.add(
        Recomendacion(
          titulo: 'Conductividad cercana al límite',
          descripcion:
              'La conductividad eléctrica está por encima del rango normal y se aproxima al límite que no debería superarse.',
          prioridad: 2,
          tipo: TipoRecomendacion.salinidad,
          variable: 'Conductividad eléctrica',
          valorActual: '${ec.toStringAsFixed(2)} dS/m',
          rangoIdeal: '${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)} dS/m; no superar ${limite.toStringAsFixed(1)} dS/m',
          accionSugerida:
              'Evite aumentar fertilización salina, revise calidad del agua y observe si la EC continúa subiendo.',
          explicacion:
              'El asesor indicó que la CE normal está entre 0.8 y 1.8 dS/m y que no debe superar 2.0 dS/m.',
        ),
      );
      return;
    }

    recomendaciones.add(
      Recomendacion(
        titulo: 'Riesgo alto de salinidad',
        descripcion:
            'La conductividad eléctrica supera el límite recomendado y puede afectar la disponibilidad de agua para la planta.',
        prioridad: 1,
        tipo: TipoRecomendacion.salinidad,
        variable: 'Conductividad eléctrica',
        valorActual: '${ec.toStringAsFixed(2)} dS/m',
        rangoIdeal: '${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)} dS/m; no superar ${limite.toStringAsFixed(1)} dS/m',
        accionSugerida:
            'Suspenda aumentos de fertilización, revise fertirriego, calidad del agua, drenaje y posible lavado de sales con acompañamiento técnico.',
        explicacion:
            'La salinidad reduce el potencial hídrico del suelo y puede limitar la absorción de agua, además de generar lesiones o estrés en plantas expuestas a niveles altos.',
      ),
    );
  }


  void _evaluarNutrientes(
    DatosSensorSuelo lectura,
    List<Recomendacion> recomendaciones,
  ) {
    _evaluarNutriente(
      recomendaciones: recomendaciones,
      nombre: 'Nitrógeno',
      simbolo: 'N',
      valor: lectura.nitrogeno,
      minimo: RangosAgronomicos.nitrogenoFructificacion.minimo,
      maximo: RangosAgronomicos.nitrogenoFructificacion.maximo,
      funcion: 'crecimiento vegetativo y vigor de la planta',
    );

    _evaluarNutriente(
      recomendaciones: recomendaciones,
      nombre: 'Fósforo',
      simbolo: 'P',
      valor: lectura.fosforo,
      minimo: RangosAgronomicos.fosforoFructificacion.minimo,
      maximo: RangosAgronomicos.fosforoFructificacion.maximo,
      funcion: 'desarrollo radicular, floración y fructificación',
    );

    _evaluarNutriente(
      recomendaciones: recomendaciones,
      nombre: 'Potasio',
      simbolo: 'K',
      valor: lectura.potasio,
      minimo: RangosAgronomicos.potasioFructificacion.minimo,
      maximo: RangosAgronomicos.potasioFructificacion.maximo,
      funcion: 'calidad del fruto, llenado y resistencia de la planta',
    );
  }

  void _evaluarNutriente({
    required List<Recomendacion> recomendaciones,
    required String nombre,
    required String simbolo,
    required double valor,
    required double minimo,
    required double maximo,
    required String funcion,
  }) {
    if (valor <= 0) {
      recomendaciones.add(
        Recomendacion(
          titulo: 'Lectura no válida de $nombre',
          descripcion:
              'El valor de $nombre aparece en cero. Puede tratarse de una lectura no representativa.',
          prioridad: 2,
          tipo: TipoRecomendacion.general,
          variable: '$nombre ($simbolo)',
          valorActual: '${valor.toStringAsFixed(0)} mg/kg',
          rangoIdeal: '${minimo.toStringAsFixed(0)}–${maximo.toStringAsFixed(0)} mg/kg',
          accionSugerida:
              'Verifique que el sensor esté correctamente insertado antes de interpretar este valor como deficiencia nutricional.',
          explicacion:
              'Un nutriente en cero puede aparecer durante pruebas o cuando el sensor no tiene contacto suficiente con el suelo.',
        ),
      );
      return;
    }

    if (valor < minimo) {
      final critico = simbolo == 'N'
          ? valor < 50
          : simbolo == 'P'
              ? valor < 10
              : valor < 50;

      recomendaciones.add(
        Recomendacion(
          titulo: critico ? 'Deficiencia crítica de $nombre' : '$nombre bajo',
          descripcion:
              'El nivel de $nombre está por debajo del rango recomendado para fresa.',
          prioridad: critico ? 1 : 2,
          tipo: TipoRecomendacion.fertilizacion,
          variable: '$nombre ($simbolo)',
          valorActual: '${valor.toStringAsFixed(0)} mg/kg',
          rangoIdeal: '${minimo.toStringAsFixed(0)}–${maximo.toStringAsFixed(0)} mg/kg',
          accionSugerida:
              'Revise el plan nutricional antes de corregir. Valide humedad, CE y pH para evitar aplicar fertilizante cuando el problema sea absorción o disponibilidad.',
          explicacion:
              '$nombre participa en $funcion. La recomendación se genera al comparar el valor actual del sensor con el rango técnico del asesor.',
        ),
      );
      return;
    }

    if (valor <= maximo) {
      return;
    }

    final muyAlto = simbolo == 'N'
        ? valor > 160
        : simbolo == 'P'
            ? valor > 60
            : valor > 220;

    recomendaciones.add(
      Recomendacion(
        titulo: muyAlto ? 'Nivel muy alto de $nombre' : '$nombre alto',
        descripcion:
            'El nivel de $nombre está por encima del rango recomendado para fresa.',
        prioridad: muyAlto ? 1 : 2,
        tipo: TipoRecomendacion.fertilizacion,
        variable: '$nombre ($simbolo)',
        valorActual: '${valor.toStringAsFixed(0)} mg/kg',
        rangoIdeal: '${minimo.toStringAsFixed(0)}–${maximo.toStringAsFixed(0)} mg/kg',
        accionSugerida:
            'No aumente fertilizantes con alto contenido de $simbolo en este momento. Revise el plan de fertirriego, la CE y el historial para evitar sobrefertilización.',
        explicacion:
            'Un nivel alto no significa que se requiera aplicar más fertilizante. Significa que no se recomienda aportar más de este nutriente hasta validar el balance nutricional.',
      ),
    );
  }


  void _evaluarCombinaciones(
    DatosSensorSuelo lectura,
    List<Recomendacion> recomendaciones,
  ) {
    final humedadBaja =
        lectura.humedadSuelo < RangosAgronomicos.humedadSuelo.minimo;

    final humedadAlta =
        lectura.humedadSuelo > RangosAgronomicos.humedadSuelo.maximo;

    final temperaturaAlta =
        lectura.temperaturaSuelo > RangosAgronomicos.temperaturaSuelo.maximo;

    final ecCriticaAlta = lectura.conductividadElectrica > 2.5;

    final phFueraDeRango =
        lectura.phSuelo > 0 &&
        (lectura.phSuelo < RangosAgronomicos.phSuelo.minimo ||
            lectura.phSuelo > RangosAgronomicos.phSuelo.maximo);

    final nBajo = lectura.nitrogeno > 0 &&
        lectura.nitrogeno <
            RangosAgronomicos.nitrogenoFructificacion.minimo;

    final pBajo = lectura.fosforo > 0 &&
        lectura.fosforo < RangosAgronomicos.fosforoFructificacion.minimo;

    final kBajo = lectura.potasio > 0 &&
        lectura.potasio < RangosAgronomicos.potasioFructificacion.minimo;

    if (humedadBaja && temperaturaAlta) {
      recomendaciones.add(
        const Recomendacion(
          titulo: 'Posible estrés hídrico',
          descripcion:
              'La humedad baja combinada con temperatura alta puede generar estrés en el cultivo.',
          prioridad: 1,
          tipo: TipoRecomendacion.riego,
          variable: 'Humedad + temperatura',
          accionSugerida:
              'Priorice la revisión del riego y observe signos de marchitez en las plantas.',
          explicacion:
              'Esta recomendación surge de una regla combinada: cuando el suelo está seco y caliente, aumenta el riesgo de estrés hídrico.',
        ),
      );
    }

    if (humedadAlta && temperaturaAlta) {
      recomendaciones.add(
        const Recomendacion(
          titulo: 'Riesgo por humedad y temperatura altas',
          descripcion:
              'La combinación de humedad alta y temperatura alta puede favorecer problemas sanitarios.',
          prioridad: 1,
          tipo: TipoRecomendacion.general,
          variable: 'Humedad + temperatura',
          accionSugerida:
              'Revise ventilación, drenaje y presencia de enfermedades en el cultivo.',
          explicacion:
              'La combinación de alta humedad y temperatura puede crear condiciones favorables para patógenos.',
        ),
      );
    }

    if (ecCriticaAlta && humedadBaja) {
      recomendaciones.add(
        const Recomendacion(
          titulo: 'Riesgo de concentración de sales',
          descripcion:
              'La conductividad muy alta con baja humedad puede aumentar el estrés salino.',
          prioridad: 1,
          tipo: TipoRecomendacion.salinidad,
          variable: 'EC + humedad',
          accionSugerida:
              'Revise la calidad del agua, fertilización y humedad del suelo.',
          explicacion:
              'Cuando hay poca humedad y la EC es muy alta, las sales pueden concentrarse más en la solución del suelo.',
        ),
      );
    }

    if (phFueraDeRango && (nBajo || pBajo || kBajo)) {
      recomendaciones.add(
        const Recomendacion(
          titulo: 'pH puede afectar la nutrición',
          descripcion:
              'El pH fuera de rango puede limitar la disponibilidad de nutrientes.',
          prioridad: 1,
          tipo: TipoRecomendacion.ph,
          variable: 'pH + NPK',
          accionSugerida:
              'Antes de aumentar fertilización, revise si el pH está afectando la absorción de nutrientes.',
          explicacion:
              'Esta regla combinada evita recomendar solo fertilización cuando el problema puede estar relacionado con disponibilidad nutricional por pH.',
        ),
      );
    }

    if (nBajo && pBajo && kBajo) {
      recomendaciones.add(
        const Recomendacion(
          titulo: 'Deficiencia nutricional general',
          descripcion:
              'Los tres nutrientes principales se encuentran por debajo del rango recomendado.',
          prioridad: 1,
          tipo: TipoRecomendacion.fertilizacion,
          variable: 'NPK',
          accionSugerida:
              'Revise integralmente el plan de fertilización del cultivo.',
          explicacion:
              'La deficiencia simultánea de N, P y K indica un posible problema general de nutrición o manejo del suelo.',
        ),
      );
    }
  }


  void _evaluarTendencias(
    List<LecturaHistorial> historial,
    List<Recomendacion> recomendaciones,
  ) {
    if (historial.length < 4) return;

    final ultimas = historial.length > 6
        ? historial.sublist(historial.length - 6)
        : historial;

    _evaluarTendenciaHumedad(ultimas, recomendaciones);
    _evaluarTendenciaTemperatura(ultimas, recomendaciones);
    _evaluarTendenciaPh(ultimas, recomendaciones);
    _evaluarTendenciaEc(ultimas, recomendaciones);
    _evaluarTendenciaNutrientes(ultimas, recomendaciones);
  }

  void _evaluarTendenciaHumedad(
    List<LecturaHistorial> lecturas,
    List<Recomendacion> recomendaciones,
  ) {
    final bajando = _vieneBajando(
      lecturas.map((l) => l.humedad).toList(),
      umbral: 2.0,
    );

    final subiendo = _vieneSubiendo(
      lecturas.map((l) => l.humedad).toList(),
      umbral: 2.0,
    );

    final ultima = lecturas.last.humedad;

    if (bajando && ultima < 50) {
      recomendaciones.add(
        const Recomendacion(
          titulo: 'Humedad con tendencia a bajar',
          descripcion:
              'La humedad del suelo viene disminuyendo en las últimas lecturas.',
          prioridad: 2,
          tipo: TipoRecomendacion.riego,
          variable: 'Humedad del suelo',
          accionSugerida:
              'Revise el riego antes de que la humedad llegue a un nivel crítico.',
          explicacion:
              'Esta recomendación se genera al analizar varias lecturas recientes guardadas en el historial local.',
        ),
      );
    }

    if (subiendo && ultima > 60) {
      recomendaciones.add(
        const Recomendacion(
          titulo: 'Humedad con tendencia a subir',
          descripcion:
              'La humedad del suelo viene aumentando en las últimas lecturas.',
          prioridad: 2,
          tipo: TipoRecomendacion.riego,
          variable: 'Humedad del suelo',
          accionSugerida:
              'Observe si el riego está siendo excesivo o si hay problemas de drenaje.',
          explicacion:
              'Una humedad en aumento puede ser normal después del riego, pero si se mantiene alta puede afectar la aireación del suelo.',
        ),
      );
    }
  }

  void _evaluarTendenciaTemperatura(
    List<LecturaHistorial> lecturas,
    List<Recomendacion> recomendaciones,
  ) {
    final subiendo = _vieneSubiendo(
      lecturas.map((l) => l.temperatura).toList(),
      umbral: 0.5,
    );

    final ultima = lecturas.last.temperatura;

    if (subiendo && ultima > 24) {
      recomendaciones.add(
        const Recomendacion(
          titulo: 'Temperatura en aumento',
          descripcion:
              'La temperatura del suelo viene aumentando en las últimas lecturas.',
          prioridad: 2,
          tipo: TipoRecomendacion.temperatura,
          variable: 'Temperatura del suelo',
          accionSugerida:
              'Revise cobertura, acolchado o sombreo si la tendencia continúa.',
          explicacion:
              'La tendencia permite anticipar condiciones de estrés térmico antes de que se vuelvan críticas.',
        ),
      );
    }
  }

  void _evaluarTendenciaPh(
    List<LecturaHistorial> lecturas,
    List<Recomendacion> recomendaciones,
  ) {
    final bajando = _vieneBajando(
      lecturas.map((l) => l.ph).toList(),
      umbral: 0.08,
    );

    final subiendo = _vieneSubiendo(
      lecturas.map((l) => l.ph).toList(),
      umbral: 0.08,
    );

    final ultima = lecturas.last.ph;

    if (bajando && ultima < 6.0) {
      recomendaciones.add(
        const Recomendacion(
          titulo: 'pH con tendencia a bajar',
          descripcion:
              'El pH del suelo viene disminuyendo y puede acercarse a una condición ácida.',
          prioridad: 2,
          tipo: TipoRecomendacion.ph,
          variable: 'pH del suelo',
          accionSugerida:
              'Monitoree el pH y valide con asesor técnico antes de aplicar correcciones.',
          explicacion:
              'El análisis histórico permite identificar cambios progresivos que no siempre son evidentes con una sola lectura.',
        ),
      );
    }

    if (subiendo && ultima > 6.3) {
      recomendaciones.add(
        const Recomendacion(
          titulo: 'pH con tendencia a subir',
          descripcion:
              'El pH del suelo viene aumentando y puede salir del rango ideal.',
          prioridad: 2,
          tipo: TipoRecomendacion.ph,
          variable: 'pH del suelo',
          accionSugerida:
              'Revise el manejo del suelo y evite correcciones sin acompañamiento técnico.',
          explicacion:
              'El pH influye en la disponibilidad de nutrientes, por eso se analiza su tendencia en el tiempo.',
        ),
      );
    }
  }

  void _evaluarTendenciaEc(
    List<LecturaHistorial> lecturas,
    List<Recomendacion> recomendaciones,
  ) {
    final subiendo = _vieneSubiendo(
      lecturas.map((l) => l.ec).toList(),
      umbral: 0.08,
    );

    final ultima = lecturas.last.ec;

    if (subiendo && ultima > 1.8) {
      recomendaciones.add(
        const Recomendacion(
          titulo: 'Conductividad en aumento',
          descripcion:
              'La conductividad eléctrica viene aumentando en las últimas lecturas.',
          prioridad: 2,
          tipo: TipoRecomendacion.salinidad,
          variable: 'Conductividad eléctrica',
          accionSugerida:
              'Revise fertilización, calidad del agua y posible acumulación de sales.',
          explicacion:
              'Una EC en aumento puede anticipar riesgo de salinidad si supera el rango recomendado.',
        ),
      );
    }
  }

  void _evaluarTendenciaNutrientes(
    List<LecturaHistorial> lecturas,
    List<Recomendacion> recomendaciones,
  ) {
    final nBajando = _vieneBajando(
      lecturas.map((l) => l.nitrogeno).toList(),
      umbral: 5,
    );

    final pBajando = _vieneBajando(
      lecturas.map((l) => l.fosforo).toList(),
      umbral: 3,
    );

    final kBajando = _vieneBajando(
      lecturas.map((l) => l.potasio).toList(),
      umbral: 5,
    );

    if (nBajando || pBajando || kBajando) {
      final nutrientes = <String>[];

      if (nBajando) nutrientes.add('N');
      if (pBajando) nutrientes.add('P');
      if (kBajando) nutrientes.add('K');

      recomendaciones.add(
        Recomendacion(
          titulo: 'Nutrientes con tendencia a disminuir',
          descripcion:
              'Uno o más nutrientes vienen disminuyendo en las últimas lecturas: ${nutrientes.join(', ')}.',
          prioridad: 2,
          tipo: TipoRecomendacion.fertilizacion,
          variable: 'NPK',
          accionSugerida:
              'Revise el comportamiento nutricional del cultivo antes de que aparezca una deficiencia marcada.',
          explicacion:
              'Esta recomendación usa el historial local para detectar disminuciones progresivas de nutrientes.',
        ),
      );
    }
  }

  bool _vieneSubiendo(
    List<double> valores, {
    required double umbral,
  }) {
    if (valores.length < 4) return false;

    var aumentos = 0;

    for (var i = 1; i < valores.length; i++) {
      if (valores[i] - valores[i - 1] > umbral) {
        aumentos++;
      }
    }

    return aumentos >= 3;
  }

  bool _vieneBajando(
    List<double> valores, {
    required double umbral,
  }) {
    if (valores.length < 4) return false;

    var disminuciones = 0;

    for (var i = 1; i < valores.length; i++) {
      if (valores[i - 1] - valores[i] > umbral) {
        disminuciones++;
      }
    }

    return disminuciones >= 3;
  }
}