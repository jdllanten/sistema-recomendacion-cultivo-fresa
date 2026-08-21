import 'package:flutter/material.dart';

// Define los colores personalizados para la aplicación

abstract final class AppColores {
  static const Color primario = Color(0xFF2E7D32);
  static const Color primariosuave = Color(0xFFE8F5E9);

  // Prioridades / estados
  static const Color prioridadAlta = Color(0xFFD32F2F); // Rojo
  static const Color prioridadMedia = Color(0xFFF57C00); // Naranja
  static const Color prioridadBaja = Color(0xFFFFC107); // Amarillo

  // Advertencia
  static const Color advertencia = Color(0xFFF57C00);
  static const Color advertenciasuave = Color(0xFFFFF3E0);

  // Crítico
  static const Color critico = Color(0xFFD32F2F);
  static const Color criticosuave = Color(0xFFFFEBEE);

  // Fondo
  static const Color fondo = Color(0xFFF7F8F5);

  // Superficies
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color borde = Color(0xFFDDE5DB);

  // Texto
  static const Color textoPrincipal = Color(0xFF1B1F1B);
  static const Color textoSecundario = Color(0xFF6B7280);
}