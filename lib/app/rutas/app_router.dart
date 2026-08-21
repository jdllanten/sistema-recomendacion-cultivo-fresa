import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/shell_navegacion_principal.dart';
import '../../features/historial/presentation/pages/historial_page.dart';
import '../../features/perfil/presentation/pages/acerca_sistema_page.dart';
import '../../features/perfil/presentation/pages/perfil_page.dart';
import '../../features/recomendaciones/presentation/pages/configuracion_plan_nutricional_page.dart';
import '../../features/recomendaciones/presentation/pages/fertilizantes_disponibles_page.dart';
import '../../features/recomendaciones/presentation/pages/plan_nutricional_npk_page.dart';
import '../../features/recomendaciones/presentation/pages/recomendaciones_page.dart';
import '../../features/sensores/presentation/pages/mqtt_test_page.dart';
import '../../features/sensores/presentation/pages/mediciones_sensor_page.dart';

abstract final class RutasApp {
  // Pestañas principales
  static const String sensores = '/';
  static const String nutricionNpk = '/nutricion-npk';
  static const String recomendaciones = '/recomendaciones';
  static const String historial = '/historial';
  static const String perfil = '/perfil';


  static const String inicio = sensores;

  // Subpantallas
  static const String pruebaMqtt = '/perfil/prueba-mqtt';
  static const String acercaSistema = '/perfil/acerca-sistema';

  static const String planNutricionalNpk = nutricionNpk;

  static const String configuracionPlanNutricional =
      '/configuracion-plan-nutricional';

  static const String fertilizantesDisponibles = '/fertilizantes-disponibles';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RutasApp.sensores,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellNavegacionPrincipal(navigationShell: navigationShell);
        },
        branches: [
         //inicio
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RutasApp.sensores,
                name: 'sensores',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: MedicionesSensorPage());
                },
              ),
            ],
          ),

          //plan nutricional
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RutasApp.nutricionNpk,
                name: 'nutricion-npk',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(
                    child: PlanNutricionalNpkPage(),
                  );
                },
              ),
            ],
          ),

          // 3. Recomendaciones
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RutasApp.recomendaciones,
                name: 'recomendaciones',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: RecomendacionesPage());
                },
              ),
            ],
          ),

          // 4. Historial
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RutasApp.historial,
                name: 'historial',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: HistorialPage());
                },
              ),
            ],
          ),

          // 5. Perfil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RutasApp.perfil,
                name: 'perfil',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: PerfilPage());
                },
                routes: [
                  GoRoute(
                    path: 'prueba-mqtt',
                    name: 'prueba-mqtt',
                    pageBuilder: (context, state) {
                      return const NoTransitionPage(child: MqttTestPage());
                    },
                  ),
                  GoRoute(
                    path: 'acerca-sistema',
                    name: 'acerca-sistema',
                    pageBuilder: (context, state) {
                      return const NoTransitionPage(child: AcercaSistemaPage());
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Subpantalla: configuración del cultivo
      GoRoute(
        path: RutasApp.configuracionPlanNutricional,
        name: 'configuracion-plan-nutricional',
        pageBuilder: (context, state) {
          return const NoTransitionPage(
            child: ConfiguracionPlanNutricionalPage(),
          );
        },
      ),

      // Subpantalla: fertilizantes disponibles
      GoRoute(
        path: RutasApp.fertilizantesDisponibles,
        name: 'fertilizantes-disponibles',
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: FertilizantesDisponiblesPage());
        },
      ),
    ],
  );
});
