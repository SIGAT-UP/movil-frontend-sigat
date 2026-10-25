import 'package:flutter/material.dart';

/// Tema de la aplicación. El verde ICA es el color semilla.
class AppTheme {
  const AppTheme._();

  static const Color _semilla = Color(0xFF1B6B3A);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _semilla),
        appBarTheme: const AppBarTheme(centerTitle: false),
      );
}
