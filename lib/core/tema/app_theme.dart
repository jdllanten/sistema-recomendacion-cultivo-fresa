import 'package:flutter/material.dart';
import 'app_colores.dart';
//Definición de los temas de la aplicación, incluyendo colores, tipografías y estilos generales
//Permite mantener una apariencia consistente en toda la aplicación y facilita la personalización del diseño

abstract final class AppTheme {
  static ThemeData get temaClaro {
    final esquemaColores = ColorScheme.fromSeed(
      seedColor: AppColores.primario,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquemaColores,
      
      //Fondo de la aplicación
      scaffoldBackgroundColor: AppColores.fondo,

      //AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: false, 
        elevation: 0, 
        backgroundColor: Colors.transparent,),

      //Tarjetas
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: AppColores.borde
            ),
        ),
      ),

      //Navegación inferior
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColores.superficie,
        indicatorColor: AppColores.primariosuave,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600
          ),
        ),
      ),

      //Texto
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColores.textoPrincipal,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColores.textoSecundario,
        ),
      ),
    );
  }
}
