import 'package:flutter/material.dart';


class CustomFonts {
  static TextStyle plantifyStyle = TextStyle(
    fontFamily: 'PlantifyFont',
    fontSize: 24,
  
  );

  static TextTheme customTextTheme = TextTheme(

    displayLarge: plantifyStyle,
  );

 
  static ThemeData getCustomFontTheme() {
    return ThemeData(
      textTheme: customTextTheme,
    );
  }
}
