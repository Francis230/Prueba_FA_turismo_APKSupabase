import 'package:flutter/material.dart';

// ===================================================================
// PALETA DE COLORES PROFESIONAL (Inspirada en el logo, refinada para UX)
// ===================================================================

// Color de Acento Principal (Dorado/Amarillo del Pin)
// Se usa para las acciones más importantes: botones, acentos, etc.
const accentColor = Color(0xFFFFD60A);

// Color Primario (Azul Eléctrico de los Ojos)
// Se usa para acciones secundarias y enlaces, para no competir con el dorado.
const primaryColor = Color(0xFF0096C7); 

// Colores de Fondo y Superficies (Modo Oscuro Sofisticado)
const backgroundColor = Color(0xFF1A1A1A); // Gris carbón, más suave que el negro puro.
const cardColor = Color(0xFF242424);      // Gris oscuro para las tarjetas, creando profundidad.

// Colores de Texto (Estándar de Material Design para legibilidad)
final textColor = Colors.white.withOpacity(0.87);
final secondaryTextColor = Colors.white.withOpacity(0.6);

// Color de Error
const errorColor = Color(0xFFCF6679);


// ===================================================================
// TEMA COMPLETO DE LA APLICACIÓN
// ===================================================================
final appTheme = ThemeData(
  // Configuración general del tema
  brightness: Brightness.dark,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: backgroundColor,
  
  // Esquema de colores completo
  colorScheme: const ColorScheme.dark(
    primary: primaryColor,
    secondary: accentColor, // El dorado es el color secundario/de acento
    background: backgroundColor,
    surface: cardColor,
    onPrimary: Colors.white,
    onSecondary: Colors.black, // Texto negro sobre botones dorados para máximo contraste
    onBackground: Colors.white,
    onSurface: Colors.white,
    error: errorColor,
  ),

  // Estilo de la barra de navegación superior (AppBar)
  appBarTheme: AppBarTheme(
    backgroundColor: cardColor,
    elevation: 1,
    iconTheme: IconThemeData(color: textColor),
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: textColor,
    ),
  ),

  // Estilo de los botones principales (ahora usan el color de acento dorado)
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: accentColor, // Fondo dorado
      foregroundColor: Colors.black,   // Texto negro para legibilidad
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  // Estilo del botón flotante
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: accentColor,
    foregroundColor: Colors.black,
  ),

  // Estilo de los campos de texto
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: accentColor, width: 2), // Borde dorado al seleccionar
    ),
    labelStyle: TextStyle(color: secondaryTextColor),
  ),

  // Estilo de las tarjetas
  cardTheme: CardThemeData(
    color: cardColor,
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
  ),

  // Estilo de los menús emergentes
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF2C2C2C),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),

  // Estilo de los botones de texto (ahora usan el azul eléctrico)
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
    ),
  ),

  // Estilo de los íconos
  iconTheme: IconThemeData(
    color: secondaryTextColor,
  ),
);