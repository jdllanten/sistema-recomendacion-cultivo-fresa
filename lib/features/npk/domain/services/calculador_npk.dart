//Resultado del cálculo de fertilización
class ResultadoFertilizacion {
  final double deficit;
  final double kgPorHaNutriente;
  final double dosisFertilizante;

  const ResultadoFertilizacion({
    required this.deficit,
    required this.kgPorHaNutriente,
    required this.dosisFertilizante,
  });
}


class CalculadorNpk {
  const CalculadorNpk();

  ResultadoFertilizacion calcular({
    required double valorActual,
    required double minimoIdeal,
    required double maximoIdeal,
    required double porcentajeFertilizante,
  }) {
    final objetivo = (minimoIdeal + maximoIdeal) / 2;

    final deficit = objetivo - valorActual;

    if (deficit <= 0) {
      return const ResultadoFertilizacion(
        deficit: 0,
        kgPorHaNutriente: 0,
        dosisFertilizante: 0,
      );
    }

    final kgPorHaNutriente = deficit * 2;

    final dosisFertilizante =
        kgPorHaNutriente / (porcentajeFertilizante / 100);

    return ResultadoFertilizacion(
      deficit: deficit,
      kgPorHaNutriente: kgPorHaNutriente,
      dosisFertilizante: dosisFertilizante,
    );
  }
}