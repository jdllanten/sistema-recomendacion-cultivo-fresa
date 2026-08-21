// Configuración general de MQTT.
abstract final class ConfiguracionMqtt {
  static const bool usarDatosMock = false;

  static const String servidor = 'broker.emqx.io';
  static const int puerto = 1883;

  static const String clienteId = 'fresa_app_flutter_jdh2010';


  static const String topicSensor =
      'fresa_app/jdh2010/finca_esperanza/+/suelo';

  /// Topic concreto para publicar una lectura de un lote.
  static String topicParaLote(String loteId) {
    return 'fresa_app/jdh2010/finca_esperanza/$loteId/suelo';
  }
}
