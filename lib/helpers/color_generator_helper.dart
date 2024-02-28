import 'dart:math';
import 'package:flutter/material.dart';

class ColorGenerator {
  final int seed;

  ColorGenerator(this.seed);

  Color generateColor() {
    final Random random = Random(seed);
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }
}
